import rclpy
from nav2_simple_commander.robot_navigator import BasicNavigator, TaskResult
from rclpy.node import Node
from rclpy.executors import MultiThreadedExecutor
from geometry_msgs.msg import TwistStamped, PoseStamped, PoseWithCovarianceStamped
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Query, Request
from fastapi.responses import FileResponse, StreamingResponse
from typing import Optional
from threading import Thread, Lock
from subprocess import Popen
import numpy as np
import cv2
from cv_bridge import CvBridge
from nav_msgs.msg import OccupancyGrid
from sensor_msgs.msg import Image
import json
import os
import httpx

from helper import pgm_to_png
from models import goalInput, status, positionOutput, MappingStatus, SaveMapRequest, ChangeMapRequest

app = FastAPI()
ros_node = None
amcl_node = None
map_image_node = None
spin_thread = None
navigator = None
cartographer_process = None

amcl_data = {"x": 0.0, "y": 0.0}
amcl_lock = Lock()

class CmdVelPublisher(Node):
    
    def __init__(self):
        super().__init__('websocket_cmd_vel_publisher')
        self.publisher = self.create_publisher(TwistStamped, '/cmd_vel', 10)

    def publish_cmd(self, linear: float, angular: float):
        msg = TwistStamped()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'base_link'
        msg.twist.linear.x = linear
        msg.twist.angular.z = angular
        self.publisher.publish(msg)
        self.get_logger().info(f"Published: linear={linear}, angular={angular}")

class AMCLListener(Node):

    def __init__(self):
        super().__init__('amcl_listener_node')
        self.amcl_pose = None

        self.create_subscription(
            PoseWithCovarianceStamped,
            '/amcl_pose',
            self.amcl_callback,
            10
        )

    def amcl_callback(self, msg):
        self.get_logger().info("Received AMCL pose")
        self.amcl_pose = msg
        with amcl_lock:
            amcl_data['x'] = msg.pose.pose.position.x
            amcl_data['y'] = msg.pose.pose.position.y

class MapImagePublisher(Node):
    def __init__(self):
        super().__init__('map_image_publisher')
        self.bridge = CvBridge()
        self.publisher = self.create_publisher(Image, '/map_image', 10)
        self.subscription = self.create_subscription(
            OccupancyGrid,
            '/map',
            self.map_callback,
            10
        )

    def map_callback(self, msg):
        # Convert OccupancyGrid to grayscale image
        width = msg.info.width
        height = msg.info.height
        data = np.array(msg.data, dtype=np.int8).reshape((height, width))

        # Map data values: -1 = unknown, 0 = free, 100 = occupied
        image = np.zeros((height, width), dtype=np.uint8)
        image[data == -1] = 127
        image[data == 0] = 255
        image[data == 100] = 0

        image = cv2.flip(image, 0)
        msg_img = self.bridge.cv2_to_imgmsg(image, encoding="mono8")
        msg_img.header = msg.header
        self.publisher.publish(msg_img)

@app.on_event("startup")
def on_startup():
    global ros_node, navigator, amcl_node, map_image_node, spin_thread
    if not rclpy.ok():
        rclpy.init()

    navigator = BasicNavigator()  # Has its own internal node

    ros_node = CmdVelPublisher()
    amcl_node = AMCLListener()
    map_image_node = MapImagePublisher()

    executor = MultiThreadedExecutor()
    executor.add_node(ros_node)
    executor.add_node(amcl_node)
    executor.add_node(map_image_node)

    spin_thread = Thread(target=executor.spin, daemon=True)
    spin_thread.start()

    try:
        navigator.waitUntilNav2Active()
    except Exception as e:
        print(f"Navigator failed to activate: {e}")

@app.on_event("shutdown")
def on_shutdown():
    global ros_node
    ros_node.destroy_node()
    navigator.destroyNode()
    rclpy.shutdown()

@app.post("/mapping/start", response_model=MappingStatus, summary="Start Cartographer mapping")
def start_mapping():
    global cartographer_process
    if cartographer_process and cartographer_process.poll() is None:
        return MappingStatus(status="already running")

    try:
        cartographer_process = Popen([
            "ros2", "launch", "turtlebot3_cartographer", "cartographer.launch.py", "use_sim_time:=true"
        ])
        return MappingStatus(status="started")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"error: {e}")

@app.post("/mapping/stop", response_model=MappingStatus, summary="Stop Cartographer mapping")
def stop_mapping():
    global cartographer_process
    if cartographer_process and cartographer_process.poll() is None:
        cartographer_process.terminate()
        cartographer_process.wait()
        return MappingStatus(status="stopped")
    return MappingStatus(status="not running")

@app.post("/mapping/save", response_model=MappingStatus, summary="Save the current map")
def save_map(request: SaveMapRequest):
    try:
        map_name = request.map_name
        save_proc = Popen([
            "ros2", "run", "nav2_map_server", "map_saver_cli",
            "-f", f"./maps/{map_name}"
        ])
        save_proc.wait()
        return MappingStatus(status=f"saved as {map_name}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"error: {e}")
    
@app.get("/mapping/stream")
async def stream_map(request: Request):
    url = "http://localhost:8080/stream?topic=/map_image"
    boundary = "frame"

    JPEG_START = b'\xff\xd8'
    JPEG_END = b'\xff\xd9'

    async def generate():
        async with httpx.AsyncClient() as client:
            async with client.stream("GET", url) as response:
                buffer = b""
                async for chunk in response.aiter_bytes():
                    buffer += chunk
                    while JPEG_START in buffer and JPEG_END in buffer:
                        start = buffer.find(JPEG_START)
                        end = buffer.find(JPEG_END, start) + 2
                        if end > start:
                            frame = buffer[start:end]
                            buffer = buffer[end:]
                            yield (
                                f"--{boundary}\r\n"
                                f"Content-Type: image/jpeg\r\n"
                                f"Content-Length: {len(frame)}\r\n\r\n"
                            ).encode("utf-8") + frame + b"\r\n"

    return StreamingResponse(generate(), media_type=f"multipart/x-mixed-replace; boundary={boundary}")

@app.post("/map/change", response_model=status, summary="Change the active map")
def change_map(request: ChangeMapRequest):
    if not request.map_name:
        raise HTTPException(status_code=400, detail="Missing map_name")

    map_dir = "/root/maps"
    map_filename = f"{request.map_name}.yaml"
    map_path = os.path.join(map_dir, map_filename)

    if not os.path.isfile(map_path):
        raise HTTPException(status_code=404, detail=f"Map file '{map_filename}' not found")

    try:
        navigator.changeMap(map_path)
        return status(status="map changed successfully")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to change map: {e}")

@app.get("/map/list", summary="List available maps")
def list_maps():
    maps_dir = "./maps"
    if not os.path.exists(maps_dir):
        raise HTTPException(status_code=404, detail="Maps directory does not exist.")

    map_files = [f for f in os.listdir(maps_dir) if f.endswith(".yaml")]
    return {"maps": map_files}

@app.get("/map/download", summary="Get map image by name")
def get_map(map_name: Optional[str] = Query(default='turtlebot3_house')):
    if not map_name:
        raise HTTPException(status_code=400, detail="Missing map_name query parameter.")

    maps_dir = "./maps"

    png_path = os.path.join(maps_dir, f"{map_name}.png")
    pgm_path = os.path.join(maps_dir, f"{map_name}.pgm")

    if os.path.exists(png_path):
        return FileResponse(png_path, media_type="image/png", filename=f"{map_name}.png")
    else:
        if os.path.exists(pgm_path):
            os.makedirs(maps_dir, exist_ok=True)
            try:
                png_path = pgm_to_png(pgm_path, png_path)
                return FileResponse(png_path, media_type="image/png", filename=f"{map_name}.png")
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Conversion failed: {e}")


@app.get("/voice/backup", response_model = status)
def backup(backup_dist: Optional[float] = 0.30, backup_speed: Optional[float] = 0.2, time_allowance: Optional[int] = 10):  
    if not navigator.isTaskComplete():
        return status(status = "stop the running task.")
    
    navigator.backup(backup_dist, backup_speed, time_allowance)

    i = 0
    while not navigator.isTaskComplete():
        i = i + 1
        feedback = navigator.getFeedback() 
        if feedback and i % 5 == 0:
            try:
                print(
                    'Distance traveled: '
                    + f'{feedback.distance_traveled:.3f}'
                )
            except Exception as e:
                print(f"Error at backup feedback: {e}")

    result = navigator.getResult()
    if result == TaskResult.SUCCEEDED:
        return status(status = "succeded")
    elif result == TaskResult.CANCELED:
        return status(status = "canceled")
    elif result == TaskResult.FAILED:
        try:
            error_code, error_msg = navigator.getTaskError()
            return status(status = "failed")
        except AttributeError:
           return status(status = "failed")
    else:
        return status(status = "unknown")

@app.post("/robot/goal", response_model=status, summary="Set a navigation goal")
def set_goal(goal: goalInput):
    if not amcl_node.amcl_pose:
        raise HTTPException(status_code=503, detail="AMCL pose not yet received")

    if not navigator.isTaskComplete():
        return status(status = "stop the running task.")
    
    initial_pose = PoseStamped()
    initial_pose.header = amcl_node.amcl_pose.header
    initial_pose.pose = amcl_node.amcl_pose.pose.pose

    goal_pose = PoseStamped()
    goal_pose.header.frame_id = 'map'
    goal_pose.header.stamp = navigator.get_clock().now().to_msg()
    goal_pose.pose.position.x = goal.x
    goal_pose.pose.position.y = goal.y
    goal_pose.pose.orientation.w = 1.0

     # Get the path, smooth it
    path = navigator.getPath(initial_pose, goal_pose)
    smoothed_path = navigator.smoothPath(path)

    # Follow path
    navigator.followPath(smoothed_path)

    i = 0
    while not navigator.isTaskComplete():
        i += 1
        feedback = navigator.getFeedback()
        if feedback and i % 5 == 0:
            try:
                print(
                    'Estimated distance remaining to goal position: '
                    + f'{feedback.distance_to_goal:.3f}'
                    + '\nCurrent speed of the robot: '
                    + f'{feedback.speed:.3f}'
                )
            except Exception as e:
                print(f"Error at goal feedback: {e}")

    result = navigator.getResult()
    if result == TaskResult.SUCCEEDED:
        return status(status = "succeded")
    elif result == TaskResult.CANCELED:
        return status(status = "canceled")
    elif result == TaskResult.FAILED:
#        (error_code, error_msg) = navigator.getTaskError()
        return status(status = "failed")
    else:
        return status(status = "unknown")
    
@app.get("/robot/position", response_model=positionOutput, summary="Get robot position from AMCL")
def get_amcl_pose():
    with amcl_lock:
        return positionOutput(x = amcl_data["x"], y = amcl_data["y"])
    
@app.get("/robot/cancel")
def cancel_task():
    navigator.cancelTask()

@app.websocket("/robot/velocity")
async def websocket_cmd_vel(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            try:
                cmd = json.loads(data)
                linear = float(cmd.get("linear", 0.0))
                angular = float(cmd.get("angular", 0.0))
                if ros_node:
                    ros_node.publish_cmd(linear, angular)
            except Exception as e:
                await websocket.send_text(f"Error parsing: {e}")
    except WebSocketDisconnect:
        print("WebSocket disconnected")

@app.get("/camera/stream")
async def stream_camera(request: Request, topic: str = Query("/camera/image_raw")):
    url = f"http://127.0.0.1:8080/stream?topic={topic}"
    boundary = "frame"

    # JPEG start/end markers
    JPEG_START = b'\xff\xd8'
    JPEG_END = b'\xff\xd9'

    async def generate():
        try:
            async with httpx.AsyncClient() as client:
                async with client.stream("GET", url) as response:
                    if response.status_code != 200:
                        raise HTTPException(status_code=response.status_code, detail="Error fetching stream")

                    buffer = b""
                    async for chunk in response.aiter_bytes():
                        buffer += chunk
                        while JPEG_START in buffer and JPEG_END in buffer:
                            start = buffer.find(JPEG_START)
                            end = buffer.find(JPEG_END, start) + 2
                            if end > start:
                                frame = buffer[start:end]
                                buffer = buffer[end:]
                                yield (
                                    f"--{boundary}\r\n"
                                    f"Content-Type: image/jpeg\r\n"
                                    f"Content-Length: {len(frame)}\r\n\r\n"
                                ).encode("utf-8") + frame + b"\r\n"
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to stream: {str(e)}")

    return StreamingResponse(generate(), media_type=f"multipart/x-mixed-replace; boundary={boundary}")
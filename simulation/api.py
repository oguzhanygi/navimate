import rclpy
from nav2_simple_commander.robot_navigator import BasicNavigator, TaskResult
from rclpy.node import Node
from rclpy.executors import MultiThreadedExecutor
from geometry_msgs.msg import TwistStamped, PoseStamped, PoseWithCovarianceStamped
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Query
from fastapi.responses import FileResponse
from typing import Optional
from threading import Thread, Lock
import json
import os
from helper import pgm_to_png
from models import goalInput, status, positionOutput

app = FastAPI()
ros_node = None
amcl_node = None
spin_thread = None
navigator = None

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

@app.on_event("startup")
def on_startup():
    global ros_node, navigator, amcl_node, spin_thread
    rclpy.init()
    ros_node = CmdVelPublisher()
    navigator = BasicNavigator()
    amcl_node = AMCLListener()

    executor = MultiThreadedExecutor()
    executor.add_node(ros_node)
    executor.add_node(navigator)
    executor.add_node(amcl_node)

    spin_thread = Thread(target=executor.spin, daemon=True)
    spin_thread.start()
    navigator.waitUntilNav2Active()

@app.on_event("shutdown")
def on_shutdown():
    global ros_node
    ros_node.destroy_node()
    navigator.destroyNode()
    rclpy.shutdown()

@app.get("/get_map")
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
    
    navigator.cancelTask()
    task = navigator.backup(backup_dist, backup_speed, time_allowance)

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

@app.post("/set_goal", response_model = status)
def set_goal(goal: goalInput):
    if not amcl_node.amcl_pose:
        raise HTTPException(status_code=503, detail="AMCL pose not yet received")

    initial_pose = PoseStamped()
    initial_pose.header = amcl_node.amcl_pose.header
    initial_pose.pose = amcl_node.amcl_pose.pose.pose

    goal_pose = PoseStamped()
    goal_pose.header.frame_id = 'map'
    goal_pose.header.stamp = navigator.get_clock().now().to_msg()
    goal_pose.pose.position.x = goal.x
    goal_pose.pose.position.y = goal.y
    goal_pose.pose.orientation.w = 1.0
    navigator.cancelTask()

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
    
@app.get("/position", response_model = positionOutput)
def get_amcl_pose():
    with amcl_lock:
        return positionOutput(x = amcl_data["x"], y = amcl_data["y"])

@app.websocket("/ws/cmd_vel")
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
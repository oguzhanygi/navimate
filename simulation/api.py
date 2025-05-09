import rclpy
from nav2_simple_commander.robot_navigator import BasicNavigator, TaskResult
from rclpy.node import Node
from geometry_msgs.msg import TwistStamped, PoseStamped
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Query
from fastapi.responses import FileResponse
from typing import Optional
import uvicorn
import threading
import json
import os
from helper import pgm_to_png
from models import goalInput, status

app = FastAPI()
ros_node = None
spin_thread = None
navigator = None

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

@app.on_event("startup")
def on_startup():
    global ros_node, spin_thread, navigator
    rclpy.init()
    ros_node = CmdVelPublisher()
    navigator = BasicNavigator()

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
    
    navigator.waitUntilNav2Active()
    task = navigator.backup(backup_dist, backup_speed, time_allowance)

    i = 0
    while not navigator.isTaskComplete():
        i = i + 1
        feedback = navigator.getFeedback() 
        if feedback and i % 5 == 0:
            print(
                'Distance traveled: '
                + f'{feedback.distance_traveled:.3f}'
            )

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

    initial_pose = PoseStamped()
    initial_pose.header.frame_id = 'map'
    initial_pose.header.stamp = navigator.get_clock().now().to_msg()
    initial_pose.pose.position.x = 0.0
    initial_pose.pose.position.y = 0.0
    initial_pose.pose.orientation.z = 0.0
    initial_pose.pose.orientation.w = 1.0

    goal_pose = PoseStamped()
    goal_pose.header.frame_id = 'map'
    goal_pose.header.stamp = navigator.get_clock().now().to_msg()
    goal_pose.pose.position.x = goal.x
    goal_pose.pose.position.y = goal.y
    goal_pose.pose.orientation.w = 1.0
    navigator.waitUntilNav2Active()

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
            print(
                'Estimated distance remaining to goal position: '
                + f'{feedback.distance_to_goal:.3f}'
                + '\nCurrent speed of the robot: '
                + f'{feedback.speed:.3f}'
            )

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
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import TwistStamped
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
import uvicorn
import threading
import json

app = FastAPI()

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

ros_node = None

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

def ros_spin(node):
    rclpy.spin(node)

def main():
    global ros_node
    rclpy.init()
    ros_node = CmdVelPublisher()

    ros_thread = threading.Thread(target=ros_spin, args=(ros_node,), daemon=True)
    ros_thread.start()

    uvicorn.run(app, host="0.0.0.0", port=8000)

    ros_node.destroy_node()
    rclpy.shutdown()

if __name__ == "__main__":
    main()


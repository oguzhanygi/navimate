#!/bin/bash
source /opt/ros/jazzy/setup.bash
source /root/turtlebot3_ws/install/setup.bash
exec uvicorn api:app --host 0.0.0.0 --port 8000

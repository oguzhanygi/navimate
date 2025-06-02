#!/bin/bash
set -e

export TURTLEBOT3_MODEL=waffle

source /opt/ros/jazzy/setup.bash
source /root/turtlebot3_ws/install/setup.bash

ros2 launch turtlebot3_gazebo turtlebot3_house.launch.py &
ros2 run web_video_server web_video_server &
xvfb-run ros2 launch turtlebot3_navigation2 navigation2.launch.py use_sim_time:=true map:=maps/turtlebot3_house.yaml &
/root/start_api.sh &

wait

FROM ros:jazzy-ros-base

# Install dependencies
RUN apt-get update && apt-get install -y \
    ros-jazzy-turtlebot3-gazebo \
    ros-jazzy-image-transport \
    ros-jazzy-camera-info-manager \
    ros-jazzy-web-video-server \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV TURTLEBOT3_MODEL=waffle
ENV ROS_DOMAIN_ID=0

# Create Python virtual environment
RUN python3 -m venv /root/venv
ENV PATH="/root/venv/bin:$PATH"

# Install Python packages
COPY requirements.txt /root/requirements.txt
RUN pip install --upgrade pip && pip install -r /root/requirements.txt

# Copy the WebSocket script
COPY teleop_websocket_server.py /root/teleop_websocket_server.py

# Copy gazebo fuel files (Needed for offline run)
COPY gz_files /root/.gz

# Copy the modified launch file (Needed to run without the client)
COPY ./my_launches/turtlebot3_house.launch.py /opt/ros/jazzy/share/turtlebot3_gazebo/launch/

# Set working directory
WORKDIR /root

# Launch simulation, web video server, and FastAPI WebSocket server
CMD ["bash", "-c", "\
  export TURTLEBOT3_MODEL=waffle && \
  source /opt/ros/jazzy/setup.bash && \
  ros2 launch turtlebot3_gazebo turtlebot3_house.launch.py & \
  ros2 run web_video_server web_video_server & \
  python /root/teleop_websocket_server.py & \
  wait"]


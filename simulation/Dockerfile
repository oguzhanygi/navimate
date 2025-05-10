FROM ros:jazzy-ros-base

# Install dependencies
RUN apt-get update && apt-get install -y \
    ros-jazzy-turtlebot3-gazebo \
    ros-jazzy-turtlebot3-navigation2 \
    ros-jazzy-rviz2 \
    ros-jazzy-image-transport \
    ros-jazzy-camera-info-manager \
    ros-jazzy-web-video-server \
    ros-$ROS_DISTRO-navigation2 \
    ros-$ROS_DISTRO-nav2-bringup \
    ros-$ROS_DISTRO-nav2-minimal-tb* \
    python3-pip \
    python3-venv \
    xvfb \
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

# Copy gazebo fuel files (Needed for offline run)
COPY gz_files /root/.gz

# Copy the modified launch file (Needed to run without the client)
COPY ./my_launches/turtlebot3_house.launch.py /opt/ros/jazzy/share/turtlebot3_gazebo/launch/

# Copy the source files
COPY api.py /root/api.py
COPY maps /root/maps
COPY helper.py /root/helper.py
COPY models.py /root/models.py

# Set working directory
WORKDIR /root

# Launch simulation, web video server, and FastAPI WebSocket server
CMD ["bash", "-c", "\
  export TURTLEBOT3_MODEL=waffle && \
  source /opt/ros/jazzy/setup.bash && \
  ros2 launch turtlebot3_gazebo turtlebot3_house.launch.py & \
  ros2 run web_video_server web_video_server & \
  xvfb-run ros2 launch turtlebot3_navigation2 navigation2.launch.py use_sim_time:=true map:=maps/turtlebot3_house.yaml & \
  uvicorn api:app --host 0.0.0.0 --port 8000 & \
  wait"]
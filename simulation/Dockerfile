FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    ROS_DISTRO=jazzy

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    curl \
    gnupg2 \
    lsb-release \
    software-properties-common \
    && locale-gen en_US en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Add ROS 2 GPG key and APT source
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | apt-key add - && \
    echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list

# Install ROS Jazzy base
RUN apt-get update && apt-get install -y ros-jazzy-ros-base

# Source ROS setup.bash
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc

# Add OSRF Gazebo key and repo
RUN apt-get update && apt-get install -y \
    curl \
    lsb-release \
    gnupg && \
    curl -sSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list

# Install ROS and system dependencies
RUN apt-get update && apt-get install -y \
    ros-jazzy-turtlebot3-gazebo \
    ros-jazzy-turtlebot3-navigation2 \
    ros-jazzy-rviz2 \
    ros-jazzy-image-transport \
    ros-jazzy-camera-info-manager \
    ros-jazzy-web-video-server \
    ros-jazzy-navigation2 \
    ros-jazzy-nav2-bringup \
    ros-jazzy-nav2-minimal-tb* \
    ros-jazzy-cartographer \
    ros-jazzy-cartographer-ros \
    python3-pip \
    python3-venv \
    git \
    python3-colcon-common-extensions \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV TURTLEBOT3_MODEL=waffle
ENV ROS_DOMAIN_ID=0

# Python virtual environment
RUN python3 -m venv /root/venv
ENV PATH="/root/venv/bin:$PATH"

# Install Python dependencies
COPY requirements.txt /root/requirements.txt
RUN pip install --upgrade pip && pip install -r /root/requirements.txt

# Prepare workspace folder and clone turtlebot3 first
RUN mkdir -p /root/turtlebot3_ws/src

# Clone the turtlebot3 repo
RUN git clone -b jazzy https://github.com/ROBOTIS-GIT/turtlebot3.git /root/turtlebot3_ws/src/turtlebot3

# Copy your modified cartographer.launch.py OVER the cloned one
COPY ./miscellaneous/cartographer.launch.py /root/turtlebot3_ws/src/turtlebot3/turtlebot3_cartographer/launch/cartographer.launch.py

# Now build the workspace — it will use your modified launch file
RUN bash -c "\
    source /opt/ros/jazzy/setup.bash && \
    cd /root/turtlebot3_ws && \
    colcon build --symlink-install --packages-select turtlebot3_cartographer"

# Optional: Source workspace in every shell
RUN echo "source /root/turtlebot3_ws/install/setup.bash" >> ~/.bashrc

# Copy Gazebo fuel files
COPY gz_files /root/.gz

# Copy custom launch and param files
COPY ./miscellaneous/turtlebot3_house.launch.py /opt/ros/jazzy/share/turtlebot3_gazebo/launch/
COPY ./miscellaneous/waffle.yaml /opt/ros/jazzy/share/turtlebot3_navigation2/param/waffle.yaml

# Copy the source files
COPY api.py /root/api.py
COPY maps /root/maps
COPY helper.py /root/helper.py
COPY models.py /root/models.py

# Set working directory
WORKDIR /root

# startup wrapper
COPY start_api.sh /root/start_api.sh
RUN chmod +x /root/start_api.sh
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
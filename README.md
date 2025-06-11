# NaviMate

NaviMate is a Flutter application designed to empower people with disabilities to control a helper robot in their home. The app provides an interface for sending navigation commands, monitoring the robot’s camera, and managing maps, making it easier for users to request the robot to fetch or deliver items as needed.

---

## Features

- **Live Camera Streaming:** View the robot’s camera feed in real time.
- **Accessible Controls:** Choose between joystick or button-based controls for robot movement, catering to different user abilities.
- **Map Navigation:** Select destinations by tapping on a map, and send the robot to specific locations.
- **Mapping Support:** Start, stop, and save new maps as the robot explores new environments.
- **Map Management:** Switch between saved maps and view map thumbnails.
- **Settings Drawer:** Easily configure robot connection (IP/port), control mode, and app theme (including dynamic color support).
- **Robust Feedback:** Get clear feedback on connection status, map loading, and command success/failure.

---

## Who is it for?

NaviMate is built for people with mobility impairments or other disabilities who benefit from a helper robot in their home. The app’s interface is designed for clarity, simplicity, and accessibility.

---

## How it works

- The app connects to a ROS2-based robot over the local network.
- Users can view the robot’s camera, control its movement, and send it to specific locations by tapping on a map.
- The robot’s position and goals are visualized in real time.
- Mapping features allow users or caregivers to create and manage maps of the home environment.

---

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/) installed (for running the simulation container).
- [Flutter](https://flutter.dev) installed (for building/running the app).
- The simulation and the device running NaviMate must be on the same network.

### Installation

**Clone the repository:**
```sh
git clone https://github.com/oguzhanygi/navimate
```

**Run the simulation backend:**
```sh
cd navimate/simulation
docker build -t navimate .
docker compose up
```

**Run the app:**
```sh
cd ../app
flutter pub get
flutter run
```

NaviMate is tested on Android and macOS. It should work on other platforms with minor tweaks.

### Configuration

- Open the app and tap the settings drawer (top left).
- Enter the robot’s IP address and port.
- Choose your preferred control mode and theme.

---

## License

[MIT](LICENSE)

---

*This project was made as our graduation project.*

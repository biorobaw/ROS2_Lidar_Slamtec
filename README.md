# ROS 2 Rolling — Ubuntu 24.04 Noble — VNC Dev Container

A ready-to-use Docker environment for ROS 2 Rolling Ridley development with a
full XFCE4 desktop accessible via VNC or a browser.

---

## Stack

| Layer | Package |
|---|---|
| OS | Ubuntu 24.04 Noble Numbat |
| ROS | ROS 2 Rolling Ridley (`ros-rolling-desktop`) |
| Desktop | XFCE4 |
| VNC Server | TigerVNC |
| Browser VNC | noVNC + websockify |
| Process mgr | Supervisord |

---

## Quick Start

### 1. Prerequisites

- [Docker Desktop](https://docs.docker.com/get-docker/) ≥ 24 (or Docker Engine + Compose plugin)
- ~5 GB disk space for the image

### 2. Clone / copy this folder

```bash
git clone <your-repo> ros2_dev
cd ros2_dev
```

### 3. Create the host workspace directory

```bash
mkdir -p workspace      # maps to /ros2_ws/src inside the container
```

Drop your ROS 2 package folders (with `package.xml`) directly inside `workspace/`.

### 4. Build & start

```bash
docker compose up --build          # first time (builds the image ~10–15 min)
docker compose up -d               # subsequent starts (detached)
```

---

## Connecting

### Browser (easiest — no client needed)

Open: **http://localhost:6080/vnc.html**

Click **Connect**, enter the password (`ros2vnc` by default).

### VNC client (e.g. RealVNC, TigerVNC Viewer)

```
Host:     localhost
Port:     5901
Password: ros2vnc
```

---

## Changing the VNC password / resolution

Edit `docker-compose.yml` under `environment:`:

```yaml
environment:
  VNC_PASSWORD: mysecretpass
  VNC_RESOLUTION: 2560x1440
```

Then restart: `docker compose up -d`.

---

## Working with the ROS 2 workspace

Open a terminal **inside the container** (either via the XFCE terminal or):

```bash
docker compose exec ros2 bash
```

### Build all packages

```bash
cb          # alias for: cd /ros2_ws && colcon build --symlink-install
```

### Build a single package

```bash
cbs <package_name>
```

### Source the workspace overlay

```bash
src         # alias for: source /ros2_ws/install/setup.bash
```

### Run a node

```bash
src && ros2 run <pkg> <executable>
```

---

## Useful commands

```bash
# Container lifecycle
docker compose up -d               # start
docker compose down                # stop + remove container (workspace files safe)
docker compose logs -f             # tail logs

# Shell access
docker compose exec ros2 bash

# Rebuild image after Dockerfile changes
docker compose up --build -d
```

---

## Directory layout

```
.
├── Dockerfile              # Image definition
├── docker-compose.yml      # Service config + volume mount
├── entrypoint.sh           # VNC startup logic
├── supervisord.conf        # Process manager (vnc + novnc)
├── workspace/              # ← YOUR ROS 2 PACKAGES GO HERE
│   └── my_package/
│       ├── package.xml
│       └── ...
└── README.md
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Black screen in VNC | Wait ~10 s for XFCE to fully start; refresh the browser tab |
| Port already in use | Change host ports in `docker-compose.yml` (e.g. `"5902:5901"`) |
| `colcon build` fails — missing deps | Run `rosdep install --from-paths /ros2_ws/src --ignore-src -r -y` |
| GPU / RViz rendering issues | Add `--device /dev/dri` under `devices:` in compose and install `mesa-utils` |

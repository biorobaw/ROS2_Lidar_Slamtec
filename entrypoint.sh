#!/bin/bash
# =============================================================================
#  entrypoint.sh — ROS 2 / VNC container startup
# =============================================================================
set -e

ROSDEV_USER="ubuntu"
ROSDEV_HOME="/home/${ROSDEV_USER}"
VNC_PORT="${VNC_PORT:-5901}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"
VNC_PASSWORD="${VNC_PASSWORD:-ros2vnc}"

# ── Sub-command: start VNC (called by supervisord) ──────────────────────────
if [[ "$1" == "vnc" ]]; then
    # Kill any stale locks
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

    # Write VNC password file as the rosdev user
    su -c "mkdir -p ${ROSDEV_HOME}/.vnc && \
           echo '${VNC_PASSWORD}' | vncpasswd -f > ${ROSDEV_HOME}/.vnc/passwd && \
           chmod 600 ${ROSDEV_HOME}/.vnc/passwd" "${ROSDEV_USER}"

    # Ensure xstartup is executable
    chmod +x "${ROSDEV_HOME}/.vnc/xstartup"

    echo "[VNC] Starting TigerVNC on :1 (port ${VNC_PORT})  resolution ${VNC_RESOLUTION}"
    exec su -c "vncserver :1 \
        -rfbport ${VNC_PORT} \
        -geometry ${VNC_RESOLUTION} \
        -depth ${VNC_DEPTH} \
        -fg \
        -xstartup ${ROSDEV_HOME}/.vnc/xstartup" "${ROSDEV_USER}"
fi

# ── Default: print connection info then exec CMD ────────────────────────────
echo "======================================================================"
echo "  ROS 2 Rolling — Ubuntu Noble — VNC Desktop"
echo "======================================================================"
echo "  VNC    → localhost:${VNC_PORT}   (password: ${VNC_PASSWORD})"
echo "  noVNC  → http://localhost:${NOVNC_PORT:-6080}/vnc.html"
echo "  Workspace mount → /ros2_ws"
echo ""
echo "  To change the VNC password pass:  -e VNC_PASSWORD=yourpass"
echo "  To change resolution pass:        -e VNC_RESOLUTION=2560x1440"
echo "======================================================================"

# Source ROS 2 for any inline commands
source /opt/ros/rolling/setup.bash || true

exec "$@"

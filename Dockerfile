# ============================================================
#  ROS 2 Rolling Ridley — Ubuntu 24.04 (Noble Numbat) + VNC
# ============================================================
FROM ubuntu:noble

# ---------- build args / labels ----------------------------
ARG DEBIAN_FRONTEND=noninteractive
ARG ROS_DISTRO=rolling
LABEL maintainer="USF BioRobotics Lab"
LABEL description="ROS 2 Rolling on Ubuntu 24.04 with VNC desktop"

# ---------- locale & timezone ------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        locales tzdata \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ---------- core utilities ---------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget gnupg2 lsb-release ca-certificates \
        software-properties-common apt-transport-https \
        git vim nano sudo bash-completion \
        python3-pip python3-venv python3-argcomplete \
        build-essential cmake \
        net-tools iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# ---------- ROS 2 Rolling ----------------------------------
# Add ROS 2 apt repo
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
        http://packages.ros.org/ros2/ubuntu \
        $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
        > /etc/apt/sources.list.d/ros2.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-desktop \
        ros-${ROS_DISTRO}-ros-base \
        ros-dev-tools \
        python3-colcon-common-extensions \
        python3-rosdep \
        python3-vcstool \
    && rosdep init \
    && rm -rf /var/lib/apt/lists/*

# ---------- XFCE4 desktop + TigerVNC + noVNC --------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        xfce4 xfce4-terminal xfce4-goodies \
        tigervnc-standalone-server tigervnc-common \
        dbus-x11 x11-xserver-utils xauth \
        novnc websockify \
        supervisor \
        fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# ---------- developer user ---------------------------------
ARG USERNAME=rosdev
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} \
               --shell /bin/bash --create-home ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ---------- ROS workspace ----------------------------------
RUN mkdir -p /ros2_ws/src \
    && chown -R ${USERNAME}:${USERNAME} /ros2_ws

# ---------- switch to dev user ----------------------------
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ---------- rosdep user update ----------------------------
RUN rosdep update

# ---------- VNC configuration ------------------------------
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080
ENV VNC_RESOLUTION=1920x1080
ENV VNC_DEPTH=24
ENV DISPLAY=:1

# VNC password (change via env var VNC_PASSWORD at runtime)
ENV VNC_PASSWORD=ros2vnc

RUN mkdir -p /home/${USERNAME}/.vnc

# XFCE startup script
RUN echo '#!/bin/bash\n\
exec startxfce4' > /home/${USERNAME}/.vnc/xstartup \
    && chmod +x /home/${USERNAME}/.vnc/xstartup

# ---------- shell environment ------------------------------
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" \
        >> /home/${USERNAME}/.bashrc \
    && echo "source /ros2_ws/install/setup.bash 2>/dev/null || true" \
        >> /home/${USERNAME}/.bashrc \
    && echo "export ROS_DOMAIN_ID=0" \
        >> /home/${USERNAME}/.bashrc \
    && echo "# ROS 2 aliases" \
        >> /home/${USERNAME}/.bashrc \
    && echo "alias cb='cd /ros2_ws && colcon build --symlink-install'" \
        >> /home/${USERNAME}/.bashrc \
    && echo "alias cbs='cd /ros2_ws && colcon build --symlink-install --packages-select'" \
        >> /home/${USERNAME}/.bashrc \
    && echo "alias ct='cd /ros2_ws && colcon test'" \
        >> /home/${USERNAME}/.bashrc \
    && echo "alias src='source /ros2_ws/install/setup.bash'" \
        >> /home/${USERNAME}/.bashrc

# ---------- supervisord config (root-owned) ---------------
USER root

RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ---------- ports -----------------------------------------
EXPOSE ${VNC_PORT} ${NOVNC_PORT}

# ---------- volumes ----------------------------------------
VOLUME ["/ros2_ws"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

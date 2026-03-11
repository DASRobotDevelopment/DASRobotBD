#!/bin/bash

set -e  # Остановка при ошибке

# Цвета
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] && error "Не запускайте от root!"

UBUNTU_CODENAME=$(lsb_release -sc 2>/dev/null || . /etc/os-release && echo $VERSION_CODENAME)
[[ "$UBUNTU_CODENAME" != "noble" ]] && warn "Рекомендуется Ubuntu 24.04 (noble)"

log "🚀 Установка ROS2 Jazzy + Robot packages"

# 1. Базовая установка ROS2 Jazzy
sudo apt update && sudo apt upgrade -y && \
sudo apt install -y locales curl software-properties-common && \
sudo locale-gen en_US.UTF-8 && \
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
export LANG=en_US.UTF-8

ROS_VERSION=$(curl -sSL https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep tag_name | cut -d '"' -f4)
curl -sSL "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_VERSION}/ros2-apt-source_${ROS_VERSION}.${UBUNTU_CODENAME}_all.deb" -o /tmp/ros2.deb && \
sudo dpkg -i /tmp/ros2.deb && rm /tmp/ros2.deb

sudo apt update && sudo apt install -y ros-dev-tools ros-jazzy-ros-base

# 2. ✅ ИСПРАВЛЕННЫЕ PAKETЫ ДЛЯ JAZZY
sudo apt update && sudo apt install -y \
    ros-jazzy-robot-state-publisher \
    ros-jazzy-joint-state-publisher-gui \
    ros-jazzy-xacro \
    ros-jazzy-urdf \
    ros-jazzy-urdf-tutorial \
    ros-jazzy-rplidar-ros \
    ros-jazzy-navigation2 \
    ros-jazzy-slam-toolbox \
    ros-jazzy-twist-mux \
    ros-jazzy-twist-mux-msgs

# 3. Автозагрузка + rosdep
echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
source /opt/ros/jazzy/setup.bash

sudo rosdep init || true
rosdep update

# 4. Тесты
log "🧪 Тест ROS2 + пакетов:"
ros2 run demo_nodes_cpp talker &
sleep 2
ros2 run demo_nodes_cpp listener --once
pkill -f talker

which xacro || error "xacro не установлен"
ros2 pkg list | grep -E "(rplidar|slam_toolbox|navigation2)" || warn "Некоторые пакеты не найдены"

log "✅ Установка завершена!"
echo -e "${YELLOW}Полный список установленных ROS2 пакетов:${NC}"
echo "  ros2 pkg list | grep jazzy"
echo -e "${YELLOW}Для Nav2 + Gazebo:${NC}"
echo "  sudo apt install ros-jazzy-desktop ros-jazzy-gazebo-ros-pkgs"

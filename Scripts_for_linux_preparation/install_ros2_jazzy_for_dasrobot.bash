#!/bin/bash

set -e # Остановка при ошибке

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Подготовка к установке
log "ℹ  Настройка сети"
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
sudo rm -rf /var/lib/apt/lists/*
sudo apt clean

# Установка основных пакетов
log "ℹ  Установка ROS2 Jazzy"

locale  # check for UTF-8
sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
locale  # verify settings
sudo apt install software-properties-common
sudo add-apt-repository universe
sudo apt update && sudo apt install curl -y
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
sudo dpkg -i /tmp/ros2-apt-source.deb
sudo apt update && sudo apt install ros-dev-tools
sudo apt update
sudo apt upgrade
sudo apt install ros-jazzy-ros-base
echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc

# Проверка установки основных пакетов
if dpkg -l | grep -q ros-jazzy-ros-base; then
    echo "✔️ ros-jazzy-ros-base установлен"
    
    if [ -d "/opt/ros/jazzy" ]; then
        source /opt/ros/jazzy/setup.bash
        echo "✔️ ROS_DISTRO: $ROS_DISTRO"
        ros2 --help >/dev/null 2>&1 && echo "✔️ ros2 команда работает"
    else
        echo "❌ /opt/ros/jazzy не найдена"
    fi
else
    echo "❌ ros-jazzy-ros-base НЕ установлен"
fi

# Установка дополнительных пакетов
log "ℹ  Установка ROS2 Jazzy packages"

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

# Проверка установки дополнительных пакетов
PACKAGES=(
    "ros-jazzy-robot-state-publisher"
    "ros-jazzy-joint-state-publisher-gui"
    "ros-jazzy-xacro"
    "ros-jazzy-urdf"
    "ros-jazzy-urdf-tutorial"
    "ros-jazzy-rplidar-ros"
    "ros-jazzy-navigation2"
    "ros-jazzy-slam-toolbox"
    "ros-jazzy-twist-mux"
    "ros-jazzy-twist-mux-msgs"
)

INSTALLED=0
MISSING=0

for pkg in "${PACKAGES[@]}"; do
    if dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'; then
        ((INSTALLED++))
    else
        echo "❌ $pkg - отсутствует"
        ((MISSING++))
    fi
done

if [ $MISSING -eq 0 ]; then
    echo "✔️ Все пакеты установлены!"
else
    echo "❌ Установи недостающие:"
    echo "sudo apt update && sudo apt install -y ${PACKAGES[*]}"
fi



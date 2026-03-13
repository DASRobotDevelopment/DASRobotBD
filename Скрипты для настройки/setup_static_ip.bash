#!/bin/bash
set -e

# Цвета ИСПРАВЛЕНЫ ✅
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ПРОВЕРКА прав ✅
[[ $EUID -eq 0 ]] && error "НЕ запускайте от sudo! Используйте: ./setup_wifi.sh"

usage() {
    cat << EOF
Использование: $0 [OPTIONS]

Параметры (обязательные):
  -i, --ip IP           IP адрес (пример: 192.168.1.100)
  -g, --gateway GATEWAY IP шлюза/роутера
  -s, --ssid SSID       Имя WiFi сети  
  -p, --password PASSWD Пароль WiFi

Пример:
  $0 -i 192.168.1.100 -g 192.168.1.1 -s MyWiFi -p MySecretPass123
EOF
    exit 1
}

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--ip) IP="$2"; shift 2 ;;
        -g|--gateway) GATEWAY="$2"; shift 2 ;;
        -s|--ssid) SSID="$2"; shift 2 ;;
        -p|--password) PASSWORD="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) error "Неизвестный параметр: $1. Используйте --help" ;;
    esac
done

# Проверка обязательных параметров
[[ -z "$IP" ]] && error "Укажите IP: -i 192.168.1.100"
[[ -z "$GATEWAY" ]] && error "Укажите шлюз: -g 192.168.1.1"
[[ -z "$SSID" ]] && error "Укажите SSID: -s MyWiFi"
[[ -z "$PASSWORD" ]] && error "Укажите пароль: -p MyPass"

log "🌐 Настройка WiFi: $SSID → $IP/$GATEWAY"

# 1. Создание/редактирование netplan конфига
CONFIG_FILE="/etc/netplan/50-cloud-init.yaml"
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

sudo tee "$CONFIG_FILE" > /dev/null << EOF
network:
  version: 2
  wifis:
    wlan0:
      dhcp4: false
      dhcp6: false
      addresses:
        - [$IP/24]
      routes:
        - to: default
          via: $GATEWAY
          metric: 100
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
      access-points:
        "$SSID":
          password: "$PASSWORD"
EOF

# 2. Проверка синтаксиса + применение
log "🔍 Проверка конфигурации..."
sudo netplan generate || error "Ошибка в netplan конфиге!"

log "✅ Применение настроек (переподключение WiFi)..."
sudo netplan apply

# 3. Проверка результата
sleep 5
CURRENT_IP=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d'/' -f1)

if [[ "$CURRENT_IP" == "$IP" ]]; then
    log "✅ WiFi настроен: $IP ($SSID)"
    echo -e "${GREEN}🌐 Сеть:${NC} $SSID | IP: $CURRENT_IP | Gateway: $GATEWAY"
else
    warn "⚠️  IP не совпадает: ожидался $IP, получен $CURRENT_IP"
fi

log "📋 Конфиг сохранен: $CONFIG_FILE"
log "💾 Бэкап: ${CONFIG_FILE}.backup.*"

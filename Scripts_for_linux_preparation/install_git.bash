#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] && error "НЕ запускайте от root/sudo!"

usage() {
    cat << EOF
Использование: $0 -e EMAIL -n NAME [-c COMMENT] [-t TYPE]

Параметры (обязательные):
  -e, --email EMAIL     Email для Git (user@example.com)
  -n, --name NAME       Имя пользователя Git (John Doe)
  -t, --type TYPE       Тип ключа (rsa|ed25519) [по умолчанию: ed25519]
  -c, --comment COMMENT Комментарий ключа [по умолчанию: email]

Пример:
  $0 -e "user@domain.com" -n "John Doe" -t ed25519
EOF
    exit 1
}

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--email) EMAIL="$2"; shift 2 ;;
        -n|--name) GIT_NAME="$2"; shift 2 ;;
        -t|--type) KEY_TYPE="$2"; shift 2 ;;
        -c|--comment) COMMENT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) error "Неизвестный параметр: $1. Используйте --help" ;;
    esac
done

[[ -z "$EMAIL" ]] && error "Укажите email: -e user@example.com"
[[ -z "$GIT_NAME" ]] && error "Укажите имя: -n 'John Doe'"
KEY_TYPE="${KEY_TYPE:-ed25519}"
COMMENT="${COMMENT:-$EMAIL}"

log "👤 Настройка Git для: $GIT_NAME ($EMAIL)"
log "🔑 Тип ключа: $KEY_TYPE"

# Установка
sudo apt update || warn "apt update failed"
sudo apt install -y git || error "Не удалось установить git"
git --version

# Git config
git config --global user.name "$GIT_NAME"
git config --global user.email "$EMAIL"
git config --list | grep -E "(user.name|user.email)"

# SSH ключ
mkdir -p ~/.ssh && chmod 700 ~/.ssh
if [[ -f ~/.ssh/id_"$KEY_TYPE" ]]; then
    warn "Ключ ~/.ssh/id_${KEY_TYPE} уже существует!"
else
    ssh-keygen -t "$KEY_TYPE" -C "$COMMENT" -f ~/.ssh/id_"$KEY_TYPE" -N ""
fi

# SSH агент
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_"$KEY_TYPE" 2>/dev/null || warn "SSH ключ не добавлен в агент"

log "📋 Публичный ключ (добавьте в GitHub/GitLab):"
cat ~/.ssh/id_"$KEY_TYPE".pub

log "🎉 Готово! Тест: ssh -T git@github.com"

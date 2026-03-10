sudo apt update
sudo apt install git -y
git --version  # 2.34+ ✓

git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --list | grep user

# Генерация SSH ключа
ssh-keygen -t ed25519 -C "your.email@example.com"
# Enter → /home/dev/.ssh/id_ed25519 (по умолчанию)
# Enter → без passphrase (для автоматизации)

# Запуск ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Показать публичный ключ
cat ~/.ssh/id_ed25519.pub

 При проблемах с загрузкой
sudo nano /etc/resolv.conf

Добавь:

text
nameserver 8.8.8.8
nameserver 1.1.1.1
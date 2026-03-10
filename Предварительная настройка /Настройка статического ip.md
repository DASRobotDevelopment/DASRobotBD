1. Обновлем систему 
sudo apt update
sudo apt upgrade

2. ip route после "default" покажет ip роутера, а далее ip текущего пк. Они понадобятся при настройке

3. Подключаемся через ssh
ssh@<login>

4. Зайти в гастройки сети:
sudo nano /etc/netplan/50-cloud-init.yaml 

5. Приводим содиржимое к виду:
network:
  version: 2
  renderer: networkd
  wifis:
    wlan0:
      dhcp4: no
      addresses: [<желаемый ip>/24]
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: default
          via: <ip роутера>
      access-points:
        "<Имя сети для подключения>":
          password: "<пароль от сети>"

6. Применяем новые настройки
sudo netplan generate
sudo netplan apply
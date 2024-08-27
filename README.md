# OpenVPN Docker Image

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue)]([https://github.com/your-username/your-repo](https://github.com/DraKuLa21-a42/docker-openvpn))
[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-Image-blue)]([https://hub.docker.com/r/your-username/ovpn](https://hub.docker.com/r/drakula21/openvpn-image))

## Використання

Створіть на сервері файл `docker-compose.yaml` зі вмістом:

```yaml
services:
  openvpn:
    image: drakula21/openvpn-image
    container_name: ovpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - /opt/etc/openvpn/ccd:/etc/openvpn/ccd
    ports:
      - "1194:1194"
      - "3000:3000"
      - "80:80"
    restart: unless-stopped
```
Та запустіть
`docker compose up -d`
В перший раз контейнер може запускатись декілька хвилин (в цей час генерується dh файл), можете також слідкувати за логами.

Виконайте команду: 

`echo 1 > /proc/sys/net/ipv4/ip_forward && sysctl -p`

Після завершення налаштувань виконайте:
`docker cp ovpn:/etc/openvpn/client1.ovpn .`
для копіювання клієнтського конфігу з контейнера на сервер у поточну директорію.
Далі, переносите файл до себе на ПК та підключаєтесь.

Для подальших налаштувань потрібно перейти за адресою: SERVER_IP:3000 та виконати початкові налаштування AdGuardHome. Змінювати нічого не потрібно, лише вказати бажані логін та пароль. Після виконання налаштувань, щроб попасти в AdGuardHome, потрібно просто перейти за IP адресою сервер, без порта (http).

Потрібні домени потрібно вказувати в меню: Налаштування - Налаштування DNS - Upstream DNS-сервери.

Формат даних:
`[/domain.com/]127.0.0.4:5959`. Змінювати лише домен.

Після збереження даних, зміни приймаються одразу. Потрібно буде лише зачекати, поки Ваш браузер оновить кеш ДНС.

Власні маршрути вказуються у файлі `/opt/etc/openvpn/ccd/DEFAULT`

Формат даних:

`push "route network netmask"`, наприклад `push "route 8.8.8.0 255.255.255.0"`(для цілої підмережі) або `push "route 8.8.8.8 255.255.255.255"`(для однієї IP адреси).

Щоб зміни прийнялись, потрібно пеперепідключитись до OpenVPN сервера.


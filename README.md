# OpenVPN Docker Image

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue)]([https://github.com/DraKuLa21-a42/docker-openvpn](https://github.com/DraKuLa21-a42/docker-openvpn))
[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-Image-blue)]([https://hub.docker.com/r/drakula21/openvpn-image](https://hub.docker.com/r/drakula21/openvpn-image))

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
      - /opt/openvpn-image/openvpn:/etc/openvpn
      - /opt/openvpn-image/AdGuardHome:/opt/AdGuardHome
    ports:
      - "1194:1194"
      - "3000:3000"
      - "80:80"
    restart: unless-stopped
```
Для запуску контейнера виконайте:
`docker compose up -d`

В перший раз контейнер може запускатись декілька хвилин (в цей час генерується dh файл), можете також слідкувати за логами.

Щоб дозволити прохоження трафіку через сервер, виконайте команду: 

`echo 1 > /proc/sys/net/ipv4/ip_forward && sysctl -p`

Через 1-3 хвилини після запуску контейнера скопіюйте ovpn файл, командою:
`docker cp ovpn:/etc/openvpn/client1.ovpn .`

Далі переносите файл до себе на ПК та підключаєтесь.

Для подальших налаштувань потрібно перейти за адресою: SERVER_IP:3000 та виконати початкові налаштування AdGuardHome. Змінювати нічого не потрібно, лише вказати бажані логін та пароль. Після виконання налаштувань, щоб попасти в AdGuardHome, потрібно просто перейти за IP адресою сервер, без порта (http).

Потрібні домени потрібно вказувати в меню: Налаштування - Налаштування DNS - Upstream DNS-сервери.

Формат даних:
`[/domain.com/]127.0.0.4:5959`.

`domain.com` - потрібний домен.

`127.0.0.4:5959` - не змінювати.

Після збереження даних зміни приймаються одразу. Потрібно буде лише зачекати, поки Ваш браузер оновить кеш ДНС.

Власні маршрути вказуються у файлі `/opt/etc/openvpn/ccd/DEFAULT`

Формат даних:

`push "route network netmask"`, наприклад `push "route 8.8.8.0 255.255.255.0"`(для цілої підмережі) або `push "route 8.8.8.8 255.255.255.255"`(для однієї IP адреси).

Щоб зміни прийнялись, потрібно пеперепідключитись до OpenVPN сервера.


Всі файли OpenVPN та AdGuardHome знаходяться в директорії /opt/openvpn-image

Якщо по якійсь причині потрібно буде виконати перевстановлення OpenVPN, буде достатньо видалити директорію `/opt/openvpn-image` та перезавантажити контейнер.

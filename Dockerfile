# Використовуємо офіційний базовий образ Ubuntu
FROM ubuntu:24.04

# Вказуємо, що нам потрібен root
USER root

# Оновлюємо пакети і встановлюємо необхідні залежності
RUN apt update && apt install -y \
    openvpn \
    iptables \
    easy-rsa \
    curl \
    python3 \
    python3-dnslib \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Створюємо папку для зберігання конфігурацій OpenVPN
RUN mkdir -p /etc/openvpn/ccd /etc/openvpn/easy-rsa

# Копіюємо скрипт для ініціалізації VPN серверу
COPY ./init.sh /init.sh
COPY ./dnsmap/ /opt/dnsmap/
RUN chmod +x /init.sh /opt/dnsmap/*

# Вказуємо точку монтування volume для зберігання конфігураційних файлів
#VOLUME ["/etc/openvpn"]

# Відкриваємо необхідний порт для OpenVPN
EXPOSE 1194/udp
EXPOSE 1194/tcp

# Вказуємо команду для запуску
CMD ["/init.sh"]


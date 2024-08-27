#!/bin/bash

# Перевіряємо, чи вже існують конфігураційні файли OpenVPN
if [ ! -f /etc/openvpn/server.conf ]; then
    echo "Налаштовуємо OpenVPN..."

    mkdir /etc/openvpn/{easy-rsa,ccd}

    # Змінюємо директорію на easy-rsa і ініціалізуємо PKI
    cd /etc/openvpn/easy-rsa

    # Створюємо директорію pki
    make-cadir pki
    cd pki

    # Створюємо файл vars з необхідними параметрами
    cat <<EOF > vars
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "California"
set_var EASYRSA_REQ_CITY       "San Francisco"
set_var EASYRSA_REQ_ORG        "My Organization"
set_var EASYRSA_REQ_EMAIL      "email@example.com"
set_var EASYRSA_REQ_OU         "My Organizational Unit"

set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    3650
set_var EASYRSA_CRL_DAYS       180
EOF

    # Генеруємо CA з автоматичним заповненням інформації
    ./easyrsa init-pki
    ./easyrsa --batch build-ca nopass

    # Генеруємо серверний ключ і сертифікат
    ./easyrsa --batch build-server-full server nopass

    # Генеруємо ключі і сертифікати для клієнтів (наприклад, для клієнта з ім'ям "client1")
    ./easyrsa --batch build-client-full client1 nopass

    # Генеруємо Diffie-Hellman параметри
    ./easyrsa gen-dh

    # Копіюємо необхідні файли до директорії OpenVPN
    cp pki/ca.crt /etc/openvpn/
    cp pki/private/server.key /etc/openvpn/
    cp pki/issued/server.crt /etc/openvpn/
    cp pki/dh.pem /etc/openvpn/
    cp pki/issued/client1.crt /etc/openvpn/
    cp pki/private/client1.key /etc/openvpn/

    # Отримуємо зовнішню IP-адресу сервера
    EXTERNAL_IP=$(curl -s ifconfig.me)

    # Створюємо конфігураційний файл сервера
    cat <<EOF > /etc/openvpn/server.conf
port 1194
proto tcp
dev tun
topology subnet
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
#push "redirect-gateway def1 bypass-dhcp"
client-config-dir /etc/openvpn/ccd
push "dhcp-option DNS 10.8.0.1"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
duplicate-cn
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
EOF

    # Створюємо конфігураційний файл для клієнта
    cat <<EOF > /etc/openvpn/client1.ovpn
client
dev tun
proto tcp
remote ${EXTERNAL_IP} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server

<ca>
$(cat /etc/openvpn/ca.crt)
</ca>

<cert>
$(cat /etc/openvpn/client1.crt)
</cert>

<key>
$(cat /etc/openvpn/client1.key)
</key>

cipher AES-256-CBC
auth SHA256
verb 3
EOF

cat <<EOF > /etc/openvpn/ccd/DEFAULT
# DNS Routing
push "route 10.224.0.0 255.254.0.0"
EOF

else
    echo "OpenVPN вже налаштовано."
fi

if [ ! -f /opt/AdGuardHome/AdGuardHome ]; then
	curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
else
	echo "AdGuardHome вже встановлений."
fi

# Додати правила файрволу
iptables -t nat -F
iptables -t nat -N dnsmap
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A PREROUTING -s 10.8.0.0/16 -d 10.224.0.0/15 -j dnsmap
iptables -A FORWARD -i tun+ -j ACCEPT
#iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
#iptables -A FORWARD -d 10.8.0.0/24 -j ACCEPT
cd /opt/dnsmap; /opt/dnsmap/proxy.py -a 127.0.0.4 -p 5959 --iprange 10.224.0.0/15 -u 8.8.8.8:53 &

# Запускаємо OpenVPN сервер
openvpn --config /etc/openvpn/server.conf --verb 3 --log /dev/stdout

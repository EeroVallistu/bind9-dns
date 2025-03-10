#!/bin/bash

# Script to install and configure BIND9 DNS server
# For Ubuntu Server 16.04 LTS
# Domain: firma.lan
# Network: 10.100.0.0/24

set -e  # Exit on error

# Variables
DOMAIN="firma.lan"
NETWORK="10.100.0"
REVERSE_ZONE="0.100.10.in-addr.arpa"
DNS_SERVER_IP="10.100.0.10"
DNS_SERVER_NAME="ns1"

echo "Installing BIND9 packages..."
apt-get update
apt-get install -y bind9 bind9utils bind9-doc

echo "Creating directories for configuration files..."
mkdir -p /etc/bind/zones

echo "Configuring named.conf.options..."
cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    recursion yes;
    allow-recursion { 127.0.0.1; ${NETWORK}.0/24; };
    listen-on { 127.0.0.1; ${DNS_SERVER_IP}; };
    allow-transfer { none; };

    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    dnssec-validation auto;
    auth-nxdomain no;    # conform to RFC1035
};
EOF

echo "Configuring named.conf.local..."
cat > /etc/bind/named.conf.local << EOF
zone "${DOMAIN}" {
    type master;
    file "/etc/bind/zones/db.${DOMAIN}";
};

zone "${REVERSE_ZONE}" {
    type master;
    file "/etc/bind/zones/db.${REVERSE_ZONE}";
};
EOF

echo "Creating forward zone file..."
cat > /etc/bind/zones/db.${DOMAIN} << EOF
\$TTL    604800
@       IN      SOA     ${DNS_SERVER_NAME}.${DOMAIN}. admin.${DOMAIN}. (
                     $(date +%Y%m%d)01     ; Serial
                         604800     ; Refresh
                          86400     ; Retry
                        2419200     ; Expire
                         604800 )   ; Negative Cache TTL
;
@       IN      NS      ${DNS_SERVER_NAME}.${DOMAIN}.
@       IN      A       ${DNS_SERVER_IP}
${DNS_SERVER_NAME}     IN      A       ${DNS_SERVER_IP}
EOF

echo "Creating reverse zone file..."
cat > /etc/bind/zones/db.${REVERSE_ZONE} << EOF
\$TTL    604800
@       IN      SOA     ${DNS_SERVER_NAME}.${DOMAIN}. admin.${DOMAIN}. (
                     $(date +%Y%m%d)01     ; Serial
                         604800     ; Refresh
                          86400     ; Retry
                        2419200     ; Expire
                         604800 )   ; Negative Cache TTL
;
@       IN      NS      ${DNS_SERVER_NAME}.${DOMAIN}.
10      IN      PTR     ${DNS_SERVER_NAME}.${DOMAIN}.
EOF

echo "Checking configuration syntax..."
named-checkconf

echo "Checking zone files..."
named-checkzone ${DOMAIN} /etc/bind/zones/db.${DOMAIN}
named-checkzone ${REVERSE_ZONE} /etc/bind/zones/db.${REVERSE_ZONE}

echo "Restarting BIND9 service..."
systemctl restart bind9

echo "Enabling BIND9 to start on boot..."
systemctl enable bind9

echo "Configuring firewall to allow DNS traffic..."
# Check if UFW is installed and active before configuring it
if command -v ufw >/dev/null 2>&1; then
    if systemctl is-active --quiet ufw || ufw status | grep -q "Status: active"; then
        echo "UFW firewall detected and active. Adding DNS rules..."
        ufw allow 53/tcp
        ufw allow 53/udp
        echo "Firewall rules added for DNS traffic."
    else
        echo "UFW is installed but not active. No firewall rules added."
        echo "Consider enabling the firewall with 'ufw enable' and adding DNS rules manually."
    fi
else
    echo "UFW firewall not detected. No firewall rules added."
    echo "Consider installing a firewall and adding DNS rules manually."
fi

echo "Testing DNS resolution..."
dig @${DNS_SERVER_IP} ${DNS_SERVER_NAME}.${DOMAIN}
dig @${DNS_SERVER_IP} -x ${DNS_SERVER_IP}

echo "BIND9 DNS server installation and configuration completed successfully."
echo "DNS Server: ${DNS_SERVER_NAME}.${DOMAIN} (${DNS_SERVER_IP})"
echo "Domain: ${DOMAIN}"
echo "Network: ${NETWORK}.0/24"
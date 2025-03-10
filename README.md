# BIND9 DNS Server Installation Script

A bash script for automating the installation and configuration of a BIND9 DNS server on Ubuntu/Debian systems.

## Overview

This script sets up a BIND9 DNS server for a local network with the following configuration:
- Domain: firma.lan
- Network: 10.100.0.0/24
- DNS server IP: 10.100.0.10
- DNS server hostname: ns1.firma.lan

## Features

- Complete BIND9 installation with required packages
- Configuration of forward and reverse DNS zones
- Automatic configuration validation
- Firewall rule management (UFW)
- Service management to ensure BIND9 starts on boot

## Requirements

- Ubuntu Server (tested on 16.04 LTS) or Debian
- Administrative (sudo/root) privileges
- Internet connection for package installation

## Usage

1. Make the script executable:
   ```bash
   chmod +x install_bind9_dns.sh
   ```

2. Run the script as root:
   ```bash
   sudo ./install_bind9_dns.sh
   ```

3. The script will:
   - Install required packages
   - Configure BIND9 with proper zone files
   - Set up forward and reverse DNS resolution
   - Configure and restart the service
   - Add necessary firewall rules if UFW is active
   - Test the DNS resolution

## Customization

Edit the script to modify:
- Domain name
- Network address
- DNS server IP and hostname
- DNS forwarders (currently set to Google DNS: 8.8.8.8 and 8.8.4.4)

## Post-Installation

After installation:
1. Update your client computers to use the new DNS server
2. Add additional DNS records as needed by modifying zone files in `/etc/bind/zones/`
3. After changes to zone files, remember to increment the serial number and restart BIND9:
   ```bash
   systemctl restart bind9
   ```

## Troubleshooting

If you encounter issues:
1. Check BIND9 service status: `systemctl status bind9`
2. Review logs: `journalctl -u bind9`
3. Validate configuration: `named-checkconf`
4. Test DNS resolution: `dig @10.100.0.10 ns1.firma.lan`

## License

This script is provided as-is, free to use and modify.

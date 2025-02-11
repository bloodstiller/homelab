# Homelab Configuration

This repository contains the configuration files for my personal homelab setup, primarily focused on media management and monitoring.

## Overview

This homelab runs on NixOS with the following key features:
- Caddy for reverse proxy (running directly on host)
- Let's Encrypt certificate management via Cloudflare DNS
- Secret management with agenix
- Automated system configuration through Nix
- Docker-based media management services
- ACL-based permission management

For NixOS-specific configuration details, see [NixOS Configuration](./nix/README.md).

## Infrastructure Setup

### Docker Data Storage
Docker data is stored on a dedicated virtual disk that is:
- Mounted to `/mnt/docker` in the VM
- Contains all Docker configuration data and persistent storage
- ACL-managed for permissions:
  - User `martin` has full rwx permissions
  - New files/directories inherit permissions automatically
- Structured as follows:
  ```
  /mnt/docker/
  └── homelab/
      └── dockerConfigs/
          ├── sonarr/
          ├── radarr/
          ├── lidarr/
          ├── prowlarr/
          └── homer/
  ```

### Media Storage
All media is stored on TrueNas Scale server using an NFS server (192.168.2.12) with the following mount points:
- `/mnt/MasterPool/Media/Movies` - Movie storage
- `/mnt/MasterPool/Media/TV` - TV Shows storage
- `/mnt/MasterPool/Media/Music` - Music storage
- `/mnt/MasterPool/Media/Downloads` - Download directory

## Services

### Media Management
- **Sonarr** (Port 8989) - TV Shows management and automation
- **Radarr** (Port 7878) - Movie management and automation
- **Lidarr** (Port 8686) - Music management and automation
- **Prowlarr** (Port 9696) - Indexer manager/proxy

### Remote Services
- **TrueNAS** - Media storage server (port 4443)
- **qBittorrent** - Torrent client (port 10095)
- **Proxmox VE 1** - Virtualization server (port 8006)
- **Proxmox VE 2** - Secondary virtualization server (port 8006)
- **Proxmox Backup Server** - Backup management (port 8007)
- **ASUS Router** - Network management
- **Pi-hole 1** - Primary DNS server
- **Pi-hole 2** - Secondary DNS server
- **Flaresolverr** (Port 8191) - Cloudflare challenge solver

### Reverse Proxy & SSL
- **Caddy** (Ports 80, 443)
  - Manages SSL certificates and reverse proxy
  - Provides Let's Encrypt certificates via Cloudflare DNS
  - Uses wildcard certificate for *.homelab.bloodstiller.com
  - Handles all HTTP/HTTPS traffic

### Dashboard
- **Homer** (Port 8080) - A modern and minimalist dashboard

## Security Features

- HTTPS for all services using Let's Encrypt certificates
- Cloudflare DNS integration for ACME validation
- SSH with ED25519 keys only
- Firewall configuration for required services
- TLS 1.3 enforced for all HTTPS connections
- ACL-based permissions for Docker data directory

## Setup Instructions

1. Clone this repository
2. Ensure NFS server is accessible at 192.168.2.12
3. Run the stack with:
   ```bash
   docker compose up -d
   ```

## Adding a New Service
When adding a new service to your homelab, follow these steps:

1. **Caddy Configuration**
   - Update the Caddy configuration in NixOS configuration.nix
   - Add a new virtual host block for your service
   - The wildcard certificate will automatically be used

2. **Pihole DNS Configuration**
   - Access Pihole admin interface
   - Add a new Local DNS record:
     - Domain: service.homelab.bloodstiller.com
     - IP Address: [Caddy host IP]

3. **Update Homer Dashboard**
   - Add the new service to `dockerConfigs/homer/config.yml`
   - Use the HTTPS URL format: `https://[service-name].homelab.bloodstiller.com`

## Network Configuration
- Hostname: nixos
- Firewall enabled with the following ports:
  ```
  TCP: 80, 443, 2049, 7878, 8080, 8191, 8686, 8989, 9696
  UDP: 2049 (NFS)
  ```
- Network Manager enabled

## Mount Points
All mount points are created with 0755 permissions and owned by martin:martin:
```
/mnt/media/
├── downloads/
├── movies/
├── tv/
└── music/
```

## Maintenance

- Update system: `sudo nixos-rebuild switch`
- View service logs: `journalctl -fu [service-name]`
- Check Caddy status: `systemctl status caddy`
- Monitor ACME cert renewals: `journalctl -fu acme-homelab.bloodstiller.com`
- Check ACL permissions: `getfacl /mnt/docker`
- Manually set ACLs if needed:
  ```bash
  sudo setfacl -R -m u:martin:rwx /mnt/docker     # Set permissions
  sudo setfacl -R -d -m u:martin:rwx /mnt/docker  # Set default ACLs
  ```
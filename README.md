# Homelab Configuration

This repository contains the configuration files for my personal homelab setup, primarily focused on media management and monitoring.

## Table of Contents
- [Homelab Configuration](#homelab-configuration)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Infrastructure](#infrastructure)
    - [Storage](#storage)
      - [Docker Data Storage](#docker-data-storage)
      - [Media Storage](#media-storage)
    - [Network Architecture](#network-architecture)
      - [VPN Configuration](#vpn-configuration)
  - [Services](#services)
    - [Media Management](#media-management)
    - [Remote Services](#remote-services)
    - [System Services](#system-services)
      - [Reverse Proxy \& SSL](#reverse-proxy--ssl)
      - [Dashboard](#dashboard)
    - [Monitoring Stack](#monitoring-stack)
    - [Download \& VPN Services](#download--vpn-services)
  - [Permission Management](#permission-management)
    - [Mount Points](#mount-points)
    - [Permission Management](#permission-management-1)
    - [TrueNAS Scale Permission Management](#truenas-scale-permission-management)
      - [Setting Permissions in TrueNAS SCALE](#setting-permissions-in-truenas-scale)
        - [Via Web UI:](#via-web-ui)
  - [Network Configuration](#network-configuration)
  - [Security Features](#security-features)
  - [Maintenance](#maintenance)
  - [Diagram:](#diagram)

## Overview

This homelab runs on NixOS with the following key features:
- Caddy for reverse proxy (running directly on host)
- Let's Encrypt certificate management via Cloudflare DNS
- Secret management with agenix
- Automated system configuration through Nix
- Docker-based media management services
- ACL-based permission management
- Comprehensive monitoring with Prometheus/Grafana stack

For NixOS-specific configuration details, see [NixOS Configuration](./nix/README.md).

## Infrastructure

### Storage

#### Docker Data Storage
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
          ├── homer/
          ├── qbitorrent/
          └── gluetun/
  ```

#### Media Storage
All media is stored on TrueNas Scale server using an NFS server (192.168.2.12) with the following mount points:
- `/mnt/MasterPool/Media/Movies` - Movie storage
- `/mnt/MasterPool/Media/TV` - TV Shows storage
- `/mnt/MasterPool/Media/Music` - Music storage
- `/mnt/MasterPool/Media/Downloads` - Download directory

### Network Architecture

#### VPN Configuration
The download stack is configured for privacy:
1. Gluetun container establishes VPN connection
2. qBittorrent container uses Gluetun's network (`network_mode: "service:gluetun"`)
3. All qBittorrent traffic (including WebUI) is routed through VPN
4. WebUI remains accessible at `https://qbittorrent.homelab.bloodstiller.com`

## Services

### Media Management
- **Sonarr** (Port 8989) - TV Shows management and automation
- **Radarr** (Port 7878) - Movie management and automation
- **Lidarr** (Port 8686) - Music management and automation
- **Prowlarr** (Port 9696) - Indexer manager/proxy

### Remote Services
- **TrueNAS** - Media storage server (port 4443)
- **Proxmox VE 1** - Virtualization server (port 8006)
- **Proxmox VE 2** - Secondary virtualization server (port 8006)
- **Proxmox Backup Server** - Backup management (port 8007)
- **ASUS Router** - Network management
- **Pi-hole 1** - Primary DNS server
- **Pi-hole 2** - Secondary DNS server
- **Flaresolverr** (Port 8191) - Cloudflare challenge solver

### System Services

#### Reverse Proxy & SSL
- **Caddy** (Ports 80, 443)
  - Manages SSL certificates and reverse proxy
  - Provides Let's Encrypt certificates via Cloudflare DNS
  - Uses wildcard certificate for *.homelab.bloodstiller.com
  - Handles all HTTP/HTTPS traffic
  - Enforces TLS 1.3 for all connections
  - Configured to handle self-signed certificates from internal services

#### Dashboard
- **Homer** (Port 8888) - A modern and minimalist dashboard

### Monitoring Stack
- **Prometheus** (Port 9090)
  - Time-series database for metrics storage
  - Central metrics collection point for all services
  - Configurable alert rules and recording rules
  - Accessible at `https://prometheus.homelab.bloodstiller.com`

- **Grafana** (Port 3000)
  - Feature-rich visualization platform
  - Pre-configured with Loki datasource
  - Accessible at `https://grafana.homelab.bloodstiller.com`
  - Anonymous access enabled with Admin privileges for local use

- **Loki** (Port 3100)
  - Log aggregation system
  - Collects logs from all system and container services
  - Integrates with Grafana for log visualization
  - Uses efficient log indexing and querying

- **Promtail**
  - Log collector agent for Loki
  - Automatically discovers and scrapes container logs
  - Forwards logs to Loki for storage
  - Configured to add metadata and labels to logs

- **Node Exporter** (Port 9100)
  - Collects host-level metrics
  - Exposes hardware and OS metrics for monitoring
  - CPU, memory, disk, and network usage statistics
  - Accessible at `https://node-exporter.homelab.bloodstiller.com`

- **cAdvisor** (Port 8181)
  - Container resource usage and performance metrics
  - Real-time resource usage data for all Docker containers
  - Helps identify resource bottlenecks
  - Accessible at `https://cadvisor.homelab.bloodstiller.com`

### Download & VPN Services
- **Gluetun** - VPN client container
  - Provides VPN connectivity through Private Internet Access
  - All qBittorrent traffic routed through VPN
  - Credentials managed via `.env` file
  - Configured for UK servers (London, Manchester)
  - Server selection can be configured by:
    ```bash
    # List available servers
    docker run --rm -v /mnt/docker/homelab/DockerConfigs/gluetun:/gluetun qmcgaw/gluetun format-servers -private-internet-access
    
    # Configure multiple servers in compose.yml using comma-separated values:
    SERVER_REGIONS=UK London, UK Manchester
    ```
- **qBittorrent** (Port 10095) 
  - Download client for all media services
  - WebUI accessible through Gluetun's network
  - All traffic routed through VPN for privacy
  - Download directory mounted to `/mnt/media/downloads`

## Permission Management

### Mount Points
All mount points are created with 775 permissions and owned by martin:martin:
```
/mnt/media/
├── downloads/  # chmod 775 for Sonarr write access
├── movies/     # chmod 775 for Radarr write access
├── tv/         # chmod 775 for Sonarr write access
└── music/      # chmod 775 for Lidarr write access
```

### Permission Management
Media directories need 775 permissions to allow services to:
- Read files (7 for owner)
- Write/modify files (7 for group)
- Read files for other users (5 for others)

To fix permissions:
```bash
# Set ownership
sudo chown -R martin:martin /mnt/media/*

# Set directory permissions
sudo chmod -R 775 /mnt/media/*
```

### TrueNAS Scale Permission Management

#### Setting Permissions in TrueNAS SCALE

##### Via Web UI:
1. Go to Datasets
2. Select your Media dataset
3. Click "Edit Permissions"
4. Set:
   - Owner: martin (1000)
   - Group: martin (1000)
   - Set permissions for User:
     - Read ✓
     - Write ✓
     - Execute ✓
   - Set permissions for Group:
     - Read ✓
     - Write ✓
     - Execute ✓
   - Set permissions for Others:
     - Read ✓
     - Execute ✓
   - Check "Apply permissions recursively"
   - Enable "Apply User"
   - Enable "Apply Group"

This creates the equivalent of 775 permissions:
- User (owner): rwx (7)
- Group: rwx (7)
- Others: rx (5)

## Network Configuration
- Hostname: nixos
- Firewall enabled with the following ports:
  ```
  TCP: 80, 443, 2049, 3000, 3100, 7878, 8080, 8181, 8191, 8686, 8989, 9090, 9100, 9696
  UDP: 2049 (NFS)
  ```
- Network Manager enabled

## Security Features
- HTTPS for all services using Let's Encrypt certificates
- Cloudflare DNS integration for ACME validation
  - Wildcard certificate for `*.homelab.bloodstiller.com`
  - Automated certificate renewal
  - All certificates managed by Caddy
- SSH with ED25519 keys only
- Firewall configuration for required services
- TLS 1.3 enforced for all HTTPS connections
- ACL-based permissions for Docker data directory
- Secrets management with agenix (encrypted secrets in Git)

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
- Monitor container stats: `https://cadvisor.homelab.bloodstiller.com`
- View system metrics: `https://grafana.homelab.bloodstiller.com`

## Diagram:


```
                                                  ┌─────────────────┐
                                                  │   Cloudflare    │
                                                  │     (DNS)       │
                                                  └────────┬────────┘
                                                          │
                                                          ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                                  NIXOS HOST                               │
│                                                                           │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────────┐   │
│   │    Caddy    │◄───│    Pihole   │    │        Docker Network       │   │
│   │(Rev. Proxy) │    │ (Local DNS) │    │                             │   │
│   └──────┬──────┘    └─────────────┘    │  ┌─────────┐  ┌─────────┐   │   │
│          │                              │  │ Sonarr  │  │ Radarr  │   │   │
│          │                              │  └─────────┘  └─────────┘   │   │
│          │                              │  ┌─────────┐  ┌─────────┐   │   │
│          │                              │  │ Lidarr  │  │ Prowlarr│   │   │
│          │                              │  └─────────┘  └─────────┘   │   │
│          │                              │  ┌─────────┐                │   │
│          │                              │  │ Homer   │                │   │
│          │                              │  └─────────┘                │   │
│          │                              │                             │   │
│          │                              │  ┌────────────────────┐     │   │
│          │                              │  │      Gluetun       │     │   │
│          │                              │  │    (VPN Client)    │     │   │
│          │                              │  │   ┌────────────┐   │     │   │
│          │                              │  │   │qBittorrent │   │     │   │
│          │                              │  │   └────────────┘   │     │   │
│          │                              │  └─────────┬──────────┘     │   │
│          │                              │                             │   │
│          │                              │  ┌─────────┐  ┌─────────┐   │   │
│          │                              │  │Prometheus│  │ Grafana │  │   │
│          │                              │  └─────────┘  └─────────┘   │   │
│          │                              │  ┌─────────┐  ┌─────────┐   │   │
│          │                              │  │  Loki   │  │Promtail │   │   │
│          │                              │  └─────────┘  └─────────┘   │   │
│          │                              │  ┌─────────┐  ┌─────────┐   │   │
│          │                              │  │cAdvisor │  │Node-Exp.│   │   │
│          │                              │  └─────────┘  └─────────┘   │   │
│          │                              │                             │   │
│          └──────────────────────────────┼─────────────────────────────┘   │
└─────────────────────────────────────────┼─────────────────────────────────┘
                                          │
                                          │
┌──────────────────┐                      │
│   TrueNAS Scale  │◄─────────────────────┘
│   (NFS Server)   │                     
└──────────────────┘                     
```


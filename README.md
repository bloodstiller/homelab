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
  - [System Configuration](#system-configuration)
    - [User Setup](#user-setup)
    - [System Settings](#system-settings)
    - [Docker Configuration](#docker-configuration)
  - [Services](#services)
    - [Media Management](#media-management)
    - [Remote Services](#remote-services)
    - [System Services](#system-services)
      - [Reverse Proxy \& SSL](#reverse-proxy--ssl)
      - [Dashboard](#dashboard)
    - [Monitoring Stack](#monitoring-stack)
      - [Remote Node Monitoring](#remote-node-monitoring)
    - [Download \& VPN Services](#download--vpn-services)
  - [Secret Management](#secret-management)
    - [Setting up agenix](#setting-up-agenix)
    - [Current Secrets](#current-secrets)
    - [Finding Your Keys](#finding-your-keys)
  - [Permission Management](#permission-management)
    - [Mount Points](#mount-points)
    - [Permission Management](#permission-management-1)
    - [TrueNAS Scale Permission Management](#truenas-scale-permission-management)
      - [Setting Permissions in TrueNAS SCALE](#setting-permissions-in-truenas-scale)
        - [Via Web UI:](#via-web-ui)
  - [Network Configuration](#network-configuration)
  - [Security Features](#security-features)
  - [Setup Instructions](#setup-instructions)
    - [Required DNS Records](#required-dns-records)
    - [Installation Steps](#installation-steps)
  - [Repository Structure](#repository-structure)
    - [Managing Secrets and Configuration](#managing-secrets-and-configuration)
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
          ├── gluetun/
          ├── prometheus/
          ├── grafana/
          ├── loki/
          ├── promtail/
          └── node-exporter/
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

## System Configuration

### User Setup
- Default user 'martin' is created with:
  - Automatic login enabled
  - Member of networkmanager, wheel, and docker groups
  - SSH key access configured
  - Sudo privileges (via wheel group)

### System Settings
- Timezone: Europe/London
- Locale: en_GB.UTF-8
- Keyboard: US layout for X11, UK layout for console
- GRUB bootloader on /dev/sda with OS probing enabled
- ACL support enabled for filesystems

### Docker Configuration
- Data directory: /mnt/docker
- ACL permissions automatically set for user 'martin'
- Rootless Docker support with privileged port binding
- Custom data root location in /mnt/docker

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

#### Remote Node Monitoring

The `Nodes` directory contains configuration for collecting metrics and logs from remote nodes (such as Raspberry Pis, VMs, or other servers) in your network. This integrates with your central Prometheus and Loki instances to provide a unified view of your entire homelab infrastructure.

1. **Prerequisites**:
   - Docker and Docker Compose installed on the remote node
   - Network connectivity between the remote node and the central Prometheus/Loki server (192.168.2.113:3100)
   - User with sudo/docker permissions

2. **Setup Process**:
   - Create a directory on the remote node:
     ```bash
     mkdir -p ~/monitoring
     cd ~/monitoring
     ```
   
   - Copy the configuration files from this repository:
     ```bash
     # Copy both files to the remote node
     scp Nodes/compose.yml Nodes/promtail-config.yml user@remote-node:~/monitoring/
     ```

   - Modify the Promtail configuration on the remote node:
     ```bash
     # Edit the client URL if your Loki instance is different from 192.168.2.113:3100
     nano ~/monitoring/promtail-config.yml
     ```

   - Customize the container names in compose.yml to reflect the node identity:
     ```bash
     # Example: change pi2-node to server1-node
     nano ~/monitoring/compose.yml
     ```

   - Start the monitoring stack:
     ```bash
     cd ~/monitoring
     docker compose up -d
     ```

3. **Verification**:
   - Check that containers are running:
     ```bash
     docker ps
     ```
   
   - Verify node-exporter metrics are available:
     ```bash
     curl http://localhost:9100/metrics
     ```
   
   - Verify cAdvisor metrics are available:
     ```bash
     curl http://localhost:8080/metrics
     ```

4. **Configure Central Prometheus**:
   - Add the remote node to your Prometheus scrape configuration (in `/mnt/docker/homelab/dockerConfigs/prometheus/prometheus.yml`):
     ```yaml
     - job_name: 'remote_node'
       static_configs:
         - targets: ['remote-node-ip:9100']
           labels:
             instance: 'remote-node-name'
     
     - job_name: 'remote_cadvisor'
       static_configs:
         - targets: ['remote-node-ip:8080']
           labels:
             instance: 'remote-node-name'
     ```

5. **Components**:
   - **node-exporter**: Collects system metrics (CPU, memory, disk, network)
   - **cAdvisor**: Collects container metrics
   - **Promtail**: Collects and forwards logs to central Loki instance

This setup enables centralized monitoring of all nodes in your homelab with minimal configuration overhead. The collected metrics and logs will appear in your Grafana dashboards alongside your main server data.

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

## Secret Management

This configuration uses [agenix](https://github.com/ryantm/agenix) for managing secrets. Secrets are encrypted with age and can only be decrypted by the host system and authorized users.

### Setting up agenix

1. Install agenix (already included in configuration.nix)

2. Create a `secrets.nix` file to define who can decrypt which secrets:
   ```nix
   let 
     # User SSH keys
     user1 = "ssh-ed25519 AAAAC3..."; # Your SSH public key
     users = [ user1 ];

     # System SSH host keys
     server1 = "ssh-ed25519 AAAAC3..."; # Your NixOS host key
     systems = [ server1 ];

   in
   {
     # Define which keys can decrypt which secrets
     "user-password.age".publicKeys = systems ++ users;
     "caddy-basicauth.age".publicKeys = [ server1 ];
     "cloudflare.age".publicKeys = systems ++ users;
   }
   ```

3. Create your secrets:
   ```bash
   # Cloudflare API token for ACME
   agenix -e secrets/cloudflare.age
   # Add: CLOUDFLARE_DNS_API_TOKEN=your_token_here

   # Basic auth for Caddy (if needed)
   agenix -e secrets/caddy-basicauth.age
   # Add your htpasswd format credentials
   ```

### Current Secrets
- `cloudflare.age`: Cloudflare API token for ACME DNS validation
- `caddy-basicauth.age`: Basic auth credentials for protected services
- `user-password.age`: User password hashes

### Finding Your Keys
- Get your user's SSH public key:
  ```bash
  cat ~/.ssh/id_ed25519.pub
  ```
- Get your system's SSH host key:
  ```bash
  cat /etc/ssh/ssh_host_ed25519_key.pub
  ```

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

## Setup Instructions

### Required DNS Records

Add the following A records to your DNS (via Pi-hole or Cloudflare):
```
homelab.bloodstiller.com
*.homelab.bloodstiller.com

pbs.homelab.bloodstiller.com
pve.homelab.bloodstiller.com
pve2.homelab.bloodstiller.com
etc.....
```

### Installation Steps

1. Install NixOS following the standard installation guide
2. Clone this repository
3. Create a Cloudflare API token with DNS management permissions
4. Create the secrets file:
   ```bash
   agenix -e /etc/secrets/cloudflare.age
   ```
   Add your Cloudflare API token:
   ```
   CLOUDFLARE_DNS_API_TOKEN=your_token_here
   ```
5. Copy configuration.nix to `/etc/nixos/configuration.nix`
6. Run:
   ```bash
   sudo nixos-rebuild switch
   ```

## Repository Structure

```
/
├── README.md
├── docker-compose.yml
├── .env
├── Nodes/
│   ├── compose.yml
│   └── promtail-config.yml
└── nix/
    ├── README.md
    ├── configuration.nix
    ├── hardware-configuration.nix
    ├── sync.sh
    ├── secrets/
    │   ├── cloudflare.age
    │   ├── caddy-basicauth.age
    │   └── user-password.age
    └── secrets.nix
```

### Managing Secrets and Configuration

The repository includes a sync script (`nix/sync.sh`) that helps keep your repository in sync with the system configuration:

```bash
./nix/sync.sh
```

This script will:
- Sync all `.age` files from `/etc/secrets` to the `nix/secrets/` directory
- Copy `hardware-configuration.nix` from the system
- Copy `configuration.nix` from the system
- Display what files were updated

Run this script before committing changes to ensure your repository stays up to date.

The .age files are safe to commit to Git as they're encrypted and can only be decrypted by authorized keys.

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
                                                  ┌────────────────┐
                                                  │   Cloudflare   │
                                                  │     (DNS)      │
                                                  └───────┬────────┘
                                                          │
                                                          ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                                  NIXOS HOST                               │
│                                                                           │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────────┐   │
│   │    Caddy    │◄───┤  Pihole 1   │    │        Docker Network       │   │
│   │(Rev. Proxy) │    └─────────────┘    │                             │   │
│   │             │    ┌─────────────┐    │  ┌───────────┐ ┌───────────┐│   │
│   │             │◄───┤  Pihole 2   │    │  │  Sonarr   │ │  Radarr   ││   │
│   └──────┬──────┘    └─────────────┘    │  └───────────┘ └───────────┘│   │
│          │                              │  ┌───────────┐ ┌───────────┐│   │
│          │                              │  │  Lidarr   │ │ Prowlarr  ││   │
│          │                              │  └───────────┘ └───────────┘│   │
│          │                              │  ┌───────────┐              │   │
│          │                              │  │   Homer   │              │   │
│          │                              │  └───────────┘              │   │
│          │                              │                             │   │
│          │                              │  ┌────────────────────┐     │   │
│          │                              │  │      Gluetun       │     │   │
│          │                              │  │    (VPN Client)    │     │   │
│          │                              │  │   ┌────────────┐   │     │   │
│          │                              │  │   │qBittorrent │   │     │   │
│          │                              │  │   └────────────┘   │     │   │
│          │                              │  └─────────┬──────────┘     │   │
│          │                              │                             │   │
│          │                              │  ┌───────────┐ ┌───────────┐│   │
│          │                              │  │Prometheus │ │  Grafana  ││   │
│          │                              │  └───────────┘ └───────────┘│   │
│          │                              │  ┌───────────┐ ┌───────────┐│   │
│          │                              │  │   Loki    │ │ Promtail  ││   │
│          │                              │  └───────────┘ └───────────┘│   │
│          │                              │  ┌───────────┐ ┌───────────┐│   │
│          │                              │  │ cAdvisor  │ │Node-Exp.  ││   │
│          │                              │  └───────────┘ └───────────┘│   │
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


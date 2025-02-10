# Homelab Configuration

This repository contains the configuration files for my personal homelab setup, primarily focused on media management and monitoring.

## Services

### Media Management
- **Sonarr** (Port 8989) - TV Shows management and automation - [LinuxServer.io docs](https://docs.linuxserver.io/images/docker-sonarr/)
- **Radarr** (Port 7878) - Movie management and automation - [LinuxServer.io docs](https://docs.linuxserver.io/images/docker-radarr/)
- **Lidarr** (Port 8686) - Music management and automation - [LinuxServer.io docs](https://docs.linuxserver.io/images/docker-lidarr/)
- **Prowlarr** (Port 9696) - Indexer manager/proxy - [LinuxServer.io docs](https://docs.linuxserver.io/images/docker-prowlarr/)

### Reverse Proxy & SSL
- **Nginx Proxy Manager** (Ports 80, 81, 443) - Manages SSL certificates and reverse proxy
  - Provides local SSL certificates for all services
  - Uses wildcard certificate for *.homelab.bloodstiller.com
  - Admin interface available on port 81
  - Handles all HTTP/HTTPS traffic on ports 80/443

### Dashboard
- **Homer** (Port 8080) - A modern and minimalist dashboard
- More information further down in the README

## Container Images

All media management services use official LinuxServer.io images:
- `lscr.io/linuxserver/sonarr:latest`
- `lscr.io/linuxserver/radarr:latest`
- `lscr.io/linuxserver/lidarr:latest`
- `lscr.io/linuxserver/prowlarr:latest`

- I would not usually use the latest version of the image, but I am using the latest version for this project as linuxserver.io images are well maintained and have a good community support.

## Volume Configuration

All media is stored on TrueNas Scale server using an NFS server (192.168.2.12) with the following mount points:
- `/mnt/MasterPool/Media/Movies` - Movie storage
- `/mnt/MasterPool/Media/TV` - TV Shows storage
- `/mnt/MasterPool/Media/Music` - Music storage
- `/mnt/MasterPool/Media/Downloads` - Download directory

## Infrastructure Setup

### Docker Data Storage
The Docker data is stored on a dedicated virtual disk that is:
- Mounted to `/mnt/docker` in the VM
- Contains all Docker configuration data and persistent storage
- Structured as follows:
  ```
  /mnt/docker/
  └── homelab/
      └── dockerConfigs/
          ├── sonarr/
          ├── radarr/
          ├── lidarr/
          ├── prowlarr/
          ├── nginx-proxy-manager/
          └── homer/
  ```

### Docker Storage Configuration
To configure Docker to use the dedicated storage disk:

1. Stop Docker services:
   ```bash
   sudo systemctl stop docker.service
   sudo systemctl stop docker.socket
   ```

2. Create Docker configuration directory:
   ```bash
   sudo mkdir -p /mnt/docker
   ```

3. If migrating existing Docker data, copy it to the new location:
   ```bash
   sudo rsync -aP /var/lib/docker/ /mnt/docker/
   ```
   This command:
   - Preserves all permissions and attributes (-a)
   - Shows progress during transfer (-P)
   - Copies all existing Docker data to the new location

4. Update Docker's configuration to use the new location:
   ```bash
   sudo nano /etc/docker/daemon.json
   ```
   Add:
   ```json
   {
      "data-root": "/mnt/docker"
   }
   ```

5. Start Docker services:
   ```bash
   sudo systemctl start docker.socket
   sudo systemctl start docker.service
   ```

6. Verify the configuration:
   ```bash
   sudo docker info | grep "Docker Root Dir"
   ```

7. After confirming everything works, optionally remove the old Docker data:
   ```bash
   sudo rm -rf /var/lib/docker/
   ```

This configuration ensures:
- Docker data is stored on a dedicated disk
- Easy backup and restoration through Proxmox
- Prevention of root partition space issues
- Better management of Docker storage growth

### Backup Strategy
This setup enables efficient backups through Proxmox Backup Server:
- The `/mnt/docker` mount point is included in VM backups
- All Docker configurations and data are preserved in backups
- Allows for complete restoration of services in case of VM failure
- Backup schedule can be managed through Proxmox Backup Server
- Separating the data drive from the OS drive allows for:
  - Smaller OS backups
  - Faster recovery times
  - Easy migration to new VMs if needed

## Setup Instructions

1. Clone this repository
2. Ensure NFS server is accessible at 192.168.2.12
3. Run the stack with:
   ```bash
   docker compose up -d
   ```
4. Access Nginx Proxy Manager on port 81 to configure:
   - SSL certificates for *.homelab.bloodstiller.com
   - Proxy hosts for each service

The required directory structure will be created automatically:
```
./dockerConfigs/
├── sonarr/
├── radarr/
├── lidarr/
├── prowlarr/
├── nginx-proxy-manager/
└── homer/
```

## Notes
- All services run with PUID=1000 and PGID=1000
- Time zone is set to UTC by default
- Services use the 'unless-stopped' restart policy

## Commented Services
- **FlareSolverr** - Currently commented out in the compose file, can be enabled if needed for handling challenging websites

## Dashboard Configuration (Homer)
Homer dashboard is configured via `dockerConfigs/homer/config.yml` and uses icons from the [dashboard-icons](https://github.com/homarr-labs/dashboard-icons) submodule.

### Service URLs
All services in the Homer dashboard are configured to use HTTPS URLs (e.g., `https://service.homelab.bloodstiller.com`), utilizing the SSL certificates managed by Nginx Proxy Manager. This ensures secure access to all services through the dashboard.

### Service Groups

1. **TV & Movies**
   - Plex - Media streaming server
   - Radarr - Movie management
   - Sonarr - TV Show management

2. **Networking**
   - Asus Router - Network management
   - Pihole (x2) - DNS and ad blocking
   - Nginx Proxy Manager - Reverse proxy management

3. **Storage/NAS**
   - TrueNAS Scale - Storage management interface

4. **Proxmox**
   - PVE1 & PVE2 - Virtualization servers
   - Proxmox Backup Server - Backup management

5. **Downloads**
   - qBittorrent - Download client
   - Prowlarr - Indexer management

6. **Music**
   - Lidarr - Music collection management

7. **Proton**
   - Proton Mail
   - Proton Calendar

8. **Useful Links**
   - WhatsApp Web
   - Amazon
   - GitHub

### Theme Configuration
- Layout: List view
- Color Theme: Dark mode
- Custom stylesheet enabled
- Footer: Disabled
- Connectivity Check: Enabled

### Access
The dashboard is accessible on port 8080 and provides quick access to all homelab services through a clean, organized interface.

## SSL and DNS Configuration Process

### Adding a New Service
When adding a new service to your homelab, follow these steps to set up SSL and DNS:

1. **Nginx Proxy Manager Configuration**
   - Access Nginx Proxy Manager at port 81
   - Add a new Proxy Host
   - Select the existing wildcard Let's Encrypt SSL certificate (*.homelab.bloodstiller.com)
   - Configure the proxy host with:
     - Domain: service.homelab.bloodstiller.com
     - Scheme: http
     - Forward Hostname/IP: service-container-name
     - Forward Port: container-exposed-port

2. **Pihole DNS Configuration**
   - Access Pihole admin interface
   - Add a new Local DNS record:
     - Domain: service.homelab.bloodstiller.com
     - IP Address: [Nginx Proxy Manager host IP]

3. **Update Homer Dashboard**
   - Add the new service to `dockerConfigs/homer/config.yml`
   - Use the HTTPS URL format: `https://service.homelab.bloodstiller.com`
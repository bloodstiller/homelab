# Homelab Configuration

This repository contains the configuration files for my personal homelab setup, primarily focused on media management and monitoring.

## Services

### Media Management
- **Sonarr** (Port 8989) - TV Shows management and automation - [LinuxServer.io docs](https://docs.linuxserver.io/images/docker-sonarr/)
- **Radarr** (Port 7878) - Movie management and automation - [LinuxServer.io docs](https://docs.linuxserver.io/images/docker-radarr/)
- **Lidarr** (Port 8686) - Music management and automation - [LinuxServer.io docs](https://docs.linuxserver.io/images/docker-lidarr/)
- **Prowlarr** (Port 9696) - Indexer manager/proxy - [LinuxServer.io docs](https://docs.linuxserver.io/images/docker-prowlarr/)

### Dashboard
- **Homer** (Port 8080) - A modern and minimalist dashboard

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

## Setup Instructions

1. Clone this repository
2. Ensure NFS server is accessible at 192.168.2.12
3. Run the stack with:
   ```bash
   docker compose up -d
   ```

The required directory structure will be created automatically:
```
./dockerConfigs/
├── sonarr/
├── radarr/
├── lidarr/
├── prowlarr/
└── homer/
```

## Notes
- All services run with PUID=1000 and PGID=1000
- Time zone is set to UTC by default
- Services use the 'unless-stopped' restart policy

## Commented Services
- **FlareSolverr** - Currently commented out in the compose file, can be enabled if needed for handling challenging websites

## Dashboard Configuration
Homer dashboard is configured via `dockerConfigs/homer/config.yml` and uses icons from the [dashboard-icons](https://github.com/homarr-labs/dashboard-icons) submodule.

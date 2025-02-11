# NixOS Homelab Configuration

This repository contains my NixOS configuration for managing a homelab server that acts as a central media management system and reverse proxy for various services.

## Overview

This NixOS configuration sets up:
- Reverse proxy with Caddy (HTTPS for all services)
- Media management suite (Sonarr, Radarr, Lidarr, Prowlarr)
- Docker support
- NFS mounts for media storage
- Secure SSH access
- Let's Encrypt certificate management via Cloudflare DNS
- Secret management with agenix

## Prerequisites

- NixOS 24.11 or later
- A Cloudflare account with DNS management for your domain
- TrueNAS or similar NAS for media storage
- Pi-hole for local DNS management
- Age key pair for secrets management
- Docker (configured to store data in /mnt/docker)

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

### Network Configuration
- NetworkManager enabled
- Hostname: nixos
- Firewall configured with the following ports:
  ```
  TCP: 80, 443, 2049, 7878, 8080, 8191, 8686, 8989, 9696
  UDP: 2049
  ```

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

## Services Proxied

### Local Services (Running on this host)
- Homer Dashboard (`:8080`)
- Sonarr (`:8989`)
- Radarr (`:7878`)
- Lidarr (`:8686`)
- Prowlarr (`:9696`)
- Flaresolverr (`:8191`)

### Remote Services
- TrueNAS (`192.168.2.12:4443`)
- qBittorrent (`192.168.2.12:10095`)
- Proxmox VE 1 (`192.168.2.178:8006`)
- Proxmox VE 2 (`192.168.2.175:8006`)
- Proxmox Backup Server (`192.168.2.179:8007`)
- ASUS Router (`192.168.2.1`)
- Pi-hole 1 (`192.168.2.136`)
- Pi-hole 2 (`192.168.2.195`)

## NFS Mounts

Media is mounted from a TrueNAS server (`192.168.2.12`) with the following structure:
- `/mnt/media/downloads`
- `/mnt/media/movies`
- `/mnt/media/tv`
- `/mnt/media/music`

## Security Features

- HTTPS for all services using Let's Encrypt certificates
- Cloudflare DNS integration for ACME validation
- SSH with ED25519 keys only
- Firewall configuration for required services
- TLS 1.3 enforced for all HTTPS connections

## Setup Instructions

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

## Required DNS Records

Add the following A records to your DNS (via Pi-hole or Cloudflare):
```
homelab.bloodstiller.com
*.homelab.bloodstiller.com

pbs.homelab.bloodstiller.com
pve.homelab.bloodstiller.com
pve2.homelab.bloodstiller.com
etc.....
```

## Maintenance

- Update system: `sudo nixos-rebuild switch`
- View service logs: `journalctl -fu [service-name]`
- Check Caddy status: `systemctl status caddy`
- Monitor ACME cert renewals: `journalctl -fu acme-homelab.bloodstiller.com`

## Notes

- Docker data is stored in `/mnt/docker`
- All services use a wildcard certificate for `*.homelab.bloodstiller.com`
- Self-signed certificates for internal services (Proxmox, TrueNAS) are ignored by the reverse proxy. 

## Repository Structure

```
/nix/
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

The repository includes a sync script (`sync.sh`) that helps keep your repository in sync with the system configuration:

```bash
./sync.sh
```

This script will:
- Sync all `.age` files from `/etc/secrets` to the `secrets/` directory
- Copy `hardware-configuration.nix` from the system
- Copy `configuration.nix` from the system
- Display what files were updated

Run this script before committing changes to ensure your repository stays up to date.

### Git Configuration

Add to your .gitignore:
```gitignore
/result
```

The .age files are safe to commit to Git as they're encrypted and can only be decrypted by authorized keys.

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      "${builtins.fetchTarball "https://github.com/ryantm/agenix/archive/main.tar.gz"}/modules/age.nix"
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.martin = {
    isNormalUser = true;
    description = "martin";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [];
  };
  users.users.martin.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOg2VKzAytPvs9aArki7JPDyOLjn6+/soebm7JJdNQ5x martin@Lok" 
  ];
  # Enable automatic login for the user.
  services.getty.autologinUser = "martin";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    acl
    wget
    git
    nfs-utils
    rsync
    (pkgs.callPackage "${builtins.fetchTarball "https://github.com/ryantm/agenix/archive/main.tar.gz"}/pkgs/agenix.nix" {})
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
   enable = true;
   enableSSHSupport = true;
  };

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      "data-root" = "/mnt/docker";
    };
  };

  # Add ACL support to the system
  boot.supportedFilesystems = [ "acl" ];


  # Set up ACLs for /mnt/docker after mounting
  system.activationScripts.dockerPermissions = {
    deps = [ "users" "groups" ];
    text = let
      setfacl = "${pkgs.acl}/bin/setfacl";
    in ''
      echo "Setting up permissions for /mnt/docker"
      ${setfacl} -R -m u:martin:rwx /mnt/docker || true
      ${setfacl} -R -d -m u:martin:rwx /mnt/docker || true
    '';
  };


  # Allow rootless Docker to bind to privileged ports
  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 0;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # Create mount points with correct permissions
  systemd.tmpfiles.rules = [
    "d /mnt/media 0755 martin martin -"
    "d /mnt/media/downloads 0755 martin martin -"
    "d /mnt/media/movies 0755 martin martin -"
    "d /mnt/media/tv 0755 martin martin -"
    "d /mnt/media/music 0755 martin martin -"
  ];


  # Define the NFS mounts
  fileSystems."/mnt/media/downloads" = {
    device = "192.168.2.12:/mnt/MasterPool/Media/Downloads";
    fsType = "nfs";
    options = [ "defaults" "_netdev" "user" "nofail" ];  # Add user mount option
  };

  fileSystems."/mnt/media/movies" = {
    device = "192.168.2.12:/mnt/MasterPool/Media/Movies";
    fsType = "nfs";
    options = [ "defaults" "_netdev" "user" "nofail" ];
  };

  fileSystems."/mnt/media/tv" = {
    device = "192.168.2.12:/mnt/MasterPool/Media/TV";
    fsType = "nfs";
    options = [ "defaults" "_netdev" "user" "nofail" ];
  };

  fileSystems."/mnt/media/music" = {
    device = "192.168.2.12:/mnt/MasterPool/Media/Music";
    fsType = "nfs";
    options = [ "defaults" "_netdev" "user" "nofail" ];
  };


# Port forwarding for rootless Docker
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      80    # caddy 
      443   # caddy https (if needed later)
      2049  # NFS
      7878  # Radarr
      8080  # Homer
      8191  # Flaresolverr
      8686  # Lidarr
      8989  # Sonarr
      9696  # Prowlarr
    ];
    allowedUDPPorts = [ 2049 ];  # For NFS
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  # ACME and Cloudflare configuration
  age.secrets.cloudflare.file = /etc/secrets/cloudflare.age;
  
  security.acme = {
    acceptTerms = true;
    defaults.email = "bloodstiller@bloodstiller.com";

    certs."homelab.bloodstiller.com" = {
      group = config.services.caddy.group;
      domain = "homelab.bloodstiller.com";
      extraDomainNames = [ "*.homelab.bloodstiller.com" ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      environmentFile = config.age.secrets.cloudflare.path;
      # Add Cloudflare credentials method
      credentialsFile = config.age.secrets.cloudflare.path;
    };
  };

  # Caddy reverse proxy configuration
  services.caddy = {
    enable = true;
    
    # qBittorrent configuration
    virtualHosts."qbittorrent.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://192.168.2.12:10095
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Proxmox Backup Server configuration
    virtualHosts."pbs.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy https://192.168.2.179:8007 {
        transport http {
          tls_insecure_skip_verify  # Required because PBS uses a self-signed cert internally
        }
      }
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Proxmox VE 1 configuration
    virtualHosts."pve.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy https://192.168.2.178:8006 {
        transport http {
          tls_insecure_skip_verify  # Required because Proxmox uses a self-signed cert internally
        }
      }
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Proxmox VE 2 configuration
    virtualHosts."pve2.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy https://192.168.2.175:8006 {
        transport http {
          tls_insecure_skip_verify  # Required because Proxmox uses a self-signed cert internally
        }
      }
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # TrueNAS configuration
    virtualHosts."truenas.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy https://192.168.2.12:4443 {
        transport http {
          tls_insecure_skip_verify  # Required because TrueNAS likely uses a self-signed cert internally
        }
      }
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # ASUS router configuration
    virtualHosts."asus.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://192.168.2.1
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Pi-hole 1 configuration
    virtualHosts."pihole.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://192.168.2.136
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Pi-hole 2 configuration
    virtualHosts."pihole2.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://192.168.2.195
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Homer dashboard
    virtualHosts."homer.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://localhost:8080
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Lidarr configuration
    virtualHosts."lidarr.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://localhost:8686
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Prowlarr configuration
    virtualHosts."prowlarr.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://localhost:9696
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Sonarr configuration
    virtualHosts."sonarr.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://localhost:8989
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';

    # Radarr configuration
    virtualHosts."radarr.homelab.bloodstiller.com".extraConfig = ''
      reverse_proxy http://localhost:7878
      
      tls /var/lib/acme/homelab.bloodstiller.com/cert.pem /var/lib/acme/homelab.bloodstiller.com/key.pem {
        protocols tls1.3
      }
    '';
  };
}


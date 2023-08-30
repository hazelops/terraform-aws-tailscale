#cloud-config
hostname: ${hostname}
yum_repos:
  tailscale-stable:
    name: tailscale-stable
    enabled: true
    repo_gpgcheck: true
    gpgcheck: false
    baseurl: https://pkgs.tailscale.com/stable/amazon-linux/2/$basearch
    gpgkey: https://pkgs.tailscale.com/stable/amazon-linux/2/repo.gpg
packages:
  - tailscale
write_files:
  - path: /etc/sysctl.conf
    content: |
      net.ipv4.ip_forward = 1
      net.ipv6.conf.all.forwarding = 1
runcmd:
  - sysctl -p /etc/sysctl.conf
  - systemctl enable --now tailscaled
  - tailscale up --authkey "${tailscale_auth_key}" --advertise-routes "${tailscale_advertise_routes}" --hostname "${hostname}"

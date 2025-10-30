Cloud Engineer Challenge — README

Overview
- This repo contains automation and network scripts for connecting an on-premises site to AWS (IPsec VPN), cloud infrastructure deployment, and **automated Joget DX application installation both on-prem and in AWS**.
- **Joget DX is now installed automatically** via these scripts:
  - `onprem/setup_onprem.sh` (on-prem simulation)
  - `terraform/user_data.sh` (AWS EC2/Cloud, via Terraform)
  These scripts automate the Joget DX download and deployment steps. See details below for automated and manual installation options.

Prerequisites
- Local admin or cloud admin access.
- Linux host (for IPsec): Ubuntu/CentOS recommended, strongSwan or Libreswan installed.
- AWS account with VPC and permissions to create Customer Gateway, Virtual Private Gateway, and VPN Connection.
- For Joget DX: Java 11+ and a supported DB (MySQL / MariaDB / PostgreSQL). The automated install uses the Joget Linux platform bundle which includes Tomcat and startup scripts.

Quick start
1. Review the network scripts in this repo to identify the local public IP and local private network used.
2. Follow "Configure IPsec tunnel to AWS" below to create the AWS side resources and configure the local IPsec host.
3. Deploy Joget DX using the provided automation:
   - On-prem: run `onprem/setup_onprem.sh`
   - AWS: `terraform apply` (uses `terraform/user_data.sh` on EC2)

Configure IPsec tunnel to AWS (high level)
1. On AWS:
   - Create a Customer Gateway (type: static IP) using your on-prem public IP.
   - Create or attach a Virtual Private Gateway (VGW) to the target VPC.
   - Create a VPN Connection (AWS-managed IPsec) between the VGW and the Customer Gateway. Choose static or route-based (BGP) per your design.
   - Download the VPN configuration from the AWS Console (select your on-prem OS like "Generic" or "Ubuntu" to get parameters) — it contains tunnel IPs, PSK(s), and IKE/ESP proposals.

2. On-prem IPsec host shown using strongSwan
- Install strongSwan:
  - Ubuntu: `sudo apt update && sudo apt install -y strongswan strongswan-pki`
  - CentOS/RHEL: `sudo yum install -y strongswan`

- Example /etc/ipsec.conf (replace placeholders):
  ```
  conn aws-tunnel-1
      keyexchange=ikev2
      ike=aes256-sha1-modp1024
      esp=aes256-sha1
      left=%defaultroute
      leftid=@ONPREM_PUBLIC_IP_OR_FQDN
      leftsubnet=10.10.0.0/16
      leftsourceip=%config
      right=AWS_TUNNEL_IP_1
      rightid=@AWS_VPN_GATEWAY_ID_OR_IP
      rightsubnet=10.0.0.0/16
      auto=start
  ```

- Example /etc/ipsec.secrets:
  ```
  @ONPREM_PUBLIC_IP_OR_FQDN : PSK "YOUR_AWS_PSK_FROM_CONSOLE"
  ```

- Restart strongSwan:
  - `sudo systemctl restart strongswan` (Ubuntu/CentOS with systemd)
  - Check status: `sudo ipsec statusall` and `sudo journalctl -u strongswan -f`

Notes:
- Use the exact IKE/ESP parameters from the AWS downloaded config.
- AWS provides two tunnels — configure both for HA.
- If using BGP, configure FRR or Bird to speak BGP on the host or use a router appliance.

Route and firewall
- Ensure your on-prem firewall allows IPsec (UDP 500, UDP 4500) and ESP if applicable.
- Add routes for AWS subnets pointing to the IPsec host if the host is not the gateway.

Joget DX installation
- **This repo automates Joget DX using the Joget Linux platform bundle (tar.gz) on both simulated on-prem and AWS cloud environments.**
- See `onprem/setup_onprem.sh` and `terraform/user_data.sh` for working installation code. These scripts will download and set up Joget DX automatically. No manual `wget` or download is required if using the scripts.
- The scripts currently use this community edition download (platform bundle includes Tomcat & startup scripts):
  - https://sourceforge.net/projects/jogetworkflow/files/joget-linux-9.0.1.tar.gz/download

Manual (Joget Linux platform bundle)
- Download the Joget Linux bundle from: https://sourceforge.net/projects/jogetworkflow/files/joget-linux-9.0.1.tar.gz/download
- Ensure Java 11+ is installed on the host.
- Extract to a target directory, e.g.:
  - `sudo mkdir -p /opt/joget && sudo tar -xzf joget-linux-9.0.1.tar.gz -C /opt/joget --strip-components=1`
- Start Joget using the included script:
  - `nohup /opt/joget/joget-start.sh > ~/joget-start.log 2>&1 &`
- Prepare a supported database (MySQL/MariaDB/PostgreSQL), create a schema and user, and configure database credentials per Joget docs (e.g., properties under the Joget app directory).
- Access Joget DX at: `http://<host>:8080/` (or via port 80 if fronted by a reverse proxy like Apache, as in the AWS automation).
- For on-prem script automation: see `onprem/setup_onprem.sh`
- For AWS automation: see `terraform/user_data.sh`

# Homelab Dashboard

A small, dependency-free local dashboard for central management of homelab services. It is a single static page with quick-launch cards, plus a tiny CGI script that triggers a couple of router automations with one click.

Runs on **NGINX** on a **Raspberry Pi 5** (host OS: Debian 13 arm64). LAN only.

The dashboard UI example can be found [here](webpage.png).

## What's inside

| File | Purpose |
|------|---------|
| `index.html` | The dashboard UI (plain HTML/CSS/JS, no build step, no frameworks) |
| `/cgi-bin/run.sh` | Bash CGI script that executes whitelisted router commands |
| `icons/` | SVG icons used by the page (`dashboard.svg`, `pi-hole.svg`, `mikrotik.svg`, etc.) |

## Features

**Service launcher** – cards that open each service in a new tab:

- **Networking:** Pi-hole (DNS ad-blocking), MikroTik (RouterOS config)
- **Home Control:** Home Assistant, ESPHome, Fluidd (3D printer)

**System Automations** – buttons that call the CGI script via `POST /cgi-bin/run.sh?cmd=<action>`:

| Button | `cmd` | Action on the MikroTik router |
|--------|-------|-------------------------------|
| Set route to ISP1 | `mikrotik-set-isp1` | Runs script `ISP1-distance-1` (main route via Aermaxnet) |
| Set route to ISP2 | `mikrotik-set-isp2` | Runs script `ISP1-distance-3` (main route via Starlink) |

A console bar at the bottom shows the status or result of the last command (green on success, pink on error).

## Setup notes

`run.sh` runs as `www-data`, so the SSH key for the MikroTik `admin` user lives in `/var/www/.ssh` (the `www-data` home directory on Debian).

Don't forget to edit the service URLs in `index.html` to match your network.

## Install and deploy

Install the needed services and create empty folder

```bash
sudo apt install nginx fcgiwrap
sudo mkdir -p /var/www/dashboard
```

Copy `index.html`, `icons/`, and `cgi-bin/` to `/var/www/dashboard`. After that, continue with the commands

```bash
sudo chown -R www-data:www-data /var/www/dashboard
sudo chmod +x /var/www/dashboard/cgi-bin/run.sh
```

Next, create an NGINX site config

```bash
sudo nano /etc/nginx/sites-available/dashboard
```

Use this config as a reference and replace `server_name` with your hostname or IP address

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name pi.hole;

    root /var/www/dashboard;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /cgi-bin/ {
        root /var/www/dashboard;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
    }
}
```

Finish setup and restart NGINX. The dashboard will become available on your server hostname/IP address

```bash
sudo ln -s /etc/nginx/sites-available/dashboard /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

## Adding new things

- **New service card:** copy an existing `<a class="card ...">` block and change the link, icon, title and description. Glow colors: `cyan`, `purple`, `green`, `pink`, `blue`, `yellow`, `orange`.
- **Icons:** SVG icons for new services can be grabbed from [dashboardicons.com](https://dashboardicons.com/). All existing icons come from there. Drop the file into `icons/` and reference it as `icons/<name>.svg`.
- **New automation:** add a `<button class="card ..." onclick="runScript('<action>', '<label>')">` and a matching entry in the `case` block of `run.sh`.

## Security risks

There is no authentication, so keep this reachable from the local network only. The script never passes user input to the shell: commands are limited to the fixed whitelist in `run.sh`.

## License

This project is licensed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for details.
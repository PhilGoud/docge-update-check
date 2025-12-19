# Dockge Update Checker Script

A lightweight Bash script designed as a companion for [Dockge](https://github.com/louislam/dockge). 

It automatically checks your Dockge stacks for available Docker image updates, cleans up old layers, and sends notifications (Discord, Telegram, Gotify, etc.), allowing you to keep your server clean and up-to-date without blindly restarting services.

## Why use this with Dockge?

Dockge is excellent for managing stacks, but you might want proactive notifications when an image update is available **before** you log in. This script:
1.  **Pulls** the latest images for all your stacks in the background.
2.  **Compares** the running version vs. the pulled version.
3.  **Notifies** you if there is a difference.
4.  **Cleans up** dangling images to prevent disk usage bloat.
5.  **Does NOT restart** your containers. You remain in control and use the Dockge UI to apply updates when you are ready.

## Installation

### 1. Download the script
Run this on the host machine where Dockge is installed.

```bash
# Example directory
mkdir -p /opt/scripts
cd /opt/scripts
git clone [https://github.com/YOUR_USERNAME/dockge-update-checker.git](https://github.com/YOUR_USERNAME/dockge-update-checker.git) .
chmod +x dockge-update-check.sh

```

### 2. Configure Notifications

Copy the example environment file:

```bash
cp notification.env.example notification.env
nano notification.env

```

Add your webhook logic (Discord, Gotify, etc.) inside the `send_notif` function.

### 3. Check Paths

Open `dockge-update-check.sh` and ensure `STACKS_DIR` matches your Dockge configuration.

* Default Dockge path: `/opt/stacks`
* Script default: `/opt/stacks`

## Usage

### Manual Run

```bash
./dockge-update-check.sh

```

### Automatic Check (Cron)

To check for updates every day at 04:00 AM:

```bash
crontab -e

```

Add the following line:

```bash
0 4 * * * /opt/scripts/dockge-update-check.sh >> /var/log/dockge-update.log 2>&1

```

## How it works

1. It iterates through folders in `/opt/stacks`.
2. It runs `docker compose pull -q` to download new layers.
3. It inspects the Image ID of the running container and compares it with the local Image ID.
4. If they differ, it adds the stack to the notification list.
5. It runs `docker image prune -f` to remove the old image layers that are now "dangling" (replaced by the new pull).

## License

MIT



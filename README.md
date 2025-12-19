# Docker Stack Update Checker

A lightweight Bash script to check for updates across multiple Docker Compose stacks without automatically restarting them. It pulls new images, detects version differences, cleans up old image layers, and notifies you.

## Features

* **Non-Intrusive:** It pulls the latest images but does **not** restart your containers. You choose when to apply the updates.
* **Multi-Stack Support:** Scans a directory containing multiple sub-folders with `compose.yaml` or `docker-compose.yml` files.
* **Orphan Cleanup:** Automatically runs `docker image prune` to remove dangling images created by the pull process (saves disk space).
* **Notifications:** customizable hook to send alerts (Discord, Gotify, Telegram, etc.) when updates are found.
* **Detailed Summary:** Prints a clear table of which stacks and services have updates pending.

## Prerequisites

* Linux environment
* Docker and Docker Compose (V2 recommended) installed
* `bash`

## Installation

1.  Clone this repository or download the script:
    ```bash
    git clone [https://github.com/yourusername/docker-update-checker.git](https://github.com/yourusername/docker-update-checker.git)
    cd docker-update-checker
    chmod +x docker-update-check.sh
    ```

2.  (Optional) Setup Notifications:
    * Copy the example environment file:
        ```bash
        cp notification.env.example notification.env
        ```
    * Edit `notification.env` and add your webhook logic (Discord, Slack, Gotify, etc.).

## Configuration

Open `docker-update-check.sh` and adjust the variables at the top if needed:

* `STACKS_DIR`: The directory holding your stack folders (Default: `/DATA/stacks`).
* `NOTIF_FILE`: Path to your notification script (Default: `/scripts/notification.env`).

**Structure expectation:**
```text
/DATA/stacks/
├── stack-a/
│   └── compose.yaml
├── stack-b/
│   └── docker-compose.yml
└── ...

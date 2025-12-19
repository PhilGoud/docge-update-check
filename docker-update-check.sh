#!/bin/bash

# ==============================================================================
# Docker Stack Update Checker
# ==============================================================================
# This script iterates through Docker Compose stacks, pulls new images,
# checks if the running container is using an older image version,
# and notifies the user of available updates.
#
# It does NOT restart containers automatically. It only stages the images.
# ==============================================================================

# --- Configuration ---
# Directory containing your stack folders (each folder should have a compose.yaml or docker-compose.yml)
STACKS_DIR="${STACKS_DIR:-/DATA/stacks}"

# Path to the environment file containing the 'send_notif' function
# If not found, notifications will be skipped.
NOTIF_FILE="${NOTIF_FILE:-/scripts/notification.env}"

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- 1. Load Notification Function ---
if [ -f "$NOTIF_FILE" ]; then
    source "$NOTIF_FILE"
else
    # Define a dummy function to prevent errors if the file is missing
    send_notif() { :; }
    # Only show warning if the user hasn't explicitly silenced it (optional logic)
    echo -e "${YELLOW}Notice: Notification file $NOTIF_FILE not found. Notifications disabled.${NC}"
fi

# Initialize array to track updates
declare -a updates_list=()

echo -e "${BLUE}=== Checking for Docker Image Updates ===${NC}"

# Check if STACKS_DIR exists
if [ ! -d "$STACKS_DIR" ]; then
    echo -e "${RED}Error: Directory $STACKS_DIR does not exist.${NC}"
    exit 1
fi

# --- Main Loop ---
# We use find/sort to iterate through subdirectories safely
while read -r stack_path; do
    stack_name=$(basename "$stack_path")
    
    # Detect Compose file
    if [[ -f "$stack_path/compose.yaml" ]]; then
        compose_file="compose.yaml"
    elif [[ -f "$stack_path/docker-compose.yml" ]]; then
        compose_file="docker-compose.yml"
    else
        # Not a valid stack folder
        continue
    fi

    cd "$stack_path" || continue

    echo -n -e "Analyzing [${YELLOW}$stack_name${NC}]... "

    # Silent Pull (Downloads new layers, potentially making old images dangling)
    # This prepares the update without restarting the service yet.
    docker compose pull -q 2>/dev/null
    
    # Get list of services defined in the stack
    services=$(docker compose ps --services 2>/dev/null)

    if [ -z "$services" ]; then
        echo -e "${RED}Inactive (Skipped)${NC}"
        cd "$STACKS_DIR" || exit
        continue
    fi

    local_has_update=false
    
    for service in $services; do
        # Get Container ID
        container_id=$(docker compose ps -q "$service")
        if [ -z "$container_id" ]; then continue; fi

        # Logic:
        # 1. Get the Image Name defined in config (e.g., nginx:latest)
        # 2. Get the Hash of the image currently running in the container
        # 3. Get the Hash of the image currently sitting locally on disk (just pulled)
        
        image_name=$(docker inspect --format '{{.Config.Image}}' "$container_id")
        running_image_id=$(docker inspect --format '{{.Image}}' "$container_id")
        local_image_id=$(docker image inspect --format '{{.Id}}' "$image_name" 2>/dev/null)

        if [ -z "$local_image_id" ]; then continue; fi

        # If Running Hash != Local Disk Hash, a newer version was pulled
        if [ "$running_image_id" != "$local_image_id" ]; then
            if [ "$local_has_update" = false ]; then
                echo -e "${RED}Update found!${NC}"
                local_has_update=true
            fi
            echo -e "  └─ ${CYAN}$service${NC}"
            updates_list+=("$stack_name|$service")
        fi
    done

    if [ "$local_has_update" = false ]; then
        echo -e "${GREEN}OK${NC}"
    fi
    
    # Return to base directory
    cd "$STACKS_DIR" || exit

done < <(find "$STACKS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

# --- CLEANUP (PRUNE) ---

echo -e "\n${BLUE}=== Cleaning up Orphan Images ===${NC}"
# -f : Force (no confirmation prompt)
# We do NOT use -a (all), to ensure we don't delete images belonging to stopped stacks,
# only strictly dangling images (replaced by the 'pull' command above).
prune_output=$(docker image prune -f)

if [ -z "$prune_output" ]; then
    echo -e "${GREEN}Nothing to clean.${NC}"
else
    echo -e "${YELLOW}Space reclaimed:${NC}"
    echo "$prune_output"
fi

# --- SUMMARY AND NOTIFICATION ---

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}          UPDATE SUMMARY                ${NC}"
echo -e "${BLUE}========================================${NC}"

if [ ${#updates_list[@]} -gt 0 ]; then
    # Terminal Output
    echo -e "The following services have updates ready to apply:\n"
    printf "%-25s | %-25s\n" "STACK" "SERVICE"
    printf "%s\n" "--------------------------+--------------------------"
    
    for item in "${updates_list[@]}"; do
        IFS='|' read -r stack service <<< "$item"
        printf "${YELLOW}%-25s${NC} | ${CYAN}%-25s${NC}\n" "$stack" "$service"
    done
    
    # --- NOTIFICATION PREPARATION ---
    # format: "- StackName"
    stacks_formatted=$(printf "%s\n" "${updates_list[@]}" | cut -d'|' -f1 | sort -u | sed 's/^/- /')
    
    msg="🐋 Docker Updates Available:"$'\n'"$stacks_formatted"
    
    # Check if function exists before calling
    if declare -f send_notif > /dev/null; then
        echo -e "\n${BLUE}Sending notification...${NC}"
        send_notif "$msg"
    fi

    echo -e "\n${RED}-> To apply: Run 'docker compose up -d' in the respective directories.${NC}"
else
    echo -e "${GREEN}No updates detected. System is up to date!${NC}"
fi

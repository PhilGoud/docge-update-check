# docker-update-check
This script iterates through Docker Compose stacks, pulls new images, checks if the running container is using an older image version, # and notifies the user of available updates.  It does NOT restart containers automatically. It only stages the images.

# DevContainer & Docker Cheat Sheet

## Container Status & Inspection

### List Running Containers

docker ps
docker ps -a # Include stopped containers
docker compose ps # For compose projects

### Inspect Container Details

docker inspect <container_name_or_id>
docker compose config # View resolved compose config

## Logs

### View Container Logs

docker logs <container_name_or_id>
docker logs -f <container_name_or_id> # Follow logs (live)
docker logs --tail 100 <container_name_or_id> # Last 100 lines
docker logs --since 5m <container_name_or_id> # Last 5 minutes

### Docker Compose Logs

docker compose logs
docker compose logs -f # Follow all services
docker compose logs -f <service_name> # Follow specific service
docker compose logs --tail=50 <service_name>

## Shell Access

### Open Shell in Running Container

docker exec -it <container_name_or_id> /bin/bash
docker exec -it <container_name_or_id> /bin/sh # If bash not available
docker compose exec <service_name> /bin/bash

### Open Shell as Root (if needed)

docker exec -it -u root <container_name_or_id> /bin/bash

## Container Lifecycle

### Restart Container

docker restart <container_name_or_id>
docker compose restart
docker compose restart <service_name>

### Stop Container

docker stop <container_name_or_id>
docker compose stop
docker compose stop <service_name>

### Start Stopped Container

docker start <container_name_or_id>
docker compose start
docker compose start <service_name>

### Remove Container (must be stopped first)

docker rm <container_name_or_id>
docker rm -f <container_name_or_id> # Force remove running container
docker compose rm # Remove stopped containers
docker compose rm -f # Force remove

## Full Rebuild & Recreate

### Rebuild DevContainer from VS Code

# Command Palette (Ctrl+Shift+P / Cmd+Shift+P):

# "Dev Containers: Rebuild Container"

# "Dev Containers: Rebuild Container Without Cache"

### Docker Compose - Rebuild & Recreate

docker compose down # Stop and remove containers
docker compose up -d # Recreate and start
docker compose up -d --build # Rebuild images + recreate
docker compose up -d --force-recreate # Force recreate without rebuild
docker compose down -v # Remove containers + volumes (DELETES DATA!)

docker compose -f ".devcontainer/docker-compose.yml" --profile ALL build --no-cache

### Complete Clean Slate (DELETES EVERYTHING)

docker compose down -v --rmi all # Remove containers, volumes, images
docker compose up -d --build # Rebuild from scratch

## Image Management

### List Images

docker images
docker compose images

### Remove Images

docker rmi <image_id>
docker image prune # Remove dangling images
docker image prune -a # Remove all unused images

### Build Images

docker compose build
docker compose build --no-cache # Build without cache
docker compose build <service_name> # Build specific service

## Volume Management

### List Volumes

docker volume ls

### Inspect Volume

docker volume inspect <volume_name>

### Remove Volume (DELETES DATA!)

docker volume rm <volume_name>
docker volume prune # Remove all unused volumes

## Network Management

### List Networks

docker network ls

### Inspect Network

docker network inspect <network_name>

## Clean Up Commands

### Remove Stopped Containers

docker container prune

### Clean Up Everything (CAREFUL!)

docker system prune # Remove stopped containers, unused networks, dangling images
docker system prune -a # Also remove unused images
docker system prune -a --volumes # NUCLEAR OPTION - removes volumes too

## DevContainer Specific

### Get Container Name for Current DevContainer

# Usually in format: <folder_name>-devcontainer-<service>-1

docker ps --filter "label=devcontainer.local_folder"

### Find DevContainer's Docker Compose File

# Usually in: .devcontainer/docker-compose.yml or .devcontainer/compose.yml

### View DevContainer Config

# Check: .devcontainer/devcontainer.json

## Common Workflows

### Fresh Start (Keep Code, Clear Data)

docker compose down -v
docker compose up -d

### Complete Rebuild (Code Changes in Dockerfile)

docker compose down
docker compose build --no-cache
docker compose up -d

### Quick Restart (Config Changes)

docker compose restart

### Debug Container That Won't Start

docker compose up # Run in foreground to see errors
docker logs <container_name> # Check logs

## System Maintenance & Cleanup

**Important:** Docker accumulates storage over time from images, containers, volumes, and build cache. Regular cleanup prevents disk space issues.

### Check Disk Usage

docker system df # See how much space Docker is using
docker system df -v # Detailed breakdown by resource type

### Safe Cleanup (Recommended)

# Remove stopped containers, unused networks, and dangling images
docker system prune

# Clean up for this project only
docker compose down # Stop and remove project containers
docker volume prune # Remove unused volumes (check before confirming!)

### Aggressive Cleanup (When You Need Space)

# WARNING: Removes ALL unused images (not just dangling ones)
docker system prune -a

# NUCLEAR OPTION: Remove everything unused (containers, images, volumes, cache)
# This will delete data in unused volumes!
docker system prune -a --volumes

### What Gets Removed

- `docker system prune`: Stopped containers, unused networks, dangling images (no tags), build cache
- `docker system prune -a`: All of the above + **all unused images** (even tagged ones)
- `docker system prune -a --volumes`: All of the above + **all unused volumes (DATA LOSS!)**

### When to Clean Up

- **Weekly/Monthly:** Run `docker system prune` to remove build cache and dangling images
- **Before major updates:** Run `docker system prune -a` to clear old images
- **Low disk space:** Check `docker system df`, then use appropriate prune command
- **After removing projects:** Remove associated volumes with `docker volume prune`

**Pro Tip:** Closing VS Code/Cursor does **NOT** stop your dev containers. Always use `docker compose down` or stop containers explicitly to free up memory.

## Tips

# Find container name quickly:

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Copy files from/to container:

docker cp <container>:/path/in/container /local/path
docker cp /local/path <container>:/path/in/container

# Check resource usage:

docker stats
docker stats <container_name>

# Get container IP address:

docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container>

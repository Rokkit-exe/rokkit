#!/bin/bash

# Check if server is available by pinging its IP address
SERVER_IP="192.168.0.100"  # Replace with your server's IP address

# server names and their ports
APPS=("adguard:30004" "ollama:10000" "searxng:40000" "dashy:31003" "it-tools:15000" "plex:32400" "sonarr:30027" "radarr:30025" "prowlarr:30050" "qbittorrent:30024" "portainer:31015")

# Loop through each app and ping the server IP and port
APP_COUNT=${#APPS[@]}
STATUS=0


# if whole server is down, set tooltip to server down
if ping -c 1 -W 1 $SERVER_IP > /dev/null 2>&1; then
  for APP in "${APPS[@]}"; do
      NAME=$(echo "$APP" | cut -d':' -f1)
      PORT=$(echo "$APP" | cut -d':' -f2)
      
      if timeout 1 nc -zv "$SERVER_IP" "$PORT" > /dev/null 2>&1; then
        (( STATUS+=1 ))
      fi
  done

  if [ "$STATUS" -eq "$APP_COUNT" ]; then
      MAIN_TEXT="Server: "
  elif [ $STATUS -gt 0 ]; then
      MAIN_TEXT="Server: $STATUS / $APP_COUNT"
  else
      MAIN_TEXT="Server: "
  fi
else
  MAIN_TEXT="Server: "
fi

# Print the output in JSON format for Waybar
echo -e "$MAIN_TEXT"

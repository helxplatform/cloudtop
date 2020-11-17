#!/usr/bin/with-contenv sh

cp -rn /app/guacamole /config
chmod -R 777 /config/guacamole
mkdir -p /root/.config/freerdp/known_hosts

#!/usr/bin/with-contenv sh

cat /app/guacamole/server-template.xml | envsubst > /usr/local/tomcat/conf/server.xml

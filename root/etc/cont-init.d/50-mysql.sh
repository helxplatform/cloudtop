#!/usr/bin/with-contenv sh

# Replace the template vars with the ENV vars
head -60 /app/guacamole/add-user-template.sql | envsubst > /app/guacamole/add-user.sql

# become the postgres user
service mysql start

# create the guacamole database
mysql -e "create database guacamole_db"

# Create the needed tables
cd /app/guacamole/guacamole-auth-jdbc-1.3.0/mysql
cat schema/*.sql | mysql -u root  guacamole_db

# Execute the script to create the user and connections
mysql --skip-password < /app/guacamole/add-user.sql

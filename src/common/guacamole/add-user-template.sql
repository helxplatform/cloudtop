-- Generate salt
CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'helx-bdcat';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
FLUSH PRIVILEGES;
use guacamole_db;
SET @username = '${USER_NAME}';
SET @password = '${VNC_PW}';
SET @conn = 'ohif-conn';
SET @salt = UNHEX(SHA2(UUID(), 256));

-- Create base entity entry for user
INSERT INTO guacamole_entity (name, type)
VALUES (@username, 'USER');

-- Create user and hash password with salt
INSERT INTO guacamole_user (
            entity_id,
            password_salt,
            password_hash,
            password_date
)
SELECT
    entity_id,
    @salt,
    UNHEX(SHA2(CONCAT(@password, HEX(@salt)), 256)),
    CURRENT_TIMESTAMP
FROM guacamole_entity
WHERE
    name = @username
    AND type = 'USER';

-- Insert the needed connectiom
INSERT INTO guacamole_connection (connection_name, protocol) VALUES (@conn, 'vnc');

-- Get the connection_id
set @connection_id := (select connection_id
FROM guacamole_connection WHERE connection_name = @conn);

-- Get the needed entity id
set @entity_id := (select entity_id FROM guacamole_entity WHERE name = @username);

-- Now the needed parameters
INSERT INTO guacamole_connection_parameter VALUES (@connection_id, 'hostname', 'localhost');
INSERT INTO guacamole_connection_parameter VALUES (@connection_id, 'port', '5901');
INSERT INTO guacamole_connection_parameter VALUES (@connection_id, 'password', @password);

-- and the connection permission table
INSERT INTO guacamole_connection_permission VALUES (@entity_id, @connection_id, 'READ');

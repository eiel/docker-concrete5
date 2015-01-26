#!/bin/bash
set -e

if [ -z "$MYSQL_PORT_3306_TCP" ]; then
	echo >&2 'error: missing MYSQL_PORT_3306_TCP environment variable'
	echo >&2 '  Did you forget to --link some_mysql_container:mysql ?'
	exit 1
fi

# if we're linked to MySQL, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${CONCRETE5_DB_USER:=root}
if [ "$CONCRETE5_DB_USER" = 'root' ]; then
	: ${CONCRETE5_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${CONCRETE5_DB_NAME:=concrete5}

if [ -z "$CONCRETE5_DB_PASSWORD" ]; then
	echo >&2 'error: missing required CONCRETE5_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e CONCRETE5_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be CONCRETE5_DB_USER and CONCRETE5_DB_NAME.)'
	exit 1
fi

if ! [ -e index.php -a -e wp-includes/version.php ]; then
	echo >&2 "concrete5 not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
#	chmod 777 -R /usr/src/concrete5/{config,packages,files}
	rsync --archive --one-file-system --quiet /usr/src/concrete5/ ./
	echo >&2 "Complete! concrete5 has been successfully copied to $(pwd)"
fi

CONCRETE5_DB_HOST='mysql'
cat <<EOPHP > config/site_install.php
<?php
define('DB_SERVER', '$CONCRETE5_DB_HOST');
define('DB_USERNAME', '$CONCRETE5_DB_USER');
define('DB_PASSWORD', '$CONCRETE5_DB_PASSWORD');
define('DB_DATABASE', '$CONCRETE5_DB_NAME');
EOPHP


TERM=dumb php -- "$CONCRETE5_DB_HOST" "$CONCRETE5_DB_USER" "$CONCRETE5_DB_PASSWORD" "$CONCRETE5_DB_NAME" <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)
$stderr = fopen('php://stderr', 'w');
list($host, $port) = explode(':', $argv[1], 2);
$maxTries = 10;
do {
	$mysql = new mysqli($host, $argv[2], $argv[3], '', (int)$port);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);
if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($argv[4]) . '`')) {
	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}
$mysql->close();
EOPHP


chown -R apache:apache .

exec "$@"

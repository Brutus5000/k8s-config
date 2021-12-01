#!/bin/sh
# Setup mariadb users

# fail on errors
set -e

. ./k8s-helpers.sh

check_resource_exists_or_fail secret mariadb
check_resource_exists_or_fail service mariadb
check_resource_exists_or_fail pod mariadb-0

ROOT_PASSWORD=$(get_secret_value mariadb MYSQL_ROOT_PASSWORD)

# create_user(service_name, database_key, username_key, password_key, [db_options])
#
# Will create a user (if not exists) with matching username and password taken from configMap and secret
# of the service name
create_user_with_db() {
  SERVICE_NAME=$1

  check_resource_exists_or_fail configmap "$SERVICE_NAME"
  check_resource_exists_or_fail secret "$SERVICE_NAME"

  DATABASE=$(get_config_value "$SERVICE_NAME" "$2")
  USERNAME=$(get_config_value "$SERVICE_NAME" "$3")
  PASSWORD=$(get_secret_value "$SERVICE_NAME" "$4")
  DB_OPTIONS=$5

  echo "Create database ${DATABASE} and create + assign user ${USERNAME}"
  kubectl exec -i mariadb-0 -- mariadb --user=root --password="${ROOT_PASSWORD}" <<SQL_SCRIPT
      CREATE DATABASE IF NOT EXISTS \`${DATABASE}\` ${DB_OPTIONS};
      CREATE USER IF NOT EXISTS '${USERNAME}'@'%' IDENTIFIED BY '${PASSWORD}';
      GRANT ALL PRIVILEGES ON \`${DATABASE}\`.* TO '${USERNAME}'@'%';
SQL_SCRIPT
}

create_user_with_db wordpress WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD

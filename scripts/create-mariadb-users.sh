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

# grant_extra_permission(service_name, database_key, username_key, db_prefix)
#
# Will grant all privileges on databases matching db_prefix
grant_extra_permission() {
    SERVICE_NAME=$1
    DATABASE=$(get_config_value postal "$2")
    USERNAME=$(get_config_value postal "$3")
    DB_PREFIX=$(get_config_value postal "$4")

    echo "Assign all privileges to user ${USERNAME} for databses with prefix $DB_PREFIX"
    kubectl exec -i mariadb-0 -- mariadb --user=root --password="${ROOT_PASSWORD}" <<SQL_SCRIPT
        GRANT ALL PRIVILEGES ON \`${DB_PREFIX}%\`.* TO '${USERNAME}'@'%';
SQL_SCRIPT
}

# serviceName, database, username, password, dbOptions
create_user_with_db anope DB_NAME DB_USERNAME DB_PASSWORD
create_user_with_db wordpress WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD
create_user_with_db postal DB_NAME DB_USER DB_PASSWORD
create_user_with_db faf-api DATABASE_NAME DATABASE_USERNAME DATABASE_PASSWORD
create_user_with_db faf-api ANOPE_DATABASE_NAME DATABASE_USERNAME DATABASE_PASSWORD
create_user_with_db faf-api LEAGUE_DATABASE_NAME LEAGUE_DATABASE_USERNAME LEAGUE_DATABASE_PASSWORD
create_user_with_db faf-user-service DB_NAME DB_USERNAME DB_PASSWORD
create_user_with_db faf-db-migrations JUST_FOR_TESTING_DB_NAME FLYWAY_USER FLYWAY_PASSWORD
create_user_with_db ory-hydra DB_NAME DB_USERNAME DB_PASSWORD
create_user_with_db faf-lobby-server DB_NAME DB_USERNAME DB_PASSWORD
create_user_with_db faf-lobby-server ANOPE_DB_NAME DB_USERNAME DB_PASSWORD
create_user_with_db faf-replay-server DB_NAME DB_USERNAME RS_DB_PASSWORD
create_user_with_db faf-policy-server DATABASE_NAME DATABASE_USER DATABASE_PASSWORD
create_user_with_db faf-league-service DB_NAME DB_LOGIN DB_PASSWORD

# Postal creates 1 database per "server" (I'd rather say it's a tenant)
grant_extra_permission postal DB_NAME DB_USER DB_TENANT_PREFIX
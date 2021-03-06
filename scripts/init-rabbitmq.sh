#!/bin/sh
# Setup rabbitmq vhost and users

# fail on errors
set -e

. ./k8s-helpers.sh

check_resource_exists_or_fail secret rabbitmq
check_resource_exists_or_fail statefulset rabbitmq
check_resource_exists_or_fail pod rabbitmq-0

# create_vhost(vhost_name)
#
# Will create a blank vhost
create_vhost() {
  VHOST_NAME=$1
  kubectl exec -i rabbitmq-0 -- rabbitmqctl add_vhost "$VHOST_NAME"
}

# create_user_for_vhost(service_name, username_key, password_key, vhost_key)
#
# Will create a user (if not exists) with matching username and password taken from configMap and secret
# of the service name
create_user_for_vhost() {
  SERVICE_NAME=$1
  USERNAME=$(get_config_value "$SERVICE_NAME" "$2")
  PASSWORD=$(get_secret_value "$SERVICE_NAME" "$3")
  VHOST_NAME=$4

  echo "Creating RabbitMQ user $USERNAME for vhost $VHOST_NAME"
  # fuck you grep for your incapability to process hyphens
  USER_EXISTS=$(kubectl exec rabbitmq-0 -- rabbitmqctl list_users | sed -n "/$USERNAME/p" | wc -l)

  if [ "$USER_EXISTS" -eq 1 ]
  then
    echo "WARNING: User already exists. Will be recreated!"
    kubectl exec -i rabbitmq-0 -- rabbitmqctl delete_user "${USERNAME}"
  fi

  kubectl exec -i rabbitmq-0 -- rabbitmqctl add_user "${USERNAME}" "${PASSWORD}"
  kubectl exec -i rabbitmq-0 -- rabbitmqctl set_permissions -p "${VHOST_NAME}" "${USERNAME}" ".*" ".*" ".*"
}

VHOST_FAF_CORE="/faf-core"
VHOST_POSTAL="/postal"

create_vhost $VHOST_POSTAL
create_user_for_vhost postal RABBITMQ_USER RABBITMQ_PASSWORD $VHOST_POSTAL

create_vhost $VHOST_FAF_CORE
create_user_for_vhost faf-lobby-server RABBITMQ_USER RABBITMQ_PASSWORD $VHOST_FAF_CORE
create_user_for_vhost faf-league-service MQ_USER MQ_PASSWORD $VHOST_FAF_CORE

#docker-compose exec faf-rabbitmq rabbitmqctl add_vhost "${RABBITMQ_POSTAL_VHOST}"
#docker-compose exec faf-rabbitmq rabbitmqctl add_user "${RABBITMQ_POSTAL_USER}" "${RABBITMQ_POSTAL_PASS}"
#docker-compose exec faf-rabbitmq rabbitmqctl set_permissions -p "${RABBITMQ_POSTAL_VHOST}" "${RABBITMQ_POSTAL_USER}" ".*" ".*" ".*"

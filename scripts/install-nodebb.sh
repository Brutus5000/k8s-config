#!/bin/sh
# Setup mongodb user and run the nodebb setup

# fail on errors
set -e

. ./k8s-helpers.sh

check_resource_exists_or_fail configmap mongodb
check_resource_exists_or_fail secret mongodb
check_resource_exists_or_fail service mongodb
check_resource_exists_or_fail pod mongodb-0
check_resource_exists_or_fail configmap nodebb
check_resource_exists_or_fail secret nodebb
check_resource_exists_or_fail service nodebb
check_resource_exists_or_fail deployment nodebb

if has_annotation_with_value statefulset mongodb "faf_users_nodebb" "created"
then
  echo "MongoDB user for NodeBB already exists"
else
  echo "Creating MongoDB user for NodeBB"

  ROOT_USERNAME=$(get_config_value mongodb MONGO_INITDB_ROOT_USERNAME)
  ROOT_PASSWORD=$(get_secret_value mongodb MONGO_INITDB_ROOT_PASSWORD)

  NODEBB_DATABASE=$(get_config_value nodebb MONGO_DATABASE)
  NODEBB_USERNAME=$(get_config_value nodebb MONGO_USERNAME)
  NODEBB_PASSWORD=$(get_secret_value nodebb MONGO_PASSWORD)

  echo "Creating user ${NODEBB_USERNAME} with roles"

  kubectl exec -i mongodb-0 -- mongo -u "$ROOT_USERNAME" -p "$ROOT_PASSWORD" <<MONGODB_SCRIPT
  use ${NODEBB_DATABASE};
  db.createUser( { user: "${NODEBB_USERNAME}", pwd: "${NODEBB_PASSWORD}", roles: [ "readWrite" ] } );
  db.grantRolesToUser("${NODEBB_USERNAME}",[{ role: "clusterMonitor", db: "admin" }]);
MONGODB_SCRIPT

  kubectl annotate statefulset mongodb faf_users_nodebb=created
fi

if has_annotation_with_value deployment nodebb setup "done"
then
  echo "NodeBB setup was already started"
else
  # Ensure we have a fresh pod that did not crash yet
  echo "Restarting NodeBB pod"
  kubectl scale --replicas=0 deployment nodebb
  kubectl scale --replicas=1 deployment nodebb
  NODEBB_POD=$(get_newest_pod_by_app_name nodebb)

  echo "Running NodeBB setup"
  kubectl exec "$NODEBB_POD" -c nodebb -- ./nodebb setup
  kubectl annotate deployment nodebb setup="done"

  echo "##########################################################################################################"
  echo "# Please write down the admin password and store it safely. You will need it in case OAuth setup breaks. #"
  echo "##########################################################################################################"
fi


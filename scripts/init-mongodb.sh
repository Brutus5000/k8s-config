#!/bin/sh
# A one time script to setup mongodb users

# fail on errors
set -e

. ./k8s-helpers.sh

ANNOTATION_NAME="faf_users_nodebb"
ANNOTATION_VALUE="created"

check_resource_exists_or_fail configmap mongodb
check_resource_exists_or_fail secret mongodb
check_resource_exists_or_fail service mongodb
check_resource_exists_or_fail pod mongodb-0

if has_annotation_with_value statefulset mongodb "$ANNOTATION_NAME" "$ANNOTATION_VALUE"
then
  echo "NodeBB user already exists. Aborting."
  exit 1
else
  ROOT_USERNAME=$(get_pod_variable mongodb-0 MONGO_INITDB_ROOT_USERNAME)
  ROOT_PASSWORD=$(get_pod_variable mongodb-0 MONGO_INITDB_ROOT_PASSWORD)
  NODEBB_DATABASE=$(get_pod_variable mongodb-0 MONGO_NODEBB_DATABASE)
  NODEBB_USERNAME=$(get_pod_variable mongodb-0 MONGO_NODEBB_USERNAME)
  NODEBB_PASSWORD=$(get_pod_variable mongodb-0 MONGO_NODEBB_PASSWORD)

  echo "Creating user ${NODEBB_USERNAME} with roles"

  kubectl exec -i mongodb-0 -- mongo -u "$ROOT_USERNAME" -p "$ROOT_PASSWORD" <<MONGODB_SCRIPT
  use ${NODEBB_DATABASE};
  db.createUser( { user: "${NODEBB_USERNAME}", pwd: "${NODEBB_PASSWORD}", roles: [ "readWrite" ] } );
  db.grantRolesToUser("${NODEBB_USERNAME}",[{ role: "clusterMonitor", db: "admin" }]);
MONGODB_SCRIPT

  kubectl annotate statefulset mongodb "$ANNOTATION_NAME"="$ANNOTATION_VALUE"
fi

#!/bin/sh
# Helper functions for interacting with a k8s cluster

# fail on errors
set -e

# contains(string, substring)
#
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
contains() {
  string="$1"
  substring="$2"
  if test "${string#*$substring}" != "$string"
  then
    return 0  # $substring is in $string
  else
    return 1  # $substring is not in $string
  fi
}

# check_cluster()
#
# Returns 0 if the current kubectl cluster is faf-k8s or otherwise if it is manually confirmed
# otherwise returns 1
check_cluster() {
  echo -n "You are using kubectl from: "
  which kubectl
  cluster=$(kubectl config current-context)

  if [ "$cluster" != "faf-k8s" ]
  then
    echo "Please make sure your kubectl context is set to faf."
    echo -n "Confirm [y/n]: "
    read -r confirm
    if [ "$confirm" != 'y' ]; then exit 1; fi;
  fi
}

check_resource_exists_or_fail() {
  RESOURCE_TYPE=$1
  RESOURCE_NAME=$2

  EXISTS=$(kubectl get "$RESOURCE_TYPE" "$RESOURCE_NAME" >/dev/null 2>/dev/null && echo true || echo false)
  if test "$EXISTS" = "false"
  then
    echo "$RESOURCE_TYPE $RESOURCE_NAME missing. Aborting."
    exit 1
  fi
}

get_newest_pod_by_app_name() {
  APP_NAME=$1
  kubectl get pod -l app="$APP_NAME" -o jsonpath="{.items[0].metadata.name}" --sort-by=.status.startTime | tail -n 1
}

get_config_value() {
  kubectl get cm "$1" -o json | jq -r ".data.${2}"
}

get_secret_value() {
  kubectl get secret "$1" -o json | jq -r ".data.${2}" | base64 -d
}

# has_annotation(resourceType [e.g. pod], resourceName [e.g. mongodb], annotationName, annotationValue)
#
# Returns 0 if the annotation is present with the required value for the k8s resource
# otherwise returns 1.
has_annotation_with_value() {
  RESOURCE_TYPE=$1
  RESOURCE_NAME=$2
  ANNOTATION_NAME=$3
  REQUIRED_VALUE=$4

  ACTUAL_VALUE=$(kubectl get "$RESOURCE_TYPE" "$RESOURCE_NAME" -o json | jq -r ".metadata.annotations.$ANNOTATION_NAME")

  if test "$REQUIRED_VALUE" = "$ACTUAL_VALUE"
  then
    return 0
  else
    return 1
  fi
}
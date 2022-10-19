#!/bin/sh
# Port forwarding for predefined things

# fail on errors
set -e

. ./k8s-helpers.sh

check_cluster

case $1 in
  traefik)
    echo "The dashboard will be available under http://localhost:9000/dashboard/"
    kubectl port-forward -n kube-system deployment/traefik 9000:9000
  ;;
  *)
    echo "Please specify one of the following dashboards: traefik"
esac
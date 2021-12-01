#!/bin/sh
# Setup all ingress routes based on base url

# fail on errors
set -e

if [ -z "$1" ]; then
    echo "You need to give a domain name"
    exit 1
fi

export FAF_BASE_DOMAIN=$1

. ./k8s-helpers.sh

check_cluster

for file in ../ingress/*.yml
do
    cat "$file" | envsubst | kubectl apply -f -
done
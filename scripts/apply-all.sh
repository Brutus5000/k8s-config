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

apply_folder() {
  # shellcheck disable=SC2231
  # globbing in $1 is intended here
  for file in ../$1/*.yml
  do
    # shellcheck disable=SC2002
    # cat is required with envsubst
    cat "$file" | sed -e "s/##FAF_BASE_DOMAIN##/$FAF_BASE_DOMAIN/g" | kubectl apply -f -
  done
}

apply_folder secrets.template # TODO: don't use template
apply_folder config.template  # TODO: don't use template
apply_folder ingress
apply_folder "apps/*"

#!/bin/sh
# Setup rabbitmq vhost and users

# fail on errors
set -e

. ./k8s-helpers.sh

check_resource_exists_or_fail secret postal
check_resource_exists_or_fail deployment postal-web
check_resource_exists_or_fail statefulset mariadb
check_resource_exists_or_fail statefulset rabbitmq

if has_annotation_with_value configmap postal db "initialized"
then
  echo "Postal database already initialized"
else
  echo "Initializing Postal database"
  kubectl exec -i deployment/postal-web -c postal-web -- postal initialize
  kubectl annotate configmap/postal db=initialized
fi

if has_annotation_with_value configmap postal user "initialized"
then
  echo "Postal primary user already initialized. If you want to make more, you can run:"
  echo "    kubectl exec -it deployment/postal-web -c postal-web -- postal make-user"
else
  echo "All fields are mandatory & the password must be at least 8 characters long"
  kubectl exec -it deployment/postal-web -c postal-web -- postal make-user
  kubectl annotate configmap/postal user=initialized
  echo "Note: if creating the user failed you have to rerun it via:"
  echo "    kubectl exec -it deployment/postal-web -c postal-web -- postal make-user"
fi

echo
echo "You will have to setup Postal via the webinterface now (organisation, domains, server). This can't be scripted as of now."
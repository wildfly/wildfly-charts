#!/bin/bash

#!/usr/bin/env bash
# exit immediately when a command fails
set -e
# avoid exiting with non-zero if any of the pipeline commands fail because we need retries for oc login
#set -o pipefail
# error on unset variables
set -u
# print each command before executing it
set -x

printenv KUBECONFIG
printenv KUBEADMIN_PASSWORD_FILE

oc get node
oc config view

export TEST_CLUSTER_URL=$(oc whoami --show-server)
read CLUSTER_ADDRESS <<< $(echo ${TEST_CLUSTER_URL} | awk -F: '{ print substr($2,3) }')
CLUSTER_ADDRESS=${CLUSTER_ADDRESS/api/router-default.apps}
# read CLUSTER_IP <<< $(getent hosts ${CLUSTER_ADDRESS} | awk '{aggr=aggr " " $1} END {print aggr}')
export CLUSTER_ADDRESS=${CLUSTER_ADDRESS}
echo "CLUSTER ADDRESS is found: " + ${CLUSTER_ADDRESS}

export SYSADMIN_USERNAME=kubeadmin
export SYSADMIN_PASSWORD=$(cat "${KUBEADMIN_PASSWORD_FILE}")

oc login --insecure-skip-tls-verify "${TEST_CLUSTER_URL}" -u ${SYSADMIN_USERNAME} -p "${SYSADMIN_PASSWORD}"
oc new-project wildfly-charts || oc project wildfly-charts

ls -l /var/run/registry-quay-io-pull-secret/

oc apply -f /var/run/registry-quay-io-pull-secret/ehugonne-quay-robot-secret.yml --namespace=wildfly-charts

cd tests/bats
export IMAGE_REGISTRY=quay.io/ehugonne
export BATS_LIBS_BASEDIR=/usr/lib/bats
[ -d ../test-common ] || mkdir ../test-common
touch ../test-common/test.env
echo "BATS_LIBS_BASEDIR=/usr/lib/bats" >> ../test-common/test.env
echo "PUSH_TO_REGISTRY=false" >> ../test-common/test.env
echo "USE_OPENSHIFT=true" >> ../test-common/test.env
echo "IMAGE_REGISTRY=quay.io/ehugonne" >> ../test-common/test.env
echo "CLUSTER_CLIENT=oc" >> ../test-common/test.env
echo "CLUSTER_ADDRESS="${CLUSTER_ADDRESS} >> ../test-common/test.env
bats --timing --trace --verbose-run -r . 
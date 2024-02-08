setup() {
    if [ -f ../test-common/test.env ]
    then
      echo 'Loading env from ${PWD}/../test-common/test.env' >&3
      export $(cat ../test-common/test.env | xargs)
    else
      echo 'No file ${PWD}/../test-common/test.env found' >&3
    fi
    load ${BATS_LIBS_BASEDIR}/bats-support/load
    load ${BATS_LIBS_BASEDIR}/bats-assert/load
}

teardown () {
  helm uninstall test-metadata --wait --timeout=90s
}

@test "Deploy with labels" {
     cat <<EOF | helm install test-metadata ../../charts/wildfly --wait --timeout=90s -f -
image:
  name: ${IMAGE_REGISTRY}/helloworld
build:
  enabled: false # Disable S2I build
deploy:
  labels:
    foo-label: bar
  route:
    enabled: false # Disable OpenShift Route
  imagePullSecrets:
    - name: github-secret
EOF

    run ${CLUSTER_CLIENT} get deployment test-metadata -o jsonpath='{.metadata.labels}'
    assert_output --partial '"foo-label":"bar"'
}

@test "Deploy with annotations" {
     cat <<EOF | helm install test-metadata ../../charts/wildfly --wait --timeout=90s -f -
image:
  name: ${IMAGE_REGISTRY}/helloworld
build:
  enabled: false # Disable S2I build
deploy:
  annotations:
    foo-annotation: bar
  route:
    enabled: false # Disable OpenShift Route
  imagePullSecrets:
    - name: github-secret
EOF

    run ${CLUSTER_CLIENT} get deployment test-metadata -o jsonpath='{.metadata.annotations}'
    assert_output --partial '"foo-annotation":"bar"'
}

setup() {
    load '../test-common/bats-support/load'
    load '../test-common/bats-assert/load'
}

teardown () {
   helm delete test-metadata --wait --timeout=90s
}

@test "Deploy with labels" {
     cat <<EOF | helm install test-metadata ../../charts/wildfly --wait --timeout=90s -f -
image:
  name: localhost:5001/helloworld
build:
  enabled: false # Disable S2I build
deploy:
  labels:
    foo-label: bar
  route:
    enabled: false # Disable OpenShift Route
EOF

    run kubectl get deployment test-metadata -o jsonpath='{.metadata.labels}'
    assert_output --partial '"foo-label":"bar"'
}

@test "Deploy with annotations" {
     cat <<EOF | helm install test-metadata ../../charts/wildfly --wait --timeout=90s -f -
image:
  name: localhost:5001/helloworld
build:
  enabled: false # Disable S2I build
deploy:
  annotations:
    foo-annotation: bar
  route:
    enabled: false # Disable OpenShift Route
EOF

    run kubectl get deployment test-metadata -o jsonpath='{.metadata.annotations}'
    assert_output --partial '"foo-annotation":"bar"'
}

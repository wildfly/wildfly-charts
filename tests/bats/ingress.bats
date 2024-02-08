setup() {
    if [ -f ../test-common/test.env ]
    then
      echo 'Loading env from $PWD/../test-common/test.env' >&3
      export $(cat ../test-common/test.env | xargs)
    else
      echo 'No file $PWD/../test-common/test.env found' >&3
    fi
    load ${BATS_LIBS_BASEDIR}/bats-support/load
    load ${BATS_LIBS_BASEDIR}/bats-assert/load
}

teardown () {
  helm uninstall test-ingress  --wait --timeout=90s
  ${CLUSTER_CLIENT} delete --ignore-not-found=true secret test-secret-tls
}

@test "Deploy with Ingress (without TLS)" {
       cat <<EOF | helm install test-ingress ../../charts/wildfly --wait --timeout=90s -f -
image:
  name: ${IMAGE_REGISTRY}/helloworld
build:
  enabled: false # Disable S2I build
deploy:
  ingress:
    host: ${CLUSTER_ADDRESS}
    enabled: true
  route:
    enabled: false # Disable OpenShift Route
  imagePullSecrets:
    - name: github-secret
EOF
    sleep 5    
    ${CLUSTER_CLIENT} wait deployment test-ingress --for condition=Available=True --timeout=90s
    ${CLUSTER_CLIENT} get ingress --namespace wildfly-charts -o json >&3
    run curl -v --no-progress-meter http://${CLUSTER_ADDRESS}/HelloWorld
    assert_output --partial  "200 OK"
    assert_output --partial  "Hello World"
}

@test "Deploy with Ingress with TLS" {
    pushd target/
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=wildfly.local"
    ${CLUSTER_CLIENT} create secret tls test-secret-tls --key="tls.key" --cert="tls.crt"
    popd 

       cat <<EOF | helm install test-ingress ../../charts/wildfly --wait --timeout=90s -f -
image:
  name: ${IMAGE_REGISTRY}/helloworld
build:
  enabled: false # Disable S2I build
deploy:
  ingress:
    enabled: true
    host: ${CLUSTER_ADDRESS}
    tls: 
      enabled: true
      secret: test-secret-tls
  route:
    enabled: false # Disable OpenShift Route
  imagePullSecrets:
    - name: github-secret
EOF
    sleep 5
    ${CLUSTER_CLIENT} wait deployment test-ingress --for condition=Available=True --timeout=90s
    ${CLUSTER_CLIENT} get ingress --namespace wildfly-charts -o json >&3
    # test with HTTPS
    run curl -v -k --no-progress-meter https://${CLUSTER_ADDRESS}/HelloWorld
    assert_output --partial  "*  subject: CN=wildfly.local"
    assert_output --partial  "Hello World"
    # verify that HTTP is redirected to HTTPS
    run curl -v --no-progress-meter http://${CLUSTER_ADDRESS}/HelloWorld
    if [[ -n "${USE_OPENSHIFT}" && ${USE_OPENSHIFT} = "true" ]]
    then
      assert_output --partial "302 Found"
    else
      assert_output --partial "308 Permanent Redirect"
    fi
}

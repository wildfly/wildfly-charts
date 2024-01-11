setup() {
    load '../test-common/bats-support/load'
    load '../test-common/bats-assert/load'
}

teardown () {
   helm delete test \
     --wait --timeout=90s
   kubectl delete --ignore-not-found=true secret test-secret-tls
}

@test "Deploy with Ingress (without TLS)" {
       cat <<EOF | helm install test ../../charts/wildfly --wait --timeout=90s -f -
image:
  name: localhost:5001/helloworld
build:
  enabled: false # Disable S2I build
deploy:
  ingress:
    host: wildfly.local
    enabled: true
EOF
    sleep 5

    run curl -v --no-progress-meter http://wildfly.local/HelloWorld
    assert_output --partial  "200 OK"
    assert_output --partial  "Hello World"
}

@test "Deploy with Ingress with TLS" {
    pushd target/
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=wildfly.local"
    kubectl create secret tls test-secret-tls --key="tls.key" --cert="tls.crt"
    popd 

       cat <<EOF | helm install test ../../charts/wildfly --wait --timeout=90s -f -
image:
  name: localhost:5001/helloworld
build:
  enabled: false # Disable S2I build
deploy:
  ingress:
    enabled: true
    host: wildfly.local
    tls: 
      enabled: true
      secret: test-secret-tls
EOF
    sleep 5

    # test with HTTPS
    run curl -v -k --no-progress-meter https://wildfly.local/HelloWorld
    assert_output --partial  "*  subject: CN=wildfly.local"
    assert_output --partial  "Hello World"

    # verify that HTTP is redirected to HTTPS
    run curl -v --no-progress-meter http://wildfly.local/HelloWorld
    assert_output --partial "308 Permanent Redirect"

}

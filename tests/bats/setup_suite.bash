setup_suite() {
    # Udpate the wildfly chart and its dependencies to be able to use it locally
    pushd ../../charts/wildfly
    helm dep up
    popd

    # Create an application image from the helloworld quickstart and push it 
    # to the Kubernetes image registry at localhost:5001/helloworld
    [ -d target ] || mkdir target
    pushd target
    [ -d quickstart ] || git clone https://github.com/wildfly/quickstart.git
    cd quickstart/helloworld
    mvn -B -Popenshift package wildfly:image
    docker tag helloworld localhost:5001/helloworld
    docker push localhost:5001/helloworld
    popd
    echo "DONE"
}

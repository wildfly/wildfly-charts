setup_suite() {
    # Udpate the wildfly chart and its dependencies to be able to use it locally
    if [[ ${PWD##*/} = code ]]
    then
        echo "Don't move" >&3
        pushd charts/wildfly
    else 
        echo "We are in ${PWD##*/}" >&3
        pushd ../../charts/wildfly
    fi
    helm dep up
    popd

    # Create an application image from the helloworld quickstart and push it 
    # to the Kubernetes image registry at localhost:5001/helloworld
    if [ ! -f ../test-common/test.env ]
    then
        touch ../test-common/test.env
        echo  BATS_LIBS_BASEDIR=${BATS_LIBS_BASEDIR} >> ../test-common/test.env
        echo "PUSH_TO_REGISTRY=true" >> ../test-common/test.env
        echo "IMAGE_REGISTRY=${IMAGE_REGISTRY}" >> ../test-common/test.env
        echo "CLUSTER_CLIENT=kubectl" >> ../test-common/test.env
        echo "USE_OPENSHIFT=false" >> ../test-common/test.env
        echo "CLUSTER_ADDRESS=wildfly.local" >> ../test-common/test.env
        echo "${PWD}/../test-common/test.env has been created" >&3
    else 
        echo "${PWD}/../test-common/test.env already exists"
    fi
    if [[ ! -d target ]]
    then 
        mkdir target
    fi
    if [[ -n "${PUSH_TO_REGISTRY}" || ${PUSH_TO_REGISTRY} = "true" ]]
    then
        pushd target
        [ -d quickstart ] || git clone https://github.com/wildfly/quickstart.git
        cd quickstart/helloworld
        mvn -B -Popenshift package wildfly:image
        docker tag helloworld ${IMAGE_REGISTRY}/helloworld
        docker push ${IMAGE_REGISTRY}/helloworld
        echo "docker push of ${IMAGE_REGISTRY}/helloworld was successful" >&3
        popd
    fi
    echo "DONE"
}

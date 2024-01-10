# Helm Chart for WildFly

A Helm chart for building and deploying a [WildFly](https://www.wildfly.org) application on OpenShift.

# Overview

The build and deploy steps are configured in separate `build` and `deploy` values.

The input of the `build` step is a Git repository that contains the application code and the output is an `ImageStreamTag` resource that contains the built application image.

The input of the `deploy` step is an `ImageStreamTag` resource that contains the built application image and the output is a `Deployment` and related resources to access the application from inside and outside OpenShift.

To be able to install a Helm release with that chart, you must be able to provide a valid application image.

# Compatibility with WildFly S2I images

The `2.x` Helm Chart for WildFly relies on the [new source-to-image (S2I) from WildFly](https://github.com/wildfly/wildfly-s2i/) that is available at [quay.io/wildfly/wildfly-s2i-jdk11](https://quay.io/repository/wildfly/wildfly-s2i-jdk11). It is not compatible with the legacy S2I image at [quay.io/wildfly/wildfly-centos7](https://quay.io/repository/wildfly/wildfly-centos7).

You can continue to use the `1.x` Helm Chart for WildFly with the legacy S2I images by specifying a `version` when you install with `helm`. For example, to use the latest `1.x` release of the Helm Chart, you can use:

```
helm install my-legacy-app -f app.yaml wildfly/wildfly --version ^1.x
```

## Build an Application Image from Source

If the application image must be built from source, the minimal configuration is:

```yaml
build:
  uri: <git repository URL of your application>
```

If the source repository is private, you must have a source secret created in the same namespace where you are building the application which allows authenticating to the repository.  Provide the name of the secret in the build section as follows:

```yaml
build:
  sourceSecret: <name of secret to login to your Git repository>
```

The `build` step will use OpenShift `BuildConfig` to build an application image from this Git repository.

The application must be a Maven project that is configured to use the [`org.wildfly.plugins:wildfly-maven-plugin`](https://docs.wildfly.org/wildfly-maven-plugin/) to provision a WildFly server with the deployed application. The application is built during the S2I assembly by running:

```
mvn -e -Popenshift -DskipTests -Dcom.redhat.xpaas.repo.redhatga -Dfabric8.skip=true --batch-mode -Djava.net.preferIPv4Stack=true -s /tmp/artifacts/configuration/settings.xml -Dmaven.repo.local=/tmp/artifacts/m2  package
```

Any additional Maven arguments can be specified by adding the `MAVEN_ARGS_APPEND` environment variable in the `.build.env` field:

```
build:
  env:
    - name: MAVEN_ARGS_APPEND
      value: "-P my-profile"
```


## Pull an existing Application Image

If your application image already exists, you can skip the `build` step and directly deploy your application image.
In that case, the minimal configuration is:

```yaml
image:
  name: <name of the application image. e.g. "quay.io/example.org/my-app">
  tag: <tag of the application image. e.g. "1.3" (defaults to "latest")>
build:
  enabled: false
```

## Working With Private Image Registries

If you are using private image registries to build, push or pull the application image, you need first to create secrets that will allow the container platform where the Helm Chart is deployed to authenticate against the private image registries.

### Pulling the Builder and Runtime Images from a Private Image Registry

This step applies if you build the image on OpenShift and need to pull the builder and runtime base images from an external private image registry.

You must first create a secret that contains the credentials to pull the base image (as explained in the [Kubernetes documentation](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)) and reference it from the `build.pullSecret` field:


```yaml
build:
  pullSecret: my-pull-secret
```

### Pushing the Application Image to a Private Image Registry

This step applies if you build the image with the Helm chart and want to push it to an external image registry.

You must first create a secret that contains the credentials to push the application image (as explained in the [Kubernetes documentation](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)) and reference it from the `build.output.pushSecret` field.
You also need to set the `build.output.kind` field to `DockerImage`.

```yaml
build:
  output:
    kind: DockerImage
    pushSecret: my-push-secret
```

### Pulling the Application Image from a Private Registry

If the application image comes from a private registry that requires authentication, you must first create a secret that contains the credentials to pull the application image (as explained in the [Kubernetes documentation](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)) and reference it from the `deploy.imagePullSecrets` field:

```yaml
image:
  name: quay.io/my-private-group/my-private-image
build:
  enabled: false
deploy:
  imagePullSecrets:
    - name: my-secret-quay-credentials
```

## Application Image

The configuration for the application image that is built and deployed is configured in a `image` section.

| Value | Description | Default | Additional Information |
| ----- | ----------- | ------- | ---------------------- |
| `image.name` | Name of the image you want to build and/or deploy | Defaults to the Helm release name. | The chart will create/reference an `ImageStreamTag` or a `DockerImage` based on this value. |
| `image.tag` | Tag that you want to build/deploy | `latest` | - |

## Building the Application Image

The configuration to build the application image is configured in a `build` section.

If the application image has been built by another mechanism, you can skip the building part of the Helm Chart by setting the `build.enabled` field to `false`.
If you are not deploying on OpenShift then as OpenShift S2I isn't supported then the image can't be built, thus even if `build.enabled` field is set to `true` the building part of the Helm Chart won't be triggered.

| Value | Description | Default | Additional Information |
| ----- | ----------- | ------- | ---------------------- |
| `build.bootableJar.builderImage` | JDK Builder image for Bootable Jar | [registry.access.redhat.com/ubi8/openjdk-17:latest](https://catalog.redhat.com/software/containers/ubi8/openjdk-17/618bdbf34ae3739687568813?container-tabs=gti) | - |
| `build.contextDir` | The sub-directory where the application source code exists | - | - |
| `build.enabled` | Determines if build-related resources should be created. | `true` | Set this to `false` if you want to deploy a previously built image. Leave this set to `true` if you want to build and deploy a new image. |
| `build.env` | Freeform `env` items | - | [Kubernetes documentation](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/). These environment variables will be used when the application is _built_. If you need to specify environment variables for the running application, use `deploy.env` instead. |
| `build.images`| Freeform images injected in the source during S2I build | - | [OKD API documentation](https://docs.okd.io/latest/rest_api/workloads_apis/buildconfig-build-openshift-io-v1.html#spec-source-images-2) |
| `build.mode` | Determines whether the application will be built using WildFly S2I images or Bootable Jar | `s2i` | Allowed values: `s2i` or `bootable-jar` |
| `build.output.kind`|	Determines if the image will be pushed to an `ImageStreamTag` or a `DockerImage` | `ImageStreamTag` | [OKD API documentation](https://docs.okd.io/latest/rest_api/workloads_apis/buildconfig-build-openshift-io-v1.html#spec-output) |
| `build.output.pushSecret` | Name of the push secret | - | The secret must exist in the same namespace or the chart will fail to install - Used only if `build.output.kind` is `DockerImage` |
| `build.pullSecret` | Name of the pull secret | - | The secret must exist in the same namespace or the chart will fail to install - [OKD API documentation](https://docs.okd.io/latest/rest_api/workloads_apis/buildconfig-build-openshift-io-v1.html#spec-strategy-sourcestrategy) |
| `build.ref` | Git ref containing the application you want to build | `main` | - |
| `build.resources` | Freeform `resources` items | - | [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| `build.s2i` | Configuration specific to building with WildFly S2I images | - | - |
| `build.s2i.buildApplicationImage` | Whether the application image is built. If `false` the Helm release will only create the builder image (and name it from the Helm release) | `true` | - |
| `build.s2i.builderImage` | WildFly S2I Builder image | [quay.io/wildfly/wildfly-s2i:latest](https://quay.io/repository/wildfly/wildfly-s2i) | [WildFly S2I documentation](https://github.com/wildfly/wildfly-s2i)  |
| `build.s2i.builderKind` | Determines the type of images for S2I Builder image (`DockerImage`, `ImageStreamTag` or `ImageStreamImage`) | the value of `build.s2i.kind` | [OKD Documentation](https://docs.okd.io/latest/cicd/)|
| `build.s2i.featurePacks` | *Deprecated* List of Galleon feature-packs identified by Maven coordinates (`<groupId>:<artifactId>:<version>`) | - | The value can be be either a `string` with a list of comma-separated Maven coordinate or an array where each item is the Maven coordinate of a feature pack - [WildFly S2I documentation](https://github.com/wildfly/wildfly-s2i) - since WildFly 23.0.2|
| `build.s2i.galleonDir` | *Deprecated* Directory relative to the root directory for the build that contains custom content for Galleon. | - | [WildFly S2I documentation](https://github.com/wildfly/wildfly-s2i) - since WildFly 23.0.2|
| `build.s2i.galleonLayers` | *Deprecated* A list of layer names to compose a WildFly server. If specified, `build.s2i.featurePacks` must also be specified. | - | The value can be be either a `string` with a list of comma-separated layers or an array where each item is a layer - [WildFly S2I documentation](https://github.com/wildfly/wildfly-s2i) |
| `build.s2i.kind` | Determines the type of images for S2I Builder and Runtime images (`DockerImage`, `ImageStreamTag` or `ImageStreamImage`) | `DockerImage` | [OKD Documentation](https://docs.okd.io/latest/cicd/builds/build-strategies.html#builds-strategy-s2i-build_build-strategies) |
| `build.s2i.runtimeImage` | WildFly S2I Runtime image | [quay.io/wildfly/wildfly-runtime:latest](https://quay.io/repository/wildfly/wildfly-runtime) | [WildFly S2I documentation](https://github.com/wildfly/wildfly-s2i) |
| `build.s2i.runtimeKind` | Determines the type of images for S2I Runtime image (`DockerImage`, `ImageStreamTag` or `ImageStreamImage`) | the value of `build.s2i.kind` | [OKD Documentation](https://docs.okd.io/latest/cicd/)|
| `build.sourceSecret`|Name of the secret containing the credentials to login to Git source repository | - | The secret must exist in the same namespace or the chart will fail to install - [OKD documentation](https://docs.okd.io/latest/cicd/builds/creating-build-inputs.html#builds-manually-add-source-clone-secrets_creating-build-inputs) |
| `build.triggers.genericSecret`| Name of the secret containing the WebHookSecretKey for the Generic Webhook | - | The secret must exist in the same namespace or the chart will fail to install - [OKD documentation](https://docs.okd.io/latest/cicd/builds/triggering-builds-build-hooks.html) |
| `build.triggers.githubSecret`| Name of the secret containing the WebHookSecretKey for the GitHub Webhook | - | The secret must exist in the same namespace or the chart will fail to install - [OKD documentation](https://docs.okd.io/latest/cicd/builds/triggering-builds-build-hooks.html) |
| `build.uri` | Git URI that references your git repo | &lt;required&gt; | Be sure to specify this to build the application. |

### Provisioning WildFly With S2I.

The recommended way to provision the WildFly server is to use the `wildfly-maven-plugin` from the application `pom.xml`.

The `build.s2i.featurePacks` and `build.s2i.galleonLayers` fields have been deprecated as they are no longer necessary with this recommendation.
For backwards compatibility, the WildFly S2I Builder image still supports these fields to delegate to the provisioning of the server to the `wildfly-maven-plugin` if it is not configured in the application `pom.xml`.
However if `build.s2i.galleonLayers` is set, `build.s2i.featurePacks` _must_ be specified (including WildFly own feature pack, e.g. `org.wildfly:wildfly-galleon-pack:26.1.1.Final`).

## Deploying the Application Image

The configuration to deploy the application image is configured in a `deploy` section.

If the Helm chart is only used to build the application image, you can skip the deploying part of the Helm Chart by setting the `build.deploy` field to `false`.

| Value | Description | Default | Additional Information |
| ----- | ----------- | ------- | ---------------------- |
| `deploy.annotations` | Map of `string` annotations that are applied to the deployment and its pod's `template` | - | [Kubernetes documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| `deploy.enabled` | Determines if deployment-related resources should be created. | `true` | Set this to `false` if you do not want to deploy an application image built by this chart. |
| `deploy.env` | Freeform `env` items | - | [Kubernetes documentation](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/).  These environment variables will be used when the application is _running_. If you need to specify environment variables when the application is built, use `build.env` instead. |
| `deploy.envFrom` | Freeform `envFrom` items | - | [Kubernetes documentation](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/).  These environment variables will be used when the application is _running_. If you need to specify environment variables when the application is built, use `build.envFrom` instead. |
| `deploy.extraContainers` | Freeform extra `containers` items | - | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/workloads/pods/#pod-templates) |
| `deploy.imagePullSecrets` | Names of secrets to pull the application image from an private image registry | - | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod) |
| `deploy.ingress` | Configuration specific to the creation of a `Ingress` resource to expose the application | - | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/) |
| `deploy.ingress.className` | Configure the `ingressClassName` which is the name of the IngressClass cluster resource. The associated IngressClass defines which controller will implement the resource. If not set the default `ingressClass` defined on the cluster is used.| |[Kubernetes Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#default-ingress-class). |
| `deploy.ingress.enabled` | Determines if a `Ingress` configuration should be created. | `false` | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/) |
| `deploy.ingress.host` | `host` is an alias/DNS that is used as endpoint for inbound traffic. | - | [Kubernete Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#the-ingress-resource) |
| `deploy.ingress.path` | The `path` that an incoming request must match before the load balancer directs traffic to the referenced Service. | - | [Kubernete Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules) |
| `deploy.ingress.pathType` | Each `path` in an Ingress rule is required to have a corresponding `pathType` to define how the path is matched. | Prefix | [Kubernete Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types) |
| `deploy.ingress.tls.secret` | Name of the secret which contains the certificates to use for TLS. | - | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls) |
| `deploy.initContainers` | Freeform `initContainers` items | - | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) |
| `deploy.labels` | Map of `string` labels that are applied to the deployment and its pod's `template` | - | [Kubernetes documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| `deploy.livenessProbe` | Freeform `livenessProbe` field. | HTTP Get on `<ip>:admin/health/live` | [Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| `deploy.readinessProbe` | Freeform `readinessProbe` field. | HTTP Get on `<ip>:admin/health/ready` | [Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| `deploy.replicas` | Number of pod replicas to deploy. | `1` | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#replicas) | 
| `deploy.resources` | Freeform `resources` items | - | [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) |
| `deploy.route` | Configuration specific to the creation of a `Route` resource to expose the application | - | - |
| `deploy.route.enabled` | Determines if a `Route` should be created | `true` | Allows clients outside of OpenShift to access your application |
| `deploy.route.host` | `host` is an alias/DNS that points to the service. Optional. If not specified a route name will typically be automatically chosen | - | [OKD Documentation](https://docs.okd.io/latest/networking/routes/route-configuration.html) |
| `deploy.route.tls.enabled` | Determines if the `Route` should be TLS-encrypted. If `deploy.tls.enabled` is true, the route will use the secure service to access to the deployment | `true`| [OKD Documentation](https://docs.okd.io/latest/networking/routes/route-configuration.html) |
| `deploy.route.tls.insecureEdgeTerminationPolicy` | Determines if insecure traffic should be redirected | `Redirect` | Allowed values: `Allow`, `Disable`, `Redirect` |
| `deploy.route.tls.termination` | Determines the type of TLS termination to use | `edge`| Allowed values: `edge`, `reencrypt`, `passthrough` |
| `deploy.startupProbe` | Freeform `startupProbe` field. | HTTP Get on `<ip>:admin/health/live` | [Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) |
| `deploy.tls.enabled` | Enables the creation of a secure service to access the application. If `true`, WildFly must be configured to enable HTTPS | `false`| - |
| `deploy.volumes` | Freeform `volumes` items| - | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/storage/volumes/) |
| `deploy.volumeMounts` | Freeform `volumeMounts` items| - | [Kubernetes Documentation](https://kubernetes.io/docs/concepts/storage/volumes/) |

NOTE: Configuring a `route` and an `ingress` are exclusive. If both are enabled and you are deploying on Openshift then a `route` will be created. If you are deploying on Kubernetes then an `ingress` will be created.


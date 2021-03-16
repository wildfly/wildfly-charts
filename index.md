
<p align="center">
  <a href="https://helm.sh"><img src="https://helm.sh/img/helm.svg" alt="Helm logo" title="WildFly" height="90"/></a>&nbsp;
  <a href="https://wildfly.org/"><img src="https://design.jboss.org/wildfly/logo/final/wildfly_logo.svg" alt="WildFly logo" title="WildFly" height="90"/></a>
</p>

# Install Helm Repository for WildFly Charts

The `wildfly` Chart can be installed from [http://docs.wildfly.org/wildfly-charts/](http://docs.wildfly.org/wildfly-charts/)

```
$ helm repo add wildfly http://docs.wildfly.org/wildfly-charts/
"wildfly" has been added to your repositories

$ helm search repo wildfly
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
wildfly/wildfly         1.0.0           22.0            A Helm chart to build and deploy WildFly applic...
````

# Install a Helm Release

We can build and deploy the [microprofile-config quickstart](https://github.com/wildfly/quickstart/tree/master/microprofile-config) using Bootable Jar with this [example file](https://raw.githubusercontent.com/wildfly/wildfly-charts/main/examples/microprofile-config/microprofile-config-app.yaml):

```
$ helm install microprofile-config-app \
    -f https://raw.githubusercontent.com/wildfly/wildfly-charts/main/examples/microprofile-config/microprofile-config-app.yaml \
    wildfly/wildfly
NAME: microprofile-config-app
LAST DEPLOYED: Tue Mar  9 11:57:33 2021
NAMESPACE: jmesnil1-dev
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

# Documentation

A complete documentation of the `widlfly` Chart is available in [its README](https://github.com/wildfly/wildfly-charts/blob/main/charts/wildfly/README.md).

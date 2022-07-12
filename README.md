# wildfly-charts - Helm Charts for WildFly

<p align="center">
  <a href="https://helm.sh"><img src="https://helm.sh/img/helm.svg" alt="Helm logo" title="WildFly" height="90"/></a>&nbsp;
  <a href="https://wildfly.org/"><img src="https://design.jboss.org/wildfly/logo/final/wildfly_logo.svg" alt="WildFly logo" title="WildFly" height="90"/></a>
</p>

[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/wildfly)](https://artifacthub.io/packages/helm/wildfly/wildfly)

## Install Helm Repository for WildFly Charts

The `wildfly` Chart can be installed from the [https://docs.wildfly.org/wildfly-charts/](https://docs.wildfly.org/wildfly-charts/) repository

```
$ helm repo add wildfly https://docs.wildfly.org/wildfly-charts/
"wildfly" has been added to your repositories
$ helm search repo wildfly
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
wildfly/wildfly       	2.0.3        	           	    Build and Deploy WildFly applications on OpenShift
````

## WildFly Charts docs

* A complete documentation of the `wildfly` Chart is available in [charts/wildfly/](./charts/wildfly/README.md).
* [Wiki](https://github.com/wildfly/wildfly-charts/wiki)

---
title: "Crossplane: review after 1.5 years"
description: "How is Crossplane handling one and a half year after my `Playing with Crossplane, for real` blog post ?"
date: 2023-12-27T20:05:56.612Z
preview: ""
draft: false
tags: ["devops", "gitops", "kubernetes", "crossplane", "cncf"]
categories: ["devops"]

image: "images/1.png" 
images:
 - "images/1.png"
---
![image](images/1.png#layoutTextWidth)

So, a year and a half ago, I wrote [Playing with Crossplane, for real](https://piratemakers.ca/posts/2022/11/docker.io-opensource-fail-and-what-to-do-instead/) blog post ([link to the Medium original version](https://medium.com/p/f591e66065ae)).

This blog post was relating a real POC I did for my company, where **I* was pushing for using ArgoCD and Crossplane to handle our infrastructure in place of Terraform.

As you can read, the outcome wasn't exactly what I thought.

I got contacted by Crossplane CEO, who shared my blog post to the team and I discussed many of my pain points with Crossplane Developers during the KubeCon North America 2022 (where I was a speaker).  
Upbound, as a company, stand behind its product and was willing to make it work. At the time they shared that they would release more of their internal providers, which would solve most of my problems. 

I wish I had a chance to do the POC once again before that, but.. meh... life, I guess... it's happening now !

So let's dive in, trying to follow the same agenda as the last blog post.

## Install

While I previously only talked about the painpoints, I Installed Corssplane with Argo. One year later, let's chech how I do it now:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-infrastructure-addons-central-cluster
  namespace: argocd
spec:
  destination:
    name: central-cluster
    namespace: argocd-infrastructure-addons
  info:
  - name: Owner
    value: devops
  - name: Team
    value: infrastructure
  - name: Environment
    value: qa
  - name: Description
    value: Project to deploy GKE Addons using ArgoCD
  project: infrastructure
  source:
    path: deployments/k8s/overlays/qa/central-cluster
    repoURL: https://gitlab.net/devops/cicd/argocd-infrastructure-addons.git # fake URL
    targetRevision: deployment
  syncPolicy:
    automated:
      allowEmpty: true
      prune: true
      selfHeal: true
    managedNamespaceMetadata:
      labels:
        wk/managedBy: argocd
        wk/origin: devops_cicd_argocd_infrastructure_addons
    syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jqPathExpressions:
        - .spec.template.spec.containers[].env[].valueFrom.resourceFieldRef.divisor
        - .spec.template.spec.initContainers[].env[].valueFrom.resourceFieldRef.divisor
```

Here, at the end, I had to tell Argo to not track the `divisor` key from the `env` values. The cluster is adding it back with a value on `0` (default should be `1`... not sure what's happening here), while Argo is trying to remove it. The `divisor` value was added in the `init container` but not in the main container in Crossplane Helm chart. Will PR for it...

So this will make ArgoCD scan my git repo and deploy the application.  
The yaml itself is actually a `helm` chart + some other values. Everything is placed into the `deployments/k8s/overlays/qa/central-cluster` folder

The `kustomization.yaml` file will hold all the addons for my cluster, Crossplane being one:

```yaml
# https://kubectl.docs.kubernetes.io/references/kustomize/builtins/#_helmchartinflationgenerator_
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
    # https://github.com/crossplane/crossplane/tree/master/cluster/charts/crossplane
    # TODO to have it working:
    # - enable helm in the argocd-cm ConfigMap by adding to the data: `kustomize.buildOptions: --load-restrictor LoadRestrictionsNone --enable-helm`
    # - Update the projects application to not track some fields:
          # ignoreDifferences:
          #   - group: apps
          #     kind: Deployment
          #     jqPathExpressions:
          #       - .spec.template.spec.containers[].env[].valueFrom.resourceFieldRef.divisor
          #       - .spec.template.spec.initContainers[].env[].valueFrom.resourceFieldRef.divisor
  - name: crossplane
    repo: https://charts.crossplane.io/stable
    releaseName: crossplane
    namespace: crossplane
    # version: 0.1.0 # use latest
    valuesFile: values.yaml
    includeCRDs: false #no CRD in the chart, they are created by crossplane Operator

resources:
  - namespaces.yaml
  - providers.yaml  
```

So this is just `inflating` the helm chart, and apply 2 other resources:
- namespace
  This is needed as ArgoCD will only maintain the namespace for my whole addons project, not specifically for Crossplane. Because I want Crossplane deployed in the `crossplane` repo, I have to add it myself (let me know if you have a better solution).  
  ```yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    annotations:
      argocd.argoproj.io/sync-options: ServerSideApply=true
      argocd.argoproj.io/sync-wave: "0"
    labels:
      kubernetes.io/metadata.name: crossplane
    name: crossplane
  ```
  Note the `sync-wave: "0"` to have that happen first.

- Crossplace Providers
  This is the list of providers I'd like to install.  
  Note that the Crossplane Helm Chart can do it for you, but I'd rather have it explicit here. I'm only installing the `storage` (buckets) and `sql` (mysql/pg) providers for this test.  
  ```yaml
  apiVersion: pkg.crossplane.io/v1
  kind: Provider
  metadata:
    name: provider-gcp-storage
    annotations:
      argocd.argoproj.io/sync-wave: "2"
  spec:
    package: xpkg.upbound.io/upbound/provider-gcp-storage:v0.41.0
  ---
  apiVersion: pkg.crossplane.io/v1
  kind: Provider
  metadata:
    name: provider-gcp-sql
    annotations:
      argocd.argoproj.io/sync-wave: "2"
  spec:
    package: xpkg.upbound.io/upbound/provider-gcp-sql:v0.41.0
  ```

## Providers

In 2023, Upbound announced [a new family of providers](https://blog.upbound.io/new-provider-families) that are smaller and have less impact on the K8s API.

For GCP, this means installing the [provider-family-gcp](https://marketplace.upbound.io/providers/upbound/provider-family-gcp/v0.41.0). This is automatically done by Crossplane when one of the sub-provider is installed. So there's nothing to do after we pushed the `Provider` resources above.

This is one of the key changed in Crossplane, which allow to only run the resources that you need, lowering the cost on the API Server.  
That's one problem solved.

```bash
❯ k get provider
NAME                          INSTALLED   HEALTHY   PACKAGE                                                AGE
provider-gcp-sql              True        True      xpkg.upbound.io/upbound/provider-gcp-sql:v0.41.0       25h
provider-gcp-storage          True        True      xpkg.upbound.io/upbound/provider-gcp-storage:v0.41.0   25h
upbound-provider-family-gcp   True        True      xpkg.upbound.io/upbound/provider-family-gcp:v0.41.0    25h
```

Check the [Provider's Marketplace](https://marketplace.upbound.io/providers/upbound/provider-family-gcp/v0.41.0) for more providers !  
It's 72 sub-providers for GCP, each of which includes few resources. For the [SQL sub-provider](https://marketplace.upbound.io/providers/upbound/provider-gcp-sql/v0.41.0), it's 5 resources:

|Kind                         | Group              | Version|
|:--------------------------:|:------------------:|:------:|
|DatabaseInstance             | sql.gcp.upbound.io | v1beta1|
|Database                     | sql.gcp.upbound.io | v1beta1|
|SourceRepresentationInstance | sql.gcp.upbound.io | v1beta1|
|SSLCert                      | sql.gcp.upbound.io | v1beta1|
|User                         | sql.gcp.upbound.io | v1beta1|


The other problem was on the quality of the providers. We'll dive in later.

## Docs

Everything changed, so did the docs. 

You want https://marketplace.upbound.io/providers/upbound/provider-gcp-sql/v0.41.0/resources/sql.gcp.upbound.io/DatabaseInstance/v1beta1
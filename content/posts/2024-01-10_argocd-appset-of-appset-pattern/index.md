---
title: "ArgoCD Appset-of-Appset Pattern"
author: "Prune"
date: 2024-01-10T14:31:56.257Z
lastmod: 2024-01-10T22:24:45-05:00

description: "Playing with ArgoCD ApplicationSets"

subtitle: "While testing how to add my Kubernetes Cluster's Addons using ArgoCD, which represents all the apps mandatory in all clustets, like crossplane, prometheus (victoriaMetrics), exporters..., I came to test a new pattern: AppSet-Of-AppSet"

image: "images/1.png" 
images:
 - "images/1.png"


tags: ["devops", "argocd", "gitops"]

aliases:
    - "/argocd-appset-of-appset-pattern-1459f962065"

---

![Docker Fail](images/1.png#layoutTextWidth)

We all know the App-of-Apps pattern, where one repo contains many other `ArgoCD Applications`.

While testing how to add my Kubernetes Cluster's Addons using ArgoCD, which represents all the apps mandatory in all clustets, like crossplane, prometheus (victoriaMetrics), exporters..., I came to test a "new" pattern: `AppSet-Of-AppSet`.

This is a quick post going over my experiements. It is **not** a howto, or a suggestion to go this route, it's just a test.

## Directory Structure

```
├── deployments
│   ├── argocd
│   │   └── qa.yaml
│   └── k8s
│       ├── addons
│       │   └── qa
│       │       └── qa-us-central-cluster
│       │           └── crossplane
│       │               └── kustomization.yaml
│       ├── base
│       │   ├── configmaps
│       │   │   ├── cm.yaml
│       │   │   └── kustomization.yaml
│       │   └── crossplane
│       │       ├── kustomization.yaml
│       │       ├── namespaces.yaml
│       │       ├── providers.yaml
│       │       └── values.yaml
│       ├── config.yaml
│       └── overlays
│           └── qa
│               └── qa-us-central-cluster
│                   └── crossplane.yaml
```

## Original AppSet

This is the AppSet scanning all my Git repos (Gitlab in this example) and generating Apps. This is classic, using a `Matrix` to create one app per cluster. It is not linked to deploying my Cluster Addons, it could also deploy any other apps, fron any repo.

In this case it is named `devops` as it will scann all the repos under `/devops` subgroup of my Gitlab Server. It will only track the `deployment` branch and will only pick repod with a `deployments/argocd/qa.yaml` file.  
If will then matrix the selected repos with two `git` generators:
- one `directory` looking for `deployments/k8s/overlays/qa/*` where `*` will be the cluster to target by the Application (`qa-us-central-cluster` from the tree above).
- one `deployments/k8s/config.yaml` file, global to the repo, with some MANDATORY values in it. It is mandatory as the AppsetController WILL NOT pick the repo if the file does not contains certain valued needed by the template.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: devops
  namespace: argocd
spec:
  generators:
  - matrix:
      generators:
      - scmProvider:
          cloneProtocol: https
          filters:
          - branchMatch: ^deployment$
            pathsExist:
            - deployments/argocd/qa.yaml
          gitlab:
            allBranches: true
            api: https://gitlab.mycompany.net/
            group: devops
            includeSubgroups: true
            tokenRef:
              key: token
              secretName: gitlab-token
      - matrix:
          generators:
          - git:
              directories:
              - path: deployments/k8s/overlays/qa/*
              pathParamPrefix: repo
              repoURL: '{{ .url }}'
              requeueAfterSeconds: 60
              revision: '{{ .branch }}'
          - git:
              files:
              - path: deployments/k8s/config.yaml
              pathParamPrefix: config
              repoURL: '{{ .url }}'
              requeueAfterSeconds: 60
              revision: '{{ .branch }}'
  goTemplate: true
  preservedFields:
    annotations:
    - environment
  syncPolicy:
    preserveResourcesOnDeletion: true
  template:
    metadata:
      name: '{{ $name := (printf "%s-%s-%s" .organization .repository .repo.path.basename)
        }}{{ $name | normalize }}'
    spec:
      destination:
        name: '{{ .repo.path.basename }}'
        namespace: '{{ .repository }}'
      info:
      - name: Owner
        value: '{{.metadata.owner}}'
      - name: Team
        value: '{{.metadata.team}}'
      - name: Environment
        value: qa
      - name: Description
        value: '{{.metadata.description}}'
      project: '{{.metadata.team}}'
      source:
        path: deployments/k8s/overlays/qa/{{ .repo.path.basename }}
        repoURL: '{{ .url }}'
        targetRevision: '{{ .branch }}'
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
          selfHeal: true
        managedNamespaceMetadata:
          labels:
            managedBy: argocd
            origin: devops_cicd_argocd
        syncOptions:
        - CreateNamespace=true
        - ServerSideApply=true
```

The `deployments/k8s/config.yaml` must contain something like:

```yaml
metadata:
  owner: "infra"
  team: "infrastructure"
  description: "This is part of the GKE Cluster Addons"
```

And the `team` value must reflect an existing `App Project` that already exist in ArgoCD. In my case:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  annotations:
    meta.helm.sh/release-name: argocd
    meta.helm.sh/release-namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
  name: infrastructure
  namespace: argocd
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  description: projects for Infrastructure Team
  destinations:
  - namespace: '*'
    server: '*'
  roles:
  - description: Project Admin privileges to infrastructure project
    groups:
    - infrastructure@company.com
    name: project-admin-infrastructure
    policies:
    - p, proj:infrastructure:project-admin, applicationsets, get, infrastructure/*,
      allow
    - p, proj:infrastructure:project-admin, applications, get, infrastructure/*, allow
    - p, proj:infrastructure:project-admin, applications, sync, infrastructure/*,
      allow
    - p, proj:infrastructure:project-admin, clusters, get, infrastructure/*, allow
    - p, proj:infrastructure:project-admin, repositories, get, infrastructure/*, allow
    - p, proj:infrastructure:project-admin, projects, get, infrastructure/*, allow
    - p, proj:infrastructure:project-admin, logs, get, infrastructure/*, allow
  sourceRepos:
  - '*'
```


Once deployed, a new `Application` will be created, and will deploy the content of the `deployments/overlays/qa/qa-us-central-cluster`, in our case, the `crossplane.yaml` file.

## The Appset of Appset

The `crossplane.yaml` file contains another `ApplicationSet` that will be deployed, and generate new apps for each of the addons.

This Appset contains static values, because it is tied to this specific repo. This sounds a little dumb, but we'll discuss that at the end :)

So this time the cluster is a static list that I can manage for my addons. For example, this AppSet will only target the current repo, so we "hardcode" the URL...

Also, because this AppSet should only be deployed in the ArgoCD clusters, and not all of the clusters of your platform, we also grab the cluster names from the file's path.  
So the Git Generator is looking for `deployments/k8s/addons/qa/*/crossplane` so we explicitelly discover two folders:
- the name of the cluster
- the name of the Addon (crossplane)

The template also set a `ignoreDifferences` which is specific to Crossplane (as of today but PRed a change that was merged in the Helm Chart). This is the main reason I went to test this Appset-of-Appset pattern in the first place: Have each addons be configured with different values.

In theory, this Appset should only be used for Crossplane deployment. Let's say we want to deploy `VictoriaMetrics`, then we would have another Appset `victoriametrics.yaml` with hardcoded values for it. The Appset here is only used to auto-generate apps per cluster.



```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  annotations:
  labels:
  name: addon-crossplane
  namespace: argocd
spec:
  generators:
  - matrix:
      generators:
      - list:
          elements:
          - url: https://gitlab.mycompany.net/devops/argocd-infrastructure-addons.git
            branch: deployment
            env: qa
            namespace: argocd
      - matrix:
          generators:
          - git:
              directories:
              - path: deployments/k8s/addons/qa/*/crossplane
              pathParamPrefix: repo
              repoURL: '{{ .url }}'
              requeueAfterSeconds: 60
              revision: '{{ .branch }}'
          - git:
              files:
              - path: deployments/k8s/config.yaml
              pathParamPrefix: config
              repoURL: '{{ .url }}'
              requeueAfterSeconds: 60
              revision: '{{ .branch }}'
  goTemplate: true
  preservedFields:
    annotations:
    - environment
  syncPolicy:
    preserveResourcesOnDeletion: true
  template:
    metadata:
      name: '{{ $name := (printf "addons-%s-%s-%s" .repo.path.basename .env (index .repo.path.segments 4))}}{{ $name | normalize }}'
    spec:
      destination:
        name: '{{ index .repo.path.segments 4 }}'
        namespace: '{{ .repo.path.basename }}'
      ignoreDifferences:
      - group: apps
        kind: Deployment
        jqPathExpressions:
        - .spec.template.spec.containers[].env[].valueFrom.resourceFieldRef.divisor
        - .spec.template.spec.initContainers[].env[].valueFrom.resourceFieldRef.divisor
      info:
      - name: Owner
        value: '{{.metadata.owner}}'
      - name: Team
        value: '{{.metadata.team}}'
      - name: Environment
        value: qa
      - name: Description
        value: '{{.metadata.description}}'
      - name: val4
        value: '{{ index .repo.path.segments 4 }}'
      - name: val5
        value: '{{ index .repo.path.segments 5 }}'
      project: '{{.metadata.team}}'
      source:
        path: deployments/k8s/addons/{{ .env }}/{{ index .repo.path.segments 4 }}/{{ .repo.path.basename }}
        repoURL: '{{ .url }}'
        targetRevision: '{{ .branch }}'
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
          selfHeal: true
        managedNamespaceMetadata:
          labels:
            wk/managedBy: argocd
            wk/origin: devops_cicd_argocd
        syncOptions:
        - CreateNamespace=true
        - ServerSideApply=true
```

## The Crossplane Kustomization

The previous AppSet will, in turn, create an application that will deploy the content of `deployments/k8s/addons/qa/qa-us-central-cluster/crossplane/kustomization.yaml`.  
This file contains something like:

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../../../base/crossplane
```

And just as a hint, here's how I inflates the Crossplane Helm chart:

```yaml
# kustomization.yaml from https://medium.com/@tharukam/generate-kubernetes-manifests-with-helm-charts-using-kustomize-2f82ab5c5f11
# https://kubectl.docs.kubernetes.io/references/kustomize/builtins/#_helmchartinflationgenerator_
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
    # https://github.com/crossplane/crossplane/tree/master/cluster/charts/crossplane
    # TODO to have it working:
    # - enable helm in the argocd-cm ConfigMap by adding to the data: `kustomize.buildOptions: --load-restrictor LoadRestrictionsNone --enable-helm`
    # - enable some resources to be tracked by ArgoCD: "Service" and "pkg.crossplane.io/*"
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

Providers:
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

Namespace:

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

## Conclusion

Is it worth it ?

Yes and No... 

Yes as a testing solution, and a way to further customize your Apps while still automating your setup.

No, as it is overly complicated and needs hardcoded values. 

Of course, this is a specific case of Infrastructure buildup, not a pattern to give to Developers.  
While I tested this solution to go around an issue with the specific case of the Crossplane Helm Chart needing to ignore some part of the generated yaml, there's a new feature in the (upcoming) ArgoCD 2.10: [ApplicationSet Template Patch](https://blog.argoproj.io/argo-cd-v2-10-release-candidate-f69ba7bf9e06#0504) !  
And if you read down to `Argo CD Server-Side Diff`, there's also a new diff algorythm that should prevent the issue with the Crossplane Helm Chart, without doing anything... 

My conclusion: AppSet-of-AppSet works and could be used in some strange situations.
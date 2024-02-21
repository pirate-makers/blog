---
title: "Crossplane: review after 1.5 years"
description: "How is Crossplane handling one and a half year after my `Playing with Crossplane, for real` blog post ?"
date: 2024-02-20T20:05:56.612Z
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

This blog post was relating a real POC I did for my company, where **I** was pushing for using ArgoCD and Crossplane to handle our infrastructure in place of Terraform.

As you may have read, the outcome wasn't exactly what I thought.

I got contacted by Crossplane CEO, who shared my blog post to the Upbound team. I had the chance to discussed many of my pain points with Crossplane Developers during the KubeCon North America 2022 (where I was a speaker, check out the [blog](https://cloud-native-canada.github.io/k8s_setup_tools/) and [video](https://www.youtube.com/watch?v=TKYAEjNg4Hw)).
Upbound, as a company, stand behind its product and was willing to make it work. At that time they shared that they would release more of their internal providers soon, which would solve most of my problems. 

I wish I had a chance to do the POC once again before that, but.. meh... life, I guess... it's happening now !

So let's dive in, trying to follow the same agenda as the last blog post.

## Install

While I previously only talked about the painpoints, I Installed Corssplane with Argo. One year later, let's chech how I do it now.

This is just a demo app, as in reality I use an [ArgoCD ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/) to generate apps based on gitlab repos, folder structure and content of some files.

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
    package: xpkg.upbound.io/upbound/provider-gcp-storage:v0.41.1
  ---
  apiVersion: pkg.crossplane.io/v1
  kind: Provider
  metadata:
    name: provider-gcp-sql
    annotations:
      argocd.argoproj.io/sync-wave: "2"
  spec:
    package: xpkg.upbound.io/upbound/provider-gcp-sql:v0.41.1
  ---
  apiVersion: pkg.crossplane.io/v1
  kind: Provider
  metadata:
    name: provider-gcp-cloudplatform
    annotations:
      argocd.argoproj.io/sync-wave: "2"
  spec:
    package: xpkg.upbound.io/upbound/provider-gcp-cloudplatform:v0.41.1
  ```

## Providers Management

In 2023, Upbound announced [a new family of providers](https://blog.upbound.io/new-provider-families) that are smaller and have less impact on the K8s API.

For GCP, this means installing the [provider-family-gcp](https://marketplace.upbound.io/providers/upbound/provider-family-gcp/v0.41.0). This is automatically done by Crossplane when one of the sub-provider is installed. So there's nothing to do after we pushed the `Provider` resources above.

This is one of the key changed in Crossplane, which allow to only run the resources that you need, lowering the cost on the API Server.
That's one problem solved.

```bash
❯ k get provider
NAME                          INSTALLED   HEALTHY   PACKAGE                                                     AGE
provider-gcp-cloudplatform    True        True      xpkg.upbound.io/upbound/provider-gcp-cloudplatform:v0.41.1  25h
provider-gcp-sql              True        True      xpkg.upbound.io/upbound/provider-gcp-sql:v0.41.1            25h
provider-gcp-storage          True        True      xpkg.upbound.io/upbound/provider-gcp-storage:v0.41.1        25h
upbound-provider-family-gcp   True        True      xpkg.upbound.io/upbound/provider-family-gcp:v0.41.1         25h
```

Check the [Provider's Marketplace](https://marketplace.upbound.io/providers/upbound/provider-family-gcp/v0.41.1) for more providers !
It's 72 sub-providers for GCP, each of which includes few resources. For the [SQL sub-provider](https://marketplace.upbound.io/providers/upbound/provider-gcp-sql/v0.41.1), it's 5 resources:

|Kind                         | Group              | Version|
|:--------------------------:|:------------------:|:------:|
|DatabaseInstance             | sql.gcp.upbound.io | v1beta1|
|Database                     | sql.gcp.upbound.io | v1beta1|
|SourceRepresentationInstance | sql.gcp.upbound.io | v1beta1|
|SSLCert                      | sql.gcp.upbound.io | v1beta1|
|User                         | sql.gcp.upbound.io | v1beta1|

Once deployed, you can also check the revisions that you installed (Crossplane keeps 2 revisions max as defaut):

```
kubectl get providerrevisions
NAME                                       HEALTHY   REVISION   IMAGE                                                        STATE      DEP-FOUND   DEP-INSTALLED   AGE
provider-gcp-cloudplatform-ce19993b3d91    True      1          xpkg.upbound.io/upbound/provider-gcp-cloudplatform:v0.41.1   Active     1           1               25s
provider-gcp-sql-58782c4213f5              True      2          xpkg.upbound.io/upbound/provider-gcp-sql:v0.41.1             Active     1           1               16h
provider-gcp-sql-ac45452bc4d2              True      1          xpkg.upbound.io/upbound/provider-gcp-sql:v0.41.0             Inactive   1           1               39d
provider-gcp-storage-23793d298dec          True      2          xpkg.upbound.io/upbound/provider-gcp-storage:v0.41.1         Active     1           1               16h
provider-gcp-storage-70a994bdf770          True      1          xpkg.upbound.io/upbound/provider-gcp-storage:v0.41.0         Inactive   1           1               39d
upbound-provider-family-gcp-d0f27e03505b   True      1          xpkg.upbound.io/upbound/provider-family-gcp:v0.41.0          Active                                 39d
```

The other problem was on the quality of the providers. We'll dive into it later.

## Docs

Everything changed, so did the docs.

The provider's docs changed a lot, but is it for the better ? 

At the time of this blog, Crossplane v1.15 is the latest so we'll use it. [https://docs.crossplane.io/latest/](https://docs.crossplane.io/latest/) is the way to go.

Provider GCP, which is linked from the docs, is on the Upbound Marketplace and contains 347 resources. It can be reached at https://marketplace.upbound.io/providers/upbound/provider-gcp/v0.41.1/docs/quickstart. 

![image](images/upbound_provider-gcp_v0_41_1.png#layoutTextWidth)

But you have a warning:

```
⚠️ Warning: The monolithic GCP provider (upbound/provider-gcp) has been deprecated in favor of the GCP provider family. 

You can read more about the provider families in our blog post and the official documentation for the provider families is here.  
We will continue support for the monolithic GCP provider until June 12, 2024. And you can find more information on migrating from the monolithic providers to the provider families here.
```

Ah...

Let's check the provider family at [https://marketplace.upbound.io/providers/upbound/provider-family-gcp/v0.41.1](https://marketplace.upbound.io/providers/upbound/provider-family-gcp/v0.41.1)

![image](images/upbound_provider-family-gcp_v0_41_1.png#layoutTextWidth)

No more `Managed Resources`... only `Providers`.  That's the trick, GCP resources are now groupped in smaller `Providers` so you can deploy only what you need.

The `ServiceAccount` Resource is now defined in the [provider-gcp-cloudplatform](https://marketplace.upbound.io/providers/upbound/provider-gcp-cloudplatform/v0.41.1/resources/cloudplatform.gcp.upbound.io/ServiceAccount/v1beta1) Provider.

I've been searching for it for some time... so the trick is to [use the search bar from the provider family](https://marketplace.upbound.io/providers/upbound/provider-family-gcp/v0.41.1/providers?).

The docs are pretty useful here, at least for a resource as simple as a SericeAccount, and better describe the option:

![image](images/ServiceAccount_-_upbound_provider-gcp-cloudplatform_v0_41_1.png#layoutTextWidth)

There's also 3 examples:

```yaml
apiVersion: cloudplatform.gcp.upbound.io/v1beta1
kind: ServiceAccount
metadata:
  annotations:
    meta.upbound.io/example-id: cloudplatform/v1beta1/serviceaccountiammember
  labels:
    testing.upbound.io/example-name: service-account-iam-member
  name: service-account-iam-member
spec:
  forProvider:
    displayName: Upbound Example Service Account
```

Crossplane docs also seems better to me, for now. Take for example the [InitProvider section](https://docs.crossplane.io/latest/concepts/managed-resources/#initprovider). It's simple and easy to understand.

### Workload Identity

What I tried next, was to use GCP `Workload Identity` for the Providers. This is a way for the providers to gain permissions from a GCP ServiceAccount, bound to the K8s ServiceAccount used by the Provider.

By default, each Provider use a specific K8s ServiceAccount:

```shell
k get sa

NAME                                       SECRETS   AGE
crossplane                                 0         39d
default                                    0         39d
provider-gcp-sql-58782c4213f5              0         16h
provider-gcp-sql-ac45452bc4d2              0         39d
provider-gcp-storage-23793d298dec          0         16h
provider-gcp-storage-70a994bdf770          0         39d
rbac-manager                               0         39d
upbound-provider-family-gcp-d0f27e03505b   0         39d
```

Here, `crossplane` KSA is the one I created for `crossplane` itself. I first thought that this KSA was used to call the GCP API. This is not the case.

We then see multiple `provider-gcp-<provider>-<id>` KSA. Those are created along the Provider install, and a new KSA is created each time you deploy a new version of the Provider. This does not seem good for Workload Identity: because WI needs to bind a Google SA to a K8s SA, we need a stable naming.

I googled for the docs and first came to [Upbound official docs](https://docs.upbound.io/providers/provider-gcp/authentication/#create-a-controllerconfig) which say to use a `ControllerConfig` to change the Providers settings:

```yaml
apiVersion: pkg.crossplane.io/v1alpha1
kind: ControllerConfig
metadata:
  name: my-controller-config
  annotations:
    iam.gke.io/gcp-service-account:
spec:
  serviceAccountName: my-KSA-name
```

But searching for more docs on `ControllerConfig` I then found the [OSS Crossplane docs](https://docs.crossplane.io/latest/concepts/providers/#controller-configuration) with once again, contradictory statement:

![image](images/Providers_controllerconfig_Crossplane_v1_15.png#layoutTextWidth)

So wee need to use a [DeploymentRuntimeConfigs](https://docs.crossplane.io/latest/concepts/providers/#runtime-configuration) !

Which also includes a warning:

```text
Important

DeploymentRuntimeConfigs is a beta feature.
```

Well, I guess we'll have to pick one of Deprecated or Beta... :)

### Conclusion

Overal conclusion is that doc is better, but the path from discovering Crossplane and going to Prod is still not straight.

So, how well did it went ? Let's keep diving in.

## Creating some Resources

### Workload Identity (2)

So, what I finally did was using a `DeploymentRuntimeConfigs` to force the provider's `ServiceAccount` to be `crossplane`, the one KSA that is bound to the GSA with the right permissions. It's like this:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata:
  name: enable-workload-identity
spec:
  deploymentTemplate:
    spec:
      selector: {}
      template:
        spec:
          serviceAccountName: crossplane
          containers: []
```

Then I updated all the providers to use this `DeploymentRuntimeConfig`:

```yaml
  apiVersion: pkg.crossplane.io/v1
  kind: Provider
  metadata:
    name: provider-gcp-cloudplatform
    annotations:
      argocd.argoproj.io/sync-wave: "2"
  spec:
    package: xpkg.upbound.io/upbound/provider-gcp-cloudplatform:v0.41.1
    runtimeConfigRef:
      name: enable-workload-identity
```

I now have:
- the `crossplane` KSA that I want to use
- the `provider-gcp-cloudplatform-1234567` KSA created by the provider
- the `provider-gcp-cloudplatform-9876543` KSA created by the previous version of the provider

But at least, my provider is using the `crossplane` KSA !!

### Add a Google Service Account

So I went ahead to create a new Google Service Account:

```yaml
apiVersion: cloudplatform.gcp.upbound.io/v1beta1
kind: ServiceAccount
metadata:
  annotations:
    meta.upbound.io/example-id: cloudplatform/v1beta1/serviceaccountiammember
  labels:
    testing.upbound.io/example-name: service-account-iam-member
  name: demo-project-service-account
spec:
  forProvider:
    displayName: GSA created from Corssplane
    description: this is a GSA created from Corssplane from the kustomized version of the argocd-demo-project
```

and I watched the logs of the provider, expecting it to create my GSA, of give an error:

```text
[controller-runtime] log.SetLogger(...) was never called; logs will not be displayed.
Detected at:
	>  goroutine 2153 [running]:
	>  runtime/debug.Stack()
	>  	runtime/debug/stack.go:24 +0x5e
	>  sigs.k8s.io/controller-runtime/pkg/log.eventuallyFulfillRoot()
	>  	sigs.k8s.io/controller-runtime@v0.16.3/pkg/log/log.go:60 +0xcd
	>  sigs.k8s.io/controller-runtime/pkg/log.(*delegatingLogSink).WithValues(0xc0006af980, {0xc001a06440, 0x4, 0x4})
	>  	sigs.k8s.io/controller-runtime@v0.16.3/pkg/log/deleg.go:168 +0x49
	>  github.com/go-logr/logr.Logger.WithValues(...)
	>  	github.com/go-logr/logr@v1.3.0/logr.go:336
	>  sigs.k8s.io/controller-runtime/pkg/builder.(*Builder).doController.func1(0xc00080c1a0)
	>  	sigs.k8s.io/controller-runtime@v0.16.3/pkg/builder/controller.go:402 +0x2ba
	>  sigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).reconcileHandler(0xc00065e640, {0x6857c88, 0xc000b1a870}, {0x54abde0?, 0xc00080c180?})
	>  	sigs.k8s.io/controller-runtime@v0.16.3/pkg/internal/controller/controller.go:306 +0x16a
	>  sigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).processNextWorkItem(0xc00065e640, {0x6857c88, 0xc000b1a870})
	>  	sigs.k8s.io/controller-runtime@v0.16.3/pkg/internal/controller/controller.go:266 +0x1c9
	>  sigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).Start.func2.2()
	>  	sigs.k8s.io/controller-runtime@v0.16.3/pkg/internal/controller/controller.go:227 +0x79
	>  created by sigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller).Start.func2 in goroutine 1087
	>  	sigs.k8s.io/controller-runtime@v0.16.3/pkg/internal/controller/controller.go:223 +0x565
```

It seems to be a Go stack-trace telling me that there's not going to be any logs generated... whaaaaaat ?

But we're OK, [we have the docs](https://docs.crossplane.io/knowledge-base/guides/troubleshoot/#provider-logs) !!

![image](images/Troubleshoot_Logs_Crossplane.png#layoutTextWidth)

WHAAAT ? I thought the `ControllerConfig` was deprecated ? 

Let's update our `DeploymentRuntimeConfig` to add debug logs... that should do it:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata:
  name: enable-workload-identity
spec:
  deploymentTemplate:
    spec:
      selector: {}
      template:
        spec:
          serviceAccountName: crossplane
          containers:
            - name: package-runtime
              args:
                - --debug
  serviceAccountTemplate: {}
```

OK, now we're good. What's in the logs ? 

```text
2024-02-21T15:40:40Z	DEBUG	events	cannot initialize the no-fork async external client: cannot get terraform setup: cannot get referenced ProviderConfig: ProviderConfig.gcp.upbound.io "default" not found
```

Interresting that Terraform is still here... but whatever... 

When you create a `Resource` to be managed by a `Provider`, you need to tell the provider which `Identity` or `Credentials` to use.

For this simple test, I was expecting using Workload Identity. So I need to attach my `ServiceAccount Resource` to a `ProviderConfig`.
You will get this informations [from the Upbound docs](https://docs.upbound.io/providers/provider-gcp/authentication/#create-a-providerconfig-2) (not sure it exist in the OSS Crossplane docs)

```yaml
apiVersion: gcp.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: workload-identity
spec:
  credentials:
    source: InjectedIdentity
  projectID: <my-GCP-project>
---
apiVersion: cloudplatform.gcp.upbound.io/v1beta1
kind: ServiceAccount
metadata:
  annotations:
    meta.upbound.io/example-id: cloudplatform/v1beta1/serviceaccountiammember
  labels:
    testing.upbound.io/example-name: service-account-iam-member
  name: demo-project-service-account
spec:
  forProvider:
    displayName: GSA created from Corssplane
    description: this is a GSA created from Corssplane from the kustomized version of the argocd-demo-project
  providerConfigRef:
    name: workload-identity
```

And finally, after a Reconcile loop:

```
[INFO] Authenticating using DefaultClient...
[INFO]   -- Scopes: [https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/userinfo.email]
[DEBUG] Waiting for state to become: [success]
[INFO] Terraform is using this identity: crossplane@<my-GCP-project>.iam.gserviceaccount.com
DEBUG	provider-gcp	Observing the external resource	{"uid": "f13fe9c3-92c7-4b48-b7ca-ed41196d0165", "name": "demo-project-service-account", "gvk": "cloudplatform.gcp.upbound.io/v1beta1, Kind=ServiceAccount"}
[INFO] Instantiating Google Cloud IAM client for path https://iam.googleapis.com/
[DEBUG] Retry Transport: starting RoundTrip retry loop
[DEBUG] Retry Transport: request attempt 0
[DEBUG] Retry Transport: Stopping retries, last request was successful
```

**The last request was successful !!!!**

If you follow the Upbound docs, the next section is [Service account impersonation](https://docs.upbound.io/providers/provider-gcp/authentication/#service-account-impersonation) which is way more secure, as each Application (deployed in its own namespace) could use a different Google Service Account.

This way, your Infrastructure team could pre-create GSA for each of your apps (or deveopper groups) and assign them to many `ProviderConfig`. You could then create abstrations for each of the namespaces, so the App deploying in namespace A could only create a single kind of resource in a specifig Google project... Sounds complicated ? It is, but it's more secure in the end.

Let's move to the final step: reproduce the same Composition that I used in the previous blog post

## Working with Composition, XRD and Claims

Last time I tried to create a Composite Resource that was creating a full usable Postgres SQL database.  As last time, thins involves creating multiple resources, like the `DatabseInstance`, the `Database`, and a `User`.

We'll use the `provider-gcp-sql` for that. So far, it all seems to be the same process.

### Composition

Going [back to the docs](https://docs.crossplane.io/latest/concepts/compositions/), it seems to start with the `Composition` so this time we'll do the same.

Compositions had small changes since the last blog post. Here's the new version:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: jetpostgresql.gcp.database.wk
  labels:
    provider: gcp
    crossplane.io/xrd: xjetpostgresql.database.wk
spec:
  # should I set this here ? Please help
  # writeConnectionSecretsToNamespace: crossplane
  compositeTypeRef:
    apiVersion: database.wk/v1alpha1
    kind: XJetPostgreSQL
  resources:
    - name: cloudsqlinstance
      base:
        apiVersion: sql.gcp.upbound.io/v1beta1
        kind: DatabaseInstance
        metadata:
          annotations: 
            crossplane.io/external-name: "crossplanesqlinstance"
          labels:
            composition.upbound.io/name: crossplanesqlinstance
        spec:
          providerConfigRef:
            name: workload-identity
          deletionPolicy: Delete
          forProvider:
            databaseVersion: POSTGRES_14
            region: us-central1
            deletionProtection: false
            settings:
            - tier: db-f1-micro
              diskType: PD_SSD
              diskSize: 20
              ipConfiguration:
                - ipv4Enabled: true
                  authorizedNetworks:
                    - value: "0.0.0.0/0"
              databaseFlags:
                - name: cloudsql.iam_authentication
                  value: "on"
            userLabels:
              creator: crossplane
              owner: prune
          writeConnectionSecretToRef:
            namespace: crossplane
            name: cloudsqlinstance
      patches:
        # set diskSize based on the Claim
        - type: FromCompositeFieldPath
          fromFieldPath: "spec.parameters.storageGB"
          toFieldPath: "spec.forProvider.settings[0].diskSize"
        # set the secret name to the claim name
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-name]"
          toFieldPath: "spec.writeConnectionSecretToRef.name"
          transforms:
            - type: string
              string:
                type: Format
                fmt: "%s-pginstance"
        # change secret namespace to the one of the claim
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-namespace]"
          toFieldPath: "spec.writeConnectionSecretToRef.namespace"
        # set label app = name of the original claim
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-name]"
          toFieldPath: "metadata.labels[crossplane.io/app]"
        # set the name of the external resource to be the name of the claim
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-name]"
          toFieldPath: "metadata.annotations[crossplane.io/external-name]"
        # set instance size to the one defined in the claim
        - type: FromCompositeFieldPath
          fromFieldPath: "spec.parameters.instanceSize"
          toFieldPath: "spec.forProvider.settings[0].tier"
          transforms:
            - type: map
              map:
                small: db-custom-1-3840
                medium: db-custom-2-7680
                large: db-custom-4-15360
          policy:
            fromFieldPath: Required
    - name: cloudsqldb
      base:
        apiVersion: sql.gcp.upbound.io/v1beta1
        kind: Database
        metadata:
          annotations: 
            crossplane.io/external-name: "crossplanesqldb"
        spec:
          providerConfigRef:
            name: workload-identity
          deletionPolicy: Delete
          forProvider:
            instanceSelector:
              MatchControllerRef: true
              matchLabels:
                composition.upbound.io/name: crossplanesqlinstance
          writeConnectionSecretToRef:
            namespace: crossplane
            name: cloudsqldb
      patches:
        # set the secret name to the claim name
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-name]"
          toFieldPath: "spec.writeConnectionSecretToRef.name"
          transforms:
            - type: string
              string:
                type: Format
                fmt: "%s-pgdb"
        # change secret namespace to the one of the claim
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-namespace]"
          toFieldPath: "spec.writeConnectionSecretToRef.namespace"
        # set the name of the DB resource to be the name defined in the claim
        - type: FromCompositeFieldPath
          fromFieldPath: "spec.parameters.dbName"
          toFieldPath: "metadata.annotations[crossplane.io/external-name]"
        # set app Label
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-name]"
          toFieldPath: "metadata.labels[crossplane.io/app]"
    - name: cloudsqldbuser
      base:
        apiVersion: sql.gcp.upbound.io/v1beta1
        kind: User
        metadata:
          annotations: 
            # set the name of the DB User, this is hardcoded for demo but should come from the CRD
            # Cloud IAM service account should be created without ".gserviceaccount.com" suffix
            crossplane.io/external-name: "demo-project-service-account@my-GCP-project.iam"
        spec:
          providerConfigRef:
            name: workload-identity
          deletionPolicy: Delete
          forProvider:
            instanceSelector:
              MatchControllerRef: true
              matchLabels:
                composition.upbound.io/name: crossplanesqlinstance
            type: CLOUD_IAM_SERVICE_ACCOUNT
          writeConnectionSecretToRef:
            namespace: crossplane
            name: cloudsqluser
      patches:
        # set the secret name to the claim name
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-name]"
          toFieldPath: "spec.writeConnectionSecretToRef.name"
          transforms:
            - type: string
              string:
                type: Format
                fmt: "%s-pguser"
        # change secret namespace to the one of the claim
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-namespace]"
          toFieldPath: "spec.writeConnectionSecretToRef.namespace"
        # set the name of the DB User, this is hardcoded for demo but should come from the Claim CRD
        # - fromFieldPath: "spec.parameters.dbName"
        #   toFieldPath: "metadata.annotations[crossplane.io/external-name]"
        # set app Label
        - type: FromCompositeFieldPath
          fromFieldPath: "metadata.labels[crossplane.io/claim-name]"
          toFieldPath: "metadata.labels[crossplane.io/app]"
```
In short, beside the `Provider` changes, the `patch` also slightly changed, with a `type: FromCompositeFieldPath`. All that is well documented.

I then applied this Composition, which gave me a warning:

```shell
k apply -f Composition.yaml
Warning: CustomResourceDefinition.apiextensions.k8s.io "XJetPostgreSQL.database.wk" not found
composition.apiextensions.crossplane.io/jetpostgresql.gcp.database.wk created
```

I guess I should have started with the XRD :)

### Composite Resource Definition (XRD)

It seems nothing changed here...

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xjetpostgresqls.database.wk
spec:
  group: database.wk
  names:
    kind: XJetPostgreSQL
    plural: xjetpostgresqls
  claimNames:
    kind: JetPostgreSQL
    plural: jetpostgresqls
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              parameters:
                type: object
                properties:
                  storageGB:
                    type: integer
                    description: size of the Database in GB - integer
                  dbName:
                    type: string
                    description: name of the new DB inside the DB instance - string
                  instanceSize:
                    type: string
                    description: instance size - string
                    enum:
                      - small
                      - medium
                      - large
                required:
                  - storageGB
                  - dbName
                  - instanceSize
            required:
              - parameters
```

### Claims

Last part is a `Claim` and again noting changed here:

```yaml
apiVersion: database.wk/v1alpha1
kind: JetPostgreSQL
metadata:
  # namespace: test-namespace
  name: jet-db-claim
spec:
  parameters:
    storageGB: 20
    dbName: xrdb
    instanceSize: small # small, medium, large
  writeConnectionSecretToRef:
    name: jet-db-claim-details
```

## Conclusion

I know this blog post is not a full fledged Crossplane test. I also did not iterate on my previous issues, like `what if I want a Composition to create 2 users or 2 DBs on the same instance ?`.

Let's say i'm keeping all that for the next blog post :)

All in all, it feels that the `Jet` Providers (generated out of Terraform Providers) are now organized and supported by Upbound.

The documentation has been improved, even if there's still room to improve. For example, when you search for a Provider and check the examples associated with it, there's usually some fields, like `labels` or `annotations` with some strange values. While not a problem, I'm always wondering `what am I missing here ?`.

My conclusion for today is that Crossplane matured and may now be production ready. But in the meantime, we started using the [Google Modules for Terraform](https://github.com/terraform-google-modules), which are some kind of `Compositions` for Terraform.

It's still complicated, but ease the pain for Developpers that don't know (and don't want to know) what needs to be created in the background to get a database.

I guess it's now time for the Corssplane Community to start sharing their `Compositions` (or Configurations) on the [Upbound Marketplace](https://marketplace.upbound.io/configurations)

Stay tuned for more "production style" use of Crossplane !
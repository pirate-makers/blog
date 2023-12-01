---
title: "Playing with Dasel"
author: "Prune"
date: 2022-06-30T15:19:54.609Z
lastmod: 2023-11-30T22:23:50-05:00

description: ""

subtitle: "Lately I worked on deprecated and deleted APIS from Kubernetes cluster for migration from version 1.20 and 1.21 to 1.22 (or 1.23)."



tags: ["devops", "json"]
aliases:
    - "/playing-with-dasel-a601398b3900"

---

Lately I worked on deprecated and deleted APIS from Kubernetes cluster for migration from version 1.20 and 1.21 to 1.22 (or 1.23).

To do so, I used the famous [KubePug](https://github.com/rikatz/kubepug) tool, specifically the Krew plugin.

As I have a bunch of clusters I used some dirty `for loops` , but here’s the global KubePug usage:

```bash
kubectl deprecations --k8s-version=v1.23.0 --format json --context ${my_cluster_name} | jq '.' > kubepug_output.json
```

The output file, PrettyPrinted, look something like:
``` json
{  
  "DeprecatedAPIs": [  
    {  
      "Description": "ComponentStatus (and ComponentStatusList) holds the cluster validation info. Deprecated: This API is deprecated in v1.19+",  
      "Group": "",  
      "Kind": "ComponentStatus",  
      "Version": "v1",  
      "Name": "",  
      "Deprecated": true,  
      "Items": [  
        {  
          "Scope": "GLOBAL",  
          "ObjectName": "scheduler",  
          "Namespace": ""  
        }  
      ]  
    },  
    {  
      "Description": "PodSecurityPolicy governs the ability to make requests that affect the Security Context that will be applied to a pod and container. Deprecated in 1.21.",  
      "Group": "policy",  
      "Kind": "PodSecurityPolicy",  
      "Version": "v1beta1",  
      "Name": "",  
      "Deprecated": true,  
      "Items": [  
        {  
          "Scope": "GLOBAL",  
          "ObjectName": "node-bootstrap",  
          "Namespace": ""  
        }  
      ]  
    }  
  ],  
  "DeletedAPIs": [  
    {  
      "Group": "extensions",  
      "Kind": "Ingress",  
      "Version": "v1beta1",  
      "Name": "ingresses",  
      "Deleted": true,  
      "Items": [  
        {  
          "Scope": "OBJECT",  
          "ObjectName": "logger-ingress",  
          "Namespace": "logger"  
        }  
      ]  
    }  
  ]  
}
```

Then I piped that into [Dasel](https://github.com/TomWright/dasel) to get a syntatic view:
```bash
dasel select --file kubepug_output.json --multiple \  
  --parser json ".DeletedAPIs.[*]" \  
--format '  {{ select ".Kind" }}.{{ select ".Version"}}.{{ select ".Group" }}:{{newline}}{{ selectMultiple ".Items.[*]" | format "\t{{ select \".Namespace\" }}/{{ select \".ObjectName\" }}{{newline}}" }} '
```

Breaking it down we have:

`select ... ".DeletedAPIs.[*]"`

which is only focusing on the `DeletedAPIs` array. Then we have the output format. Here’s a breakdown:

```{{ select ".Kind" }}.{{ select ".Version"}}.{{ select ".Group" }}```

This first part is printing the full resource `KVG` . Then there’s a line return and:

```
{{ selectMultiple ".Items.[*]" | format   
    "\t{{ select \".Namespace\" }}/{{ select \".ObjectName\" }}  
    {{newline}}
```

This is a loop saying, for every item in `Items` print a tab then `namespace`/ `objectName`. Then we add a line returned.

which returned one ingress per line:
```
Ingress.v1beta1.extensions:  
    logger/logger-ingress  
    other_namespace/other_ingress
```

You can then query K8s with a command like:
```bash
k get Ingress.v1beta1.extensions -A
# or
k get Ingress.v1beta1.extensions -n logger logger-ingress
```

OK, it sounds pretty useless as I only have few `ingresses` but it could have been far worse 😅  
And now, you can extend this output to generate some kubectl commands programmatically… which may be usefull down the line

At least I practiced `Dasel` !

#### Update 1

Looking to the original API used to create resources inside k8s, I got to the point where I could use the `ManagedFields` information. This is not a precise way of doing it, as things may be updated later on after deployment, and may not reflect the real information.

Whatever, I did gave a shot at it.

A simple way to do is to call the K8s API directly by using the `--raw` option. Here’s how to list `ingress` resource:
```bash
kubectl get --raw=/apis/networking.k8s.io/v1/ingresses
```

This is giving me the list of all `ingress` metadata:
```json
{  
  "kind": "IngressList",  
  "apiVersion": "networking.k8s.io/v1",  
  "metadata": {  
    "resourceVersion": "450328"  
  },  
  "items": [  
    {  
      "metadata": {  
        "name": "test-ext-v1beta-1",  
...  
        "managedFields": [  
          {  
            "manager": "glbc",  
            "operation": "Update",  
            "apiVersion": "networking.k8s.io/v1",  
            "time": "2022-06-29T19:46:39Z",  
            "fieldsType": "FieldsV1",  
            "fieldsV1": {  
              "f:metadata": {  
                "f:finalizers": {  
                  ".": {},  
                  "v:\"networking.gke.io/ingress-finalizer-V2\"": {}  
                }  
              }  
            }  
          },  
          {  
            "manager": "kubectl-client-side-apply",  
            "operation": "Update",  
            "apiVersion": "extensions/v1beta1",  
            "time": "2022-06-29T19:46:39Z",  
            "fieldsType": "FieldsV1",  
            "fieldsV1": {  
              "f:metadata": {  
                "f:annotations": {  
                  ".": {},  
                  "f:kubectl.kubernetes.io/last-applied-configuration": {},  
                  "f:kubernetes.io/ingress.class": {}  
                }  
              },  
...
```

The interesting bits here are the two `managedFields` . While they have the same `time` value, one was managed by `kubectl` and the other one by `glbc`.

The `kubectl` one is using an API version as `"apiVersion": "extensions/v1beta1"` which is a way to know which API was used when the resource was created.

Again, I used Dasel to get the interesting bits here:

```bash
kubectl get --raw=/apis/networking.k8s.io/v1/ingresses| \  
dasel -p json -m select --color -s 'items.[*].metadata' \  
--format '{{ select ".namespace" }}/{{ select ".name" }}: {{ selectMultiple ".managedFields.[*]"| format "{{ select \".apiVersion\"}}, " }}'
```

With my 3 test ingress, with different versions, It returns:
```
default/test-ext-v1beta-1: networking.k8s.io/v1, extensions/v1beta1,  
default/test-ext-v1beta-upgraded: networking.k8s.io/v1, extensions/v1beta1, networking.k8s.io/v1,  
default/test-net-v1beta-1: networking.k8s.io/v1, networking.k8s.io/v1beta1,
```
#### Update 2

For the ones interested, I also implemented that in Go using the Kubernetes `client-go` . I’m not going to dig much here, but you can access the same values by calling:

```go
ingress, err := clientset.NetworkingV1().Ingresses("").List(context.TODO(), metav1.ListOptions{})
for _, ing := range ingress.Items {  
  ingInfos := ing.GetObjectMeta()  
  fields := ingInfos.GetManagedFields()  

  // Iterate through fields   
  }
  ```

---
title: "Playing with Dasel"
author: "Prune"
date: 2022-06-30T15:19:54.609Z
lastmod: 2023-11-30T22:23:50-05:00

description: ""

subtitle: "Lately I worked on deprecated and deleted APIS from Kubernetes cluster for migration from version 1.20 and 1.21 to 1.22 (or 1.23)."




aliases:
    - "/playing-with-dasel-a601398b3900"

---

Lately I worked on deprecated and deleted APIS from Kubernetes cluster for migration from version 1.20 and 1.21 to 1.22 (or 1.23).

To do so, I used the famous [KubePug](https://github.com/rikatz/kubepug) tool, specifically the Krew plugin.

As I have a bunch of clusters I used some dirty `for loops` , but here’s the global KubePug usage:
`kubectl deprecations --k8s-version=v1.23.0 --format json --context ${my_cluster_name} | jq &#39;.&#39; &gt; kubepug_output.json`

The output file, PrettyPrinted, look something like:
`{  
  &#34;DeprecatedAPIs&#34;: [  
    {  
      &#34;Description&#34;: &#34;ComponentStatus (and ComponentStatusList) holds the cluster validation info. Deprecated: This API is deprecated in v1.19+&#34;,  
      &#34;Group&#34;: &#34;&#34;,  
      &#34;Kind&#34;: &#34;ComponentStatus&#34;,  
      &#34;Version&#34;: &#34;v1&#34;,  
      &#34;Name&#34;: &#34;&#34;,  
      &#34;Deprecated&#34;: true,  
      &#34;Items&#34;: [  
        {  
          &#34;Scope&#34;: &#34;GLOBAL&#34;,  
          &#34;ObjectName&#34;: &#34;scheduler&#34;,  
          &#34;Namespace&#34;: &#34;&#34;  
        }  
      ]  
    },  
    {  
      &#34;Description&#34;: &#34;PodSecurityPolicy governs the ability to make requests that affect the Security Context that will be applied to a pod and container. Deprecated in 1.21.&#34;,  
      &#34;Group&#34;: &#34;policy&#34;,  
      &#34;Kind&#34;: &#34;PodSecurityPolicy&#34;,  
      &#34;Version&#34;: &#34;v1beta1&#34;,  
      &#34;Name&#34;: &#34;&#34;,  
      &#34;Deprecated&#34;: true,  
      &#34;Items&#34;: [  
        {  
          &#34;Scope&#34;: &#34;GLOBAL&#34;,  
          &#34;ObjectName&#34;: &#34;node-bootstrap&#34;,  
          &#34;Namespace&#34;: &#34;&#34;  
        }  
      ]  
    }  
  ],  
  &#34;DeletedAPIs&#34;: [  
    {  
      &#34;Group&#34;: &#34;extensions&#34;,  
      &#34;Kind&#34;: &#34;Ingress&#34;,  
      &#34;Version&#34;: &#34;v1beta1&#34;,  
      &#34;Name&#34;: &#34;ingresses&#34;,  
      &#34;Deleted&#34;: true,  
      &#34;Items&#34;: [  
        {  
          &#34;Scope&#34;: &#34;OBJECT&#34;,  
          &#34;ObjectName&#34;: &#34;logger-ingress&#34;,  
          &#34;Namespace&#34;: &#34;logger&#34;  
        }  
      ]  
    }  
  ]  
}`

Then I piped that into [Dasel](https://github.com/TomWright/dasel) to get a syntatic view:
`dasel select --file kubepug_output.json --multiple \  
  --parser json &#34;.DeletedAPIs.[*]&#34; \  
--format &#39;  {{ select &#34;.Kind&#34; }}.{{ select &#34;.Version&#34;}}.{{ select &#34;.Group&#34; }}:{{newline}}{{ selectMultiple &#34;.Items.[*]&#34; | format &#34;\t{{ select \&#34;.Namespace\&#34; }}/{{ select \&#34;.ObjectName\&#34; }}{{newline}}&#34; }} &#39;`

Breaking it down we have:
`select ... &#34;.DeletedAPIs.[*]&#34;`

which is only focusing on the `DeletedAPIs` array. Then we have the output format. Here’s a breakdown:
`{{ select &#34;.Kind&#34; }}.{{ select &#34;.Version&#34;}}.{{ select &#34;.Group&#34; }}`

This first part is printing the full resource `KVG` . Then there’s a line return and:
`{{ selectMultiple &#34;.Items.[*]&#34; | format   
    &#34;\t{{ select \&#34;.Namespace\&#34; }}/{{ select \&#34;.ObjectName\&#34; }}  
    {{newline}}`

This is a loop saying, for every item in `Items` print a tab then `namespace`/ `objectName`. Then we add a line returned.

which returned one ingress per line:
`Ingress.v1beta1.extensions:  
    logger/logger-ingress  
    other_namespace/other_ingress`

You can then query K8s with a command like:
`k get Ingress.v1beta1.extensions -A``or``k get Ingress.v1beta1.extensions -n logger logger-ingress`

OK, it sounds pretty useless as I only have few `ingresses` but it could have been far worse :)  
And now, you can extend this output to generate some kubectl commands programmatically… which may be usefull down the line

At least I practiced `Dasel` !

#### Update 1

Looking to the original API used to create resources inside k8s, I got to the point where I could use the `ManagedFields` information. This is not a precise way of doing it, as things may be updated later on after deployment, and may not reflect the real information.  
Whatever, I did gave a shot at it.

A simple way to do is to call the K8s API directly by using the `--raw` option. Here’s how to list `ingress` resource:
`kubectl get --raw=/apis/networking.k8s.io/v1/ingresses`

This is giving me the list of all `ingress` metadata:
`{  
  &#34;kind&#34;: &#34;IngressList&#34;,  
  &#34;apiVersion&#34;: &#34;networking.k8s.io/v1&#34;,  
  &#34;metadata&#34;: {  
    &#34;resourceVersion&#34;: &#34;450328&#34;  
  },  
  &#34;items&#34;: [  
    {  
      &#34;metadata&#34;: {  
        &#34;name&#34;: &#34;test-ext-v1beta-1&#34;,  
...  
        &#34;managedFields&#34;: [  
          {  
            &#34;manager&#34;: &#34;glbc&#34;,  
            &#34;operation&#34;: &#34;Update&#34;,  
            &#34;apiVersion&#34;: &#34;networking.k8s.io/v1&#34;,  
            &#34;time&#34;: &#34;2022-06-29T19:46:39Z&#34;,  
            &#34;fieldsType&#34;: &#34;FieldsV1&#34;,  
            &#34;fieldsV1&#34;: {  
              &#34;f:metadata&#34;: {  
                &#34;f:finalizers&#34;: {  
                  &#34;.&#34;: {},  
                  &#34;v:\&#34;networking.gke.io/ingress-finalizer-V2\&#34;&#34;: {}  
                }  
              }  
            }  
          },  
          {  
            &#34;manager&#34;: &#34;kubectl-client-side-apply&#34;,  
            &#34;operation&#34;: &#34;Update&#34;,  
            &#34;apiVersion&#34;: &#34;extensions/v1beta1&#34;,  
            &#34;time&#34;: &#34;2022-06-29T19:46:39Z&#34;,  
            &#34;fieldsType&#34;: &#34;FieldsV1&#34;,  
            &#34;fieldsV1&#34;: {  
              &#34;f:metadata&#34;: {  
                &#34;f:annotations&#34;: {  
                  &#34;.&#34;: {},  
                  &#34;f:kubectl.kubernetes.io/last-applied-configuration&#34;: {},  
                  &#34;f:kubernetes.io/ingress.class&#34;: {}  
                }  
              },  
...`

The interesting bits here are the two `managedFields` . While they have the same `time` value, one was managed by `kubectl` and the other one by `glbc`.

The `kubectl` one is using an API version as `&#34;apiVersion&#34;: &#34;extensions/v1beta1&#34;` which is a way to know which API was used when the resource was created.

Again, I used Dasel to get the interesting bits here:
`kubectl get --raw=/apis/networking.k8s.io/v1/ingresses| \  
dasel -p json -m select --color -s &#39;items.[*].metadata&#39; \  
--format &#39;{{ select &#34;.namespace&#34; }}/{{ select &#34;.name&#34; }}: {{ selectMultiple &#34;.managedFields.[*]&#34;| format &#34;{{ select \&#34;.apiVersion\&#34;}}, &#34; }}&#39;`

With my 3 test ingress, with different versions, It returns:
`default/test-ext-v1beta-1: networking.k8s.io/v1, extensions/v1beta1,  
default/test-ext-v1beta-upgraded: networking.k8s.io/v1, extensions/v1beta1, networking.k8s.io/v1,  
default/test-net-v1beta-1: networking.k8s.io/v1, networking.k8s.io/v1beta1,`

#### Update 2

For the ones interested, I also implemented that in Go using the Kubernetes `client-go` . I’m not going to dig much here, but you can access the same values by calling:
`ingress, err := clientset.NetworkingV1().Ingresses(&#34;&#34;).List(context.TODO(), metav1.ListOptions{})``for _, ing := range ingress.Items {  
  ingInfos := ing.GetObjectMeta()  
  fields := ingInfos.GetManagedFields()  

  // Iterate through fields   
  }`

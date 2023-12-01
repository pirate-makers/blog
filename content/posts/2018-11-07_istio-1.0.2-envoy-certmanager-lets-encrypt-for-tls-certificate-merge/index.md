---
title: "Istio 1.0.2 (Envoy) + Cert-Manager + Let’s Encrypt for TLS + Certificate Merge"
author: "Prune"
date: 2018-11-07T17:38:31.904Z
lastmod: 2023-11-30T22:09:05-05:00

description: ""

subtitle: "Recap"

image: "images/1.jpeg" 
images:
 - "images/1.jpeg"
 - "images/2.png"

tags: ["devops", "servicemesh", "kubernetes", "dev", "golang"]

aliases:
    - "/istio-1-0-2-envoy-cert-manager-lets-encrypt-for-tls-certificate-merge-7a774bff66c2"

---

![image](images/1.jpeg#layoutTextWidth)


### Recap

I already talked about Istio + Cert-Manager in [part one](https://medium.com/@prune998/istio-envoy-cert-manager-lets-encrypt-for-tls-14b6a098f289) and [part two](https://medium.com/@prune998/istio-0-8-0-envoy-cert-manager-lets-encrypt-for-tls-d26bee634541). In the meantime Istio went to release 1.0, lastly 1.0.3.

While this version improves a lot of things and finally get rid of some nasty bugs when using gRPC (HTTP2) Streams, there’s still no improvement on the Ingress Gateway SSL Management.

Let me remind you :

*   Cert-Manager only create **TLS Secrets**, which are a kind of Secret that only contains a **crt** and **key** file.
*   Istio Ingress Gateway only mount **ONE Secret** named _istio-ingressgateway-certs._
*   Istio Ingress Gateway have no way to detect when a SSL Certificate is updated.

This three constraints lead to the fact that :

*   you can only create ONE **Certificate** Resource with all your endpoints in it
*   the target **TLS Secret** have to be located in the Istio-System Namespace
*   You can’t mix certificates created from Cert-Manager and another source (like providing your own Certificates for some domains)

### What solutions do we have ?

Well, not much right now.

Cert-Manager’s team is looking into this and will change/stabilize the API _soon_, which should offer other ways to store Secrets, like Ashicorp Vault.  
When I say _soon_, it’s more of a joke than a close event. I opened a discussion months ago and went almost to a PR to allow Cert-Manager to be able to write multiple Certificates inside a single Secret, changing their type from TLS to Opaque. Following the discussion I did not push the PR. I was told that :
> We can’t accept a PR like this as we are trying to stabilize the API and the final storage for Certificates is not yet decided. Also, we have to be careful not to include things in the API that we couldn’t support in the long term.

Istio is also looking for a solution to use something else than Secrets, of have something else manage the secrets for you. As of now, Istio (and the Ingress Gateway) do not support automatic update when a Secret is updated.

### Then enter Cert-Merge Operator

I was so much frustrated about all this that I came with my own solution : [Cert-Merge Operator](https://github.com/prune998/certmerge-operator)!

Be warned : this is my first time using the [Operator SDK](https://github.com/operator-framework/operator-sdk) and this is Beta software. Still, I just put it in Production on our platform.

The idea is simple : as Istio can only read _ONE Secret_ to fetch _Certificates_ and since Cert-Manager can only set _ONE certificate_ in each _Secret_, we need a way to **merge many TLS Secret’s data into one Opaque Secret with many Certificates.**

So, how does this work ? Let’s find out…

![image](images/2.png#layoutTextWidth)


1.  The user push Manifests to create some _Certificates_
2.  **Cert-Manager** is triggered and create to corresponding TLS Secrets
3.  **CertMerge Operator** watch for Secrets and is triggered when Cert-Manager create or update them
4.  **CertMerge Operator** also watch for _CertMerge_ requests. In our case, we decided to merge ALL certificates with a Label _certmerge=true_ into ONE SINGLE _Opaque Secret._
This is due to Istio limitation to only mount one secret inside the Ingress Gateway.
5.  **CertMerge Operator** create the Istio’s needed Secret
6.  the **Istio Ingress Gateway** watch for _Gateway_ Resources. Each _Gateway_ is defined to use a different certificate name (coming from the same single Secret which is mounted at start)

### Can I do that in Prod ?

Well, while it’s working on our platform, there still are some possible issues :

First, this solution needs you to have a **Label** on the Cert-Manager’s Secret.  
This **Label** is used by the Cert-Merge Operator to search/select the secrets that needs to be merged. This not supported at the moment.   
It’s also why I’m pissed off by Cert-Manager project.

Short explanation : I opened an [issue](https://github.com/jetstack/cert-manager/issues/977), then a [PR](https://github.com/jetstack/cert-manager/pull/1027), to add support for Labels in the Certificate Custom Resource.  
This PR was rejected with almost the same statement I had months before :
> So at the moment there’s open questions around how we can define alternate representations of certificates (i.e. as a secret, as a field on another resource, or even being stored in other secret backends). We need to work out how these sorts of things will be represented before we accept new fields on our API resources that may in future be difficult to maintain.> For that reason, I don’t think we can accept this PR for the time being.

Well, you can go read the whole thread, but as far as I’m concerned, there ALREADY is a v1 API for Cert-Manager, and whatever is done, there WILL BE A v2 anytime soon. So, instead of improving V1 right now and maybe change it in V2, they prefer waiting for V2.

I already waited too many years of my life…   
- for a girlfriend which dumped me after 5 years  
- for the new Iphone XS which would be faster than the X (which is, but have smaller battery)  
- for a real summer in Quebec City  
- for the next Macpro which never came (don’t call the trashcan a Macpro !)

I will not wait for a CNCF Project to stop improving on V1 while they try to settle on V2.

So, to conclude : **NO YOU CAN’T !**

As suggested by the Cert-Manager’s involved people, you CAN pre-create the `Secrets` with the desired names and add `Labels`. Cert-Manager will add the SSL Cert’s data afterward. (never tested this)

Well, again, I’m questioning these guy’s production knowledge. The whole point of all this is automation. I create a `Certificate` CR and I get a `Secret` with the certificate. If I have to create the `Secret` before uploading the `Certificate` CR, I would rather create the crt and key files on my own and upload them into the `Secret`.

### I still want it !

Notice : _It’s beta, it does not work with stock Cert-Manager, it may change in the future._

So if you still want to use it, you have to build your own Cert-Manager with my PR applied. You can clone from my [Github repo](https://github.com/prune998/cert-manager/tree/prune/certificate-labels).

Also, note that there MAY BE some security concerns using the CertMerge Operator… Be conscious that you are giving the right to an Operator to read ALL the Secrets in your Kubernetes cluster and potentially merge them into another Namespace.

I’m pretty sure LOTS of people will have to complain about that.

I still have to figure out the real workflow here…   
Should I just manage Secrets from within the Istio-System Namespace ?   
Should I only be able to merge Secrets from a Namespace into the same Namespace ?

### What about the Operator SDK ?

Well, I got this Operator setup and running, starting from almost 0, in few hours coding. So I think we can say it’s a really cool and fast path to creating Operators.  
I also had [great support from the community] (https://github.com/operator-framework/operator-sdk/issues/694)when I was struggling to add some features.

From my point of view I would have loved a little more examples and docs.

I won’t go through the Operator SDK Cli setup, just follow the [Quick Start](https://github.com/operator-framework/operator-sdk#quick-start) of the [Blog Post](https://coreos.com/blog/introducing-operator-framework). I’m just going to explain some of my code.

Once you have the CLI setup you can start creating your Operator. As you’ll see in the QuickStart, you need to create a new Operator, add an API (your Custom Resource) and add a Controler. This is all done using the CLI and will provide a default implementation :
```bash
operator-sdk new certmerge-operator  
cd certmerge-operator  
operator-sdk add api --api-version=certmerge.lecentre.net/v1alpha1 --kind=CertMerge  
operator-sdk add controller --api-version=certmerge.lecentre.net/v1alpha1 --kind=CertMerge  
operator-sdk generate k8s
```

The last command, `operator-sdk generate k8s` will generate the needed code from your Custom Resouce Definition so you will have to run it every time you change something.

#### The Custom Resource

In my case the Custom Resouce is of `Type: CertMerge` and is defined in `pkg/apis/certmerge/v1alpha1/certmerge_types.go` .

It must include all the needed fields your Operator will need to do it’s job. You also need a `List` type of your Resource. Here’s my CR :
```go
// CertMerge is the Schema for the certmerges API  
type CertMerge struct {  
  metav1.TypeMeta   `json:",inline"`  
  metav1.ObjectMeta `json:"metadata,omitempty"```  Spec   CertMergeSpec   `json:"spec,omitempty"`  
  Status CertMergeStatus `json:"status,omitempty"`  
}
// CertMergeList contains a list of CertMerge  
type CertMergeList struct {  
  metav1.TypeMeta `json:",inline"`  
  metav1.ListMeta `json:"metadata,omitempty"```  Items           []CertMerge `json:"items"`  
}
```

Most important here are that my CR contains a `Spec`, holding the details of my CR, and a `Status`, holding the fields that my Operator can use to re-concile the CR. I haven’t add stuff to the Status part of the Operator right now.

The `Spec` is defined as :
```go
// CertMergeSpec defines the desired state of CertMerge``type CertMergeSpec struct {  
  SecretName      string             `json:"name"`  
  SecretNamespace string             `json:"namespace"`  
  Selector        []SecretSelector   `json:"selector"`  
  SecretList      []SecretDefinition `json:"secretlist"`  
}
// SecretSelector defines the needed parameters to search for secrets by Label  
type SecretSelector struct {  
  LabelSelector metav1.LabelSelector `json:"labelselector"`  
  Namespace     string               `json:"namespace"`  
}
// SecretDefinition defines the parameters to search for secrets by name  
type SecretDefinition struct {  
  Name      string `json:"name"`  
  Namespace string `json:"namespace"`  
}
```

To define a Merge we need to give it a Name and a Namespace, a list of Secrets to add (SecretList) and a list of Labels to search for (we will include all the certs that match the Labels).

#### The Main

There’s not much in the main. I decided to use [Logrus](https://github.com/Sirupsen/logrus) as logger but there are active discussions to change it to [Glog](https://github.com/golang/glog) and Zap (but my friend and co-worker Akh is strongly discouraging me to go with Glog) . I added an option to change the Log Level :
```go
var (  
  logLevel       = flag.String("loglevel", log.WarnLevel.String(), "the log level to display")  
  displayVersion = flag.Bool("version", false, "Show version and quit")  
)
func main() {  
  flag.Parse()
  // set logs in json format  
  myLogLevel, err := log.ParseLevel(*logLevel)  
  if err != nil {  
    myLogLevel = log.WarnLevel  
  }  
  log.SetLevel(myLogLevel)  
  log.SetFormatter(&log.JSONFormatter{}
```

Then you create a Manager which holds all the SDK components :
```go
mgr, err := manager.New(cfg, manager.Options{Namespace: ""})
```

Using an empty Namespace make the Operator watch ALL Namespaces. You will have to update the RBAC rules for your Operator to allow for this. I’ve changed the Roles/RoleBindings to ClusterRoles/ClusterRoleBindings.

You finally add all APIs and Controlers. These lines will load ALL the files located in the `pkg/apis` and `pkg/controller` to the Manager :
```go
// Setup Scheme for all resources  
if err := apis.AddToScheme(mgr.GetScheme()); err != nil {  
  log.Fatal(err)  
}
// Setup all Controllers  
if err := controller.AddToManager(mgr); err != nil {  
  log.Fatal(err)  
}
```

#### The Watch

The Operator watch for some Resources change to trigger a Reconcile. This is done in the `Controler`. It’s located in the file `pkg/controller/certmerge/certmerge_controller.go`

The `Add` function is called when we add the Controlers. This function indeed create the Controler and all the Watched. Obviously you want to watch your own Custom Resource (I will use CR now on) :
```go
func add(mgr manager.Manager, r reconcile.Reconciler, mapFn handler.ToRequestsFunc) error {
  // Create a new controller  
  c, err := controller.New("certmerge-controller", mgr, controller.Options{Reconciler: r})  
  if err != nil {  
    return err  
  }
  // Watch for changes to primary resource CertMerge  
  err = c.Watch(&source.Kind{Type: &certmergev1alpha1.CertMerge{}}, &handler.EnqueueRequestForObject{})  
  if err != nil {  
    return err  
  }
```

If you’re building your own Operator from scratch, your `add` func is going to take only 2 parameters. The last one, `mapFn handler.ToRequestsFunc` is a function that will be called by some `Watch` instead of the default `Reconcile` function. I’ll get to it soon.

In this Operator, we watch for `CertMerge` CR and we create/update `Secrets`. The SDK have a cool way to link the `Secrets` we create. This allows us, for example, to automatically remove the `Secret` when the `CertMerge` is removed.

To do that we create a new `Watch` with a handler of `EnqueueRequestForOwner` instead of a `EnqueueRequestForObject` :
```go
// This will trigger the Reconcile if the Merged Secret is modified
err = c.Watch(&source.Kind{Type: &corev1.Secret{}}, &handler.EnqueueRequestForOwner{  
  IsController: true,  
  OwnerType:    &certmergev1alpha1.CertMerge{},  
})
```

So now, the Reconcile will be triggered if there is an event regarding a `CertMerge` resource of a `Secret` resource that is managed by our Operator.

When Cert-Manager renew a Certificate it will update the target Secret. This event also need to be watched by our Operator. This is done using another kind of `Watch` : the `EnqueueRequestsFromMapFunc`
```go
// Watch for Secret change and process them through the SecretTriggerCertMerge function
// This watch enables us to reconcile a CertMerge when a concerned Secret is changed (create/update/delete)
err = c.Watch(  
  &source.Kind{Type: &corev1.Secret{}},  
  &handler.EnqueueRequestsFromMapFunc{  
    ToRequests: mapFn,  
  },  
  p,  
)
```

We’re saying here that we will run the `mapFn` function when a `Secret` event is triggered.

We also use `p`, a `Predicate`. Predicates are used to filter `Events`. The `Predicate` function will return `true` if the event have to be passed to the `mapFn` function or `false` to drop the event.

For example, the `Delete` events are dropped :
```go
DeleteFunc: func(e event.DeleteEvent) bool {  
  return false  
},
```

We drop `Delete` events as, when deleting an object, the K8s API first create an`Update event` with some `Delete Metadata` then create a `Delete event`.

In case of an `Update` event, we don’t want to trigger a `Reconcile` if the Secret’s data is not changed :
```go
// if old and new data is the same, don't reconcile  
newObj := e.ObjectNew.DeepCopyObject().(*corev1.Secret)  
oldObj := e.ObjectOld.DeepCopyObject().(*corev1.Secret)
if cmp.Equal(newObj.Data, oldObj.Data) {  
  return false  
}
```

I’m still not sure how to only trigger the right events. As the `mapFn` func only gets access to the latest object (not the old or the diff), it does not know if it’s a create, update or delete operation that triggered the event.  
In case of a delete, for example, 2 events are fired : first an `Update` and then a `Delete`. During the `Delete` operation, the Secret is already removed, so the reconcile will fail. The target Merged Secret will not be updated and the now-removed certificate will still be visible inside the Secret.

There’s still work to do to improve all this.

### Secret’s Event Management

As stated, a `Secret` update event will trigger the `mapFn` func which, in this controller, is `SecretTriggerCertMerge`.

The purpose of this function is to find all the `CertMerge` CR that should be reconciled when a `Secret` is changed.

First thing to do here is to DROP the event if the `Secret` is/was created by the Operator itself. This case is already taken care by the other Secret’s Watch.

We then get all the `CertMerge` CR and check if the `Secret` have a Name or the Labels the CR requires.

If yes, we add the CR to the list and return it. Each CR in the list will trigger a Reconcile.
```go
// parse each CertMerge CR and reconcile them if needed  
for _, cm := range cml.Items {  
  if secretInCertMergeList(&cm, instance) || secretInCertMergeLabels(&cm, instance) {  
    // trigger the CertMerge Reconcile  
    result = append(result, reconcile.Request{ NamespacedName: client.ObjectKey{Namespace: cm.Namespace, Name: cm.Name}})
    log.Infof("CertMerge %s/%s added to Reconcile List", cm.Namespace, cm.Name)  
  }  
}
return result
```

#### Reconcile

The last part and most important is the Reconcile function.  
It is triggered when a`CertMerge` event occurs and when a `Secret` event is concerned by a `CertMerge` CR.

As we merge based on `Secret` Name and `Secret` Labels, we have a two pass strategy where we add all concerned `Secrets` to a list. We finally concat them into a `Secret` and put in back in K8s using the API.
```go
secret := newSecretForCR(instance)  
certData := make(map[string][]byte)
if len(instance.Spec.SecretList) > 0 {  
  for _, sec := range instance.Spec.SecretList {  
    secContent, err := r.searchSecretByName(sec.Name, sec.Namespace)  
...  
    certData[sec.Name+".crt"] = secContent.Data["tls.crt"]  
    certData[sec.Name+".key"] = secContent.Data["tls.key"]  
  }  
}
if len(instance.Spec.Selector) > 0 {  
  for _, sec := range instance.Spec.Selector {  
    secContent, err := r.searchSecretByLabel(sec.LabelSelector.MatchLabels, sec.Namespace)  
    for _, secCert := range secContent.Items {  
      certData[secCert.Name+".crt"] = secCert.Data["tls.crt"]  
      certData[secCert.Name+".key"] = secCert.Data["tls.key"]  
    }  
  }  
}
secret.Data = certData  
err = r.client.Create(context.TODO(), secret)
```

Of course this is far more complicated, but check the code, this is just a workflow overview.

### Using the Operator

If you still think this Operator can suite your needs, deploy it for yourself.

To do so you will find the sample deployment manifests in the `deploy` folder. You just need to apply them in the right namespace.

This deployment use the `:latest` image of my public [Docker Hub Registry](https://hub.docker.com/r/prune/cert-operator/).

Quoting the `README.md` file :
```bash
kubectl apply -f deploy/namespace.yaml  
kubectl -n cert-merge apply -f deploy/service_account.yaml  
kubectl -n cert-merge apply -f deploy/role.yaml  
kubectl -n cert-merge apply -f deploy/role_binding.yaml  
kubectl -n cert-merge apply -f deploy/certmerge_v1alpha1_certmerge_crd.yaml  
kubectl -n cert-merge apply -f deploy/operator.yaml
```

Ok you’ve got an operator, now what ?

#### Cert-Manager Certificates

Now that you have the Operator, you can split all your `Certificates` in different `Secrets`. This is my first `Certificate` :
```yaml
apiVersion: certmanager.k8s.io/v1alpha1  
kind: Certificate  
metadata:  
  name: cert-svc.dev.domain.com  
  namespace: istio-system  
spec:  
  acme:  
    config:  
    - dns01:  
        provider: aws-dns-prod  
      domains:  
        - svc.dev.domain.com  
  commonName: svc.dev.domain.com  
  dnsNames:  
    - svc.dev.domain.com  
  labels:  
    env: "dev"  
    certmerge: "true"  
  issuerRef:  
    kind: ClusterIssuer  
    name: letsencrypt-prod  
  secretName: cert-svc.dev.domain.com  
organization:  
  - My Own Team
```

Once Cert-Manager job is done I’ll have a new Secret `cert-svc.dev.domain.com` in the `istio-system` Namespace.

Let’s add another one :
```yaml
apiVersion: certmanager.k8s.io/v1alpha1  
kind: Certificate  
metadata:  
  name: cert-svc.prod.domain.com  
  namespace: istio-system  
spec:  
  acme:  
    config:  
    - dns01:  
        provider: aws-dns-prod  
      domains:  
        - svc.prod.domain.com  
  commonName: svc.prod.domain.com  
  dnsNames:  
    - svc.prod.domain.com  
  labels:  
    env: "prod"  
    certmerge: "true"  
  issuerRef:  
    kind: ClusterIssuer  
    name: letsencrypt-prod  
  secretName: cert-svc.prod.domain.com  
organization:  
  - My Own Team
```

Ensure all certificates are generated :
```bash
kubectl -n istio-system get secrets -l certmerge=true

NAME                        TYPE                DATA      AGE  
cert-svc.dev.domain.com     kubernetes.io/tls   2         7h  
cert-svc.prod.domain.com    kubernetes.io/tls   2         7h
```

Now Create the Merge. We only need ONE `CertMerge` CR as Istio can only read ONE `Secret`. So let’s put everything in it :
```yaml
apiVersion: certmerge.lecentre.net/v1alpha1  
kind: CertMerge  
metadata:  
  name: "certmerge-istio-ingress"  
spec:  
  selector:  
  - labelselector:  
      matchLabels:  
        certmerge: "true"  
    namespace: istio-system  
  name: istio-ingressgateway-certs  
  namespace: istio-system
```

After that, you should have one new `Secret` called `istio-ingressgateway-certs`. Let’s check that :
```bash
kubectl -n istio-system describe  secrets istio-ingressgateway-certs  

Name:         istio-ingressgateway-certs  
Namespace:    istio-system  
Labels:       certmerge=certmerge-istio-ingress  
              creator=certmerge-operator  
Annotations:  <none>``Type:  Opaque``Data  
====  
cert-svc.dev.domain.com.crt     1675 bytes  
cert-svc.dev.domain.com.key     1675 bytes  
cert-svc.prod.domain.com.crt    1675 bytes  
cert-svc.prod.domain.com.key    1675 bytes
```

That’s it !

You can now create the `Istio Gateways` for Dev:
```yaml
apiVersion: networking.istio.io/v1alpha3  
kind: Gateway  
metadata:  
  name: svc-dev-gateway  
spec:  
  selector:  
    istio: ingressgateway  
servers:  
- port:  
    number: 443  
    name: https-443-svc-dev  
    protocol: HTTPS  
  tls:  
    mode: SIMPLE  
    serverCertificate: /etc/istio/ingressgateway-certs/cert-svc.dev.domain.com.crt  
    privateKey: /etc/istio/ingressgateway-certs/cert-svc.dev.domain.com.key  
  hosts:  
    - "svc.dev.domain.com"
```

And for Prod :
```yaml
apiVersion: networking.istio.io/v1alpha3  
kind: Gateway  
metadata:  
  name: svc-prod-gateway  
spec:  
  selector:  
    istio: ingressgateway  
servers:  
- port:  
    number: 443  
    name: https-443-svc-prod  
    protocol: HTTPS  
  tls:  
    mode: SIMPLE  
    serverCertificate: /etc/istio/ingressgateway-certs/cert-svc.prod.domain.com.crt  
    privateKey: /etc/istio/ingressgateway-certs/cert-svc.prod.domain.com.key  
  hosts:  
    - "svc.prod.domain.com"
```

Add your `VirtualServices` as usual and you're done !

One note though :   
As of now, Istio Ingress Gateway is not able to detect when a “file” (a Certificate) is updated in the `Secret`.   
That means that even if you `Secret` will always be up to date when Cert-Manager renew some certs, Istio will not pick them up.  
The solution (not part of this blog) is to either :

*   update the `Gateway` resource (maybe an update is not enough and you need to delete/create it again, will have to check that in another post)
*   trigger a reload of `Envoy` by calling it’s internal API

Istio’s team is supposed to address that soon.

### Final words

I’m really questioning the CNCF influence on many projects related to K8s lately.

K8s and micro-services are all about fast iteration, agility, automation…   
I’m not saying we can’t step back and think for some time. It’s good to have a clear plan, settle an API and support it.  
But it’s also fine to settle on a V1, improve it and reach a V2, even if that imply API changes.

It’s also good to admit things are missing in an API. Labels are a key component to the whole K8s ecosystem. Not having them is Cert-Manager is not a decision, it’s a lack of feature, whatever API you support.

Of course it’s my point of view, and I still thank all the people working hard on these projects. We need them. They are unreplaceable.  
Just keep in mind that APIs are not written in stone. You’re allowed to break your API when going from V1 to V2.

Also remember that all this work is a patch on the current implementation of Cert-Manager and Istio Ingress Gateway. As soon as something new comes in, like using an SSL backend storage (maybe Ashicorp Vault ?) or a Gateway SSL management by the Istio Backplane… you’ll be able to trash all this !

---
title: "Istio (Envoy) + Cert-Manager + Let’s Encrypt for TLS"
author: "Prune"
date: 2018-01-23T23:12:08.221Z
lastmod: 2023-11-30T22:05:27-05:00

description: ""

subtitle: "Updates 1"

image: "images/2.jpeg" 
images:
 - "images/1.jpeg"
 - "images/2.jpeg"
 - "images/3.jpeg"

tags: ["devops", "servicemesh", "kubernetes"]

aliases:
    - "/istio-envoy-cert-manager-lets-encrypt-for-tls-14b6a098f289"

---

![image](images/1.jpeg#layoutTextWidth)
#### Updates 1

Thanks to comments by Laurent Demailly, here are some updates. This article have been updated accordinately :

*   there is now an [official Helm Chart for Cert-Manager](https://github.com/kubernetes/charts/tree/master/stable/cert-manager)
*   Istio Ingress also support GRPC, which is based on HTTP/2

#### Update 2 (2018–06–26)

I made a new post to use Cert-Manager with Istio 0.8.0 [here](https://medium.com/@prune998/istio-0-8-0-envoy-cert-manager-lets-encrypt-for-tls-d26bee634541).

### Istio

[Istio](https://istio.io/) is a part of a new way to manage the flow of data in your Microservice world. In fact, it’s even more than that to me.   
People can’t stop speaking of Microservice vs Monolith, how it’s better for dev, easy to maintain, faster to deploy…   
Well, they are right, but Microservices is not just having small applications talking to each others. It’s a way of thinking your infrastructure too. It’s also how your “simple” application expose metrics and logs, how you can track the state, how you can control the flow between your services and how you manage errors.

So what can Istio add to this Microservice world ?

Istio is an implementation of a Service Mesh !
> Whaaaaaat ? Service Mesh ? we already have Kubernetes API, we don’t need a “Mesh” do we ?

Well, yes you do.   
I won’t explain all the benefits of using it, you’ll find enough docs online. but in few words, a Service Mesh is the layer that gives knowledge of others services to all your services.   
In fact, it also enforce all the “Microservices” best practices, like adding traffic and error metrics, add support to OpenTracing (Zipkin og Jaegger), allow control of retries, canary deployments, … well, read [Istio doc](https://istio.io/docs/concepts/) !

So, back to the topic…

### Prerequisits

*   a running Kubernetes Cluster
version 1.7+ recommended
*   one or many DNS domain names
*   Istio installed in your cluster with a working Ingress Controler
*   the DNS domain names from above configured to point to the Istio Ingress IP

### SSL

**SSL** is security (well, sort of), but it’s usually the last thing implemented in software. Why ? Well, it used to be “hard”, but I see no reasons now. [Let’s Encrypt] (https://letsencrypt.org/how-it-works/)created a new paradigm where it’s DAMN so easy to create valide SSL certificates using an API call (protocol is called ACME… ). It offers you 3 ways to validate you’re the owner of the domain. using DNS, a “secret token” using HTTP or the, well, the 3rd solution is not available anymore as it proved to be insecure.  
So, you set up your DNS with a special TXT record that Let’s Encrypt gave you, or you put it inside your web root path (like /.well-known/acme-challenge/xxx) and Let’s Encrypt validate it. This is really simplified, but it’s almost that.

Some devs decided to implement the ACME protocol directly inside the application. That’s the decision the guys from [Traefik](https://traefik.io/) took. [Caddy](https://caddyserver.com/) also did something similar with “plugins”.   
It’s cool because you just have to define your vhost and the application take care of gathering and renewing the certificates.

Sadly, Istio (and the underlying Envoy proxy) did not. And that’s the point of this blog post !

### Cert-Manager

Many folks got to the idea that, if not every software can implement the ACME protocol, we still need a tool to manage (like request, renew, deprecate) SSL certificates. That’s why LEGO was created. Then Kube-LEGO for kubernetes, then.. and finaly, they almost all agree to put everything inside [Cert-Manager](https://github.com/jetstack/cert-manager) !

Cert-Manager come with a helm chart so it’s quite easy to deploy… just follow the doc, but it’s like :

**[update]**  
There is now an [official Helm Chart for Cert-Manager](https://github.com/kubernetes/charts/tree/master/stable/cert-manager), you don’t need to `git clone` , just do the `helm install` .
```bash
git clone https://github.com/jetstack/cert-manager
cd cert-manager
# check out the latest release tag to ensure we use a supported version of cert-manager
git checkout v0.2.3
helm install \
  --name cert-manager \  
  --namespace kube-system* \  
  --set ingressShim.extraArgs='{--default-issuer-name=letsencrypt-prod,--default-issuer-kind=ClusterIssuer}' \  
  contrib/charts/cert-manager
```

This commands will start a Cert-Manager pod in the kube-system Namespace.

I used the configuration line `--default-issuer-kind=ClusterIssuer` so I can create my issuers only once.
> an Issuer whaaaat ?

Here’s how it’s working :

*   you create an Issuer config which tels the Cert-Manager how to use the ACME API (you will usualy have only 2, staging and prod)
*   you create a Certificate definition telling which domains need SSL
*   Cert-Manager request the certificates for you

So, let’s create the issuers. As I’m creating ClusterIssuers, I don’t care of a particular Namespace :
```yaml
apiVersion: certmanager.k8s.io/v1alpha1  
kind: ClusterIssuer  
metadata:  
  name: letsencrypt-prod  
  namespace: kube-system  
spec:  
  acme:  
    # The ACME server URL  
    server: https://acme-v01.api.letsencrypt.org/directorr
    # Email address used for ACME registration  
    email: me@domain.com  
    # Name of a secret used to store the ACME account private key  
    privateKeySecretRef:  
      name: letsencrypt-prod  
    # Enable the HTTP-01 challenge provider  
    http01: {}  
---  
apiVersion: certmanager.k8s.io/v1alpha1  
kind: ClusterIssuer  
metadata:  
  name: letsencrypt-staging  
  namespace: kube-system  
spec:  
  acme:  
    # The ACME server URL  
    server: https://acme-staging.api.letsencrypt.org/directory
    # Email address used for ACME registration  
    email: staging+me@domain.com  
    # Name of a secret used to store the ACME account private key  
    privateKeySecretRef:  
      name: letsencrypt-staging  
    # Enable the HTTP-01 challenge provider  
    http01: {}
```

Then
`kubectl apply -f certificate-issuer.yml`

Now you should have a working Cert-Manager. You need to create the config for your domains/services so the Istio Ingress can pick the right certificate.

### Istio Ingress

The Ingress is the front Web Proxy where you expose your services. It’s your edge… I say WEB PROXY as it only support HTTP/HTTPS for now. But let’s suppose you know everything about Ingress.

**[update]**  
This is not a real update but a precision, Ingree also support GRPC, which of course is HTTP/2.

The magic of Ingress is it’s implementation in the Kubernetes API. You create an Ingress Manifest and all your traffic is directed to the right Pod ! Magic ! Told you !

Well, in this case, it’s Dirty Magic !

For example, the Traefik Ingress binds port 80 and 443, manage the certificates, so you create an ingress for [www.mydomain.com](http://www.mydomain.com) and it just works, because it’s doing everything.

For Istio, as you’re using the Cert-Manager, there are some more steps. To be quick, here they are (as of 01/2018, it may change quickly) :

*   create a Certificate Request for domain [www.mydomain.com](http://www.mydomain.com)
*   Cert-Manager will pick this definition and create a pod, which is in fact a web server that can answer the ACME challenge ([Ingress-Shim](https://github.com/jetstack/cert-manager/blob/master/docs/user-guides/ingress-shim.md))
It will also create a Service and an HTTP Ingress so it is reacheable by the Lets Encrypt servers
*   The previous point will not work as you are using Istio Ingress, so you have to delete the `Service` and `Ingress`
*   Create your own Service that points to the Pod
*   Create your own Istio Ingress so the pod is accessible

Sounds crazy ?  
Well, it is, for now. And it’s EVEN WORSE :

When using Cert-Manager with Istio, you can only have ONE certificate for external services !   
So you have to add all the public DNS names to this one certificate !

So let’s implement it…

#### Certificate

Put this manifest in a file like _certificate-istio.yml_ :
```yaml
apiVersion: certmanager.k8s.io/v1alpha1  
kind: Certificate  
metadata:  
  name: istio-ingress-certs  
  namespace: istio-system  
spec:  
  secretName: istio-ingress-certs  
  issuerRef:  
    name: letsencrypt-staging  
    kind: ClusterIssuer  
  commonName: www.mydomain.com  
  dnsNames:  
  - www.mydomain.com  
  - mobile.mydomain.com  
  acme:  
    config:  
    - http01:  
        ingressClass: none  
      domains:  
      - www.mydomain.com  
      - mobile.mydomain.com
```

What we see here is :

*   we want a certificate
*   it will support 2 domains, _www.mydomain.com_ and _mobile.mydomain.com_
*   This Certificate Request is in the same Namespace as the Istio Ingress (istio-system)
*   it will use the HTTP-01 ACME Challenge
*   the certificate will be copied to a K8s Secret named _istio-ingress-certs ←_ this is SUPER IMPORTANT as the Istio Ingress (Envoy proxy) expect it.

then :
`kubectl apply -f certificate-istio.yml`

Once done, you will start seeing logs going through the cert-manager pod, as well as in the Istio Ingress… something like :
```plaintext
istio-ingress-7f8468bb7b-pxl94 istio-ingress [2018-01-23T21:01:53.341Z] "GET /.well-known/acme-challenge/xxxxxxx HTTP/1.1" 503 UH 0 19 0 - "10.20.5.1" "Go-http-client/1.1" "xxx" "www.domain.com" "-"  
istio-ingress-7f8468bb7b-pxl94 istio-ingress [2018-01-23T21:01:58.287Z] "GET /.well-known/acme-challenge/xxxxxx HTTP/1.1" 503 UH 0 19 0 - "10.20.5.1" "Go-http-client/1.1" "xxxx" "mobile.domain.com" "-"
```

This is because the Let’s Encrypt servers is polling for the validation token and your setup is not working yet. As of now your setup looks like that :

![image](images/2.jpeg#layoutTextWidth)


Now it’s time to remove the unwanted stuff created by Cert-Manager.   
Use your best K8s tool, like the Dashboard or kubectl, and remove the service and ingress from the _istio-system_ Namespace. They will be named like **cm-istio-ingress-certs-xxxx.** If you have many domain names in your certificate request, you will have more things to remove.

Also, don’t remove the pods !! (they will be re-created in case of error)

(as a reminder : kubectl -n istio-system delete ing cm-istio-ingress-certs-xxxx)

#### Services

Now that your setup is clean, you can go on and re-create the needed Services and Ingress.

You will need as many services as you have different domain names. In our case, 2. Here is the manifest :
```yaml
apiVersion: v1  
kind: Service  
metadata:  
  name: cert-manager-ingress-www  
  namespace: istio-system  
  annotations:  
    auth.istio.io/8089: NONE  
spec:  
  ports:  
  - port: 8089  
    name: http-certingr  
  selector:  
    certmanager.k8s.io/domain: www.mydomain.com  
---  
apiVersion: v1  
kind: Service  
metadata:  
  name: cert-manager-ingress-mobile  
  namespace: istio-system  
  annotations:  
    auth.istio.io/8089: NONE  
spec:  
  ports:  
  - port: 8089  
    name: http-certingr  
  selector:  
    certmanager.k8s.io/domain: mobile.mydomain.com
```

then
`kubectl apply -f certificate-services.yml`

You can then check your services. Each one should have one taget pod assigned.

Note here that the Service Name does not matter. It’s up to you to give a specific name so you will not mix up all your domains.

#### Ingress

It’s now time to create the Ingress so your “ACME Token Pods” are accessible from the outside.
```yaml
apiVersion: extensions/v1beta1  
kind: Ingress  
metadata:  
  annotations:  
    kubernetes.io/ingress.class: istio  
    certmanager.k8s.io/acme-challenge-type: http01  
    certmanager.k8s.io/cluster-issuer: letsencrypt-staging  
  name: istio-ingress-certs-mgr  
  namespace: istio-system  
spec:  
  rules:  
  - http:  
      paths:  
      - path: /.well-known/acme-challenge/.*  
        backend:  
          serviceName: cert-manager-ingress-www  
          servicePort: http-certingr  
    host: www.mydomain.com  
  - http:  
      paths:  
      - path: /.well-known/acme-challenge/.*  
        backend:  
          serviceName: cert-manager-ingress-mobile  
          servicePort: http-certingr  
    host: mobile.mydomain.com
```

Again, we have a few things to note here :

*   ingress is in the same Namespace as the Certificate, Services and Ingress
*   ingress Class is _Istio_ (obviously)
*   we are using the _staging_ issuer (remember the first step when we created the Issuers)
Depending wether you created an `Issuer` or a `ClusterIssuer` your have to use the right annotation. Documentation is in the [Ingress-Shim](https://github.com/jetstack/cert-manager/blob/master/docs/user-guides/ingress-shim.md) project
*   we must create an HTTP rule for each domain
*   the _backend/serviceName_ must match the services we created in the previous step, as well as the domain name, so :
_www.mydomain.com_ → serviceName _cert-manager-ingress-www_ → pod _cm-istio-ingress-certs-xxx_ where the label _certmanager.k8s.io/domain =_ [_www.mydomain.com_](http://www.mydomain.com)

again :
`kubectl apply -f certificate-ingress.yml`

And that’s it !

Checking the Istio-Ingress logs, you should see a couple of _“GET /.well-known/acme-challenge/xxx HTTP/1.1” 200_

### Sample application

I used a sample application to validate my setup is working:
```yaml
apiVersion: v1  
kind: Service  
metadata:  
  name: helloworld-v1  
  labels:  
    app: helloworld  
    version: v1  
spec:  
  ports:  
  - name: http  
    port: 8080  
  selector:  
    app: helloworld  
    version: v1  
---  
apiVersion: v1  
kind: Service  
metadata:  
  name: helloworld-v2  
  labels:  
    app: helloworld  
    version: v2  
spec:  
  ports:  
  - name: http  
    port: 8080  
  selector:  
    app: helloworld  
    version: v2  
---  
apiVersion: extensions/v1beta1  
kind: Ingress  
metadata:  
  annotations:  
    kubernetes.io/ingress.class: istio  
    kubernetes.io/ingress.allow-http: "false"  
  name: istio-ingress-https  
spec:  
  tls:  
    - secretName: istio-ingress-certs  
  rules:  
  - http:  
      paths:  
      - path: /.*  
        backend:  
          serviceName: helloworld-v1  
          servicePort: 8080  
    host: www.mydomain.com
  - http:  
      paths:  
      - path: /.*  
        backend:  
          serviceName: helloworld-v2  
          servicePort: 8080  
    host: mobile.mydomain.com  
---  
apiVersion: extensions/v1beta1  
kind: Ingress  
metadata:  
  annotations:  
    kubernetes.io/ingress.class: istio  
  name: istio-ingress-http  
spec:  
  rules:  
  - http:  
      paths:  
      - path: /.*  
        backend:  
          serviceName: helloworld-v1  
          servicePort: 8080  
    host: www.mydomain.com
  - http:  
      paths:  
      - path: /.*  
        backend:  
          serviceName: helloworld-v2  
          servicePort: 8080  
    host: mobile.mydomain.com  
---  
apiVersion: v1  
kind: ReplicationController  
metadata:  
  labels:  
    app: helloworld  
    version: v1  
  name: helloworld-v1  
spec:  
  replicas: 1  
  template:  
    metadata:  
      labels:  
        app: helloworld  
        version: v1  
    spec:  
      containers:  
        - image: "kelseyhightower/helloworld:v1"  
          name: helloworld  
          ports:  
            - containerPort: 8080  
              name: http  
---  
apiVersion: v1  
kind: ReplicationController  
metadata:  
  labels:  
    app: helloworld  
    version: v2  
  name: helloworld-v2  
spec:  
  replicas: 1  
  template:  
    metadata:  
      labels:  
        app: helloworld  
        version: v2  
    spec:  
      containers:  
        - image: "kelseyhightower/helloworld:v2"  
          name: helloworld  
          ports:  
            - containerPort: 8080  
              name: http
```

We must thanks Kelsy Hightower, again, for his HelloWorld example app 🙏

then:
`kubectl -n default apply -f helloworld.yml`

Note you will need one Ingress for all you HTTPS domains, and one for the HTTP… Only the HTTPS is represented here :

![image](images/3.jpeg#layoutTextWidth)


Cert-Manager should remove the Token-Exchange pods in the istio-system namespace after the validation is done. Yes, once the Cert-Manager agreed with the Let’s Encrypt servers, they exchange a permanent key that is used for renewal. No need of the pods, and even Services and Ingress, at least if your are sure you will not need to add or change something in the certificate.

### Updating the Certificate

When updating the certificate, I suggest to first create the right `Service` for it. Then update the `Ingress` to send traffic to the right service.  
Finally, update your `Certificate` definition and add the new domain name.

Cert-Manager will create a new `ingress` and `service` that you will have to delete. Everything else will take place by itself. Wait a few seconds for `Istio-Ingress` to reload it’s certificate and you’re good to `curl` !

### Conclusion

While I find it pretty ugly right now, it’s working…   
If you need to update your certificate or add a new domain name, you will have to update your certificate definition so the whole process can start over. This is really a pain and certainly a LOT harder than having it fully integrated like with Traefik or Caddy. I’m sure this will change quickly though.

I would like to thank [Laurent Demailly](https://github.com/ldemailly) for it’s work on this. See Istio Issue [868] (https://github.com/istio/istio.github.io/issues/868)for more details and discussion. He’s working on a sample application deployment, Fortio, using Istio + TLS and he’s the one who inspired and help me getting all this to work.

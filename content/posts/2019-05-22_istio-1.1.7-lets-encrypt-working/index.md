---
title: "Istio 1.1.7 + Let’s Encrypt : WORKING !"
author: "Prune"
date: 2019-05-22T13:01:42.927Z
lastmod: 2023-11-30T22:15:08-05:00

description: ""

subtitle: "It’s been almost a year since I first wrote about using Let’s Encrypt SSL Certificates with Istio, 0.8.0 at this time.
Then I blogged…"

image: "images/1.png" 
images:
 - "images/1.png"

tags: ["devops", "servicemesh", "kubernetes"]

aliases:
    - "/istio-1-1-7-lets-encrypt-working-9100cea9f503"

---

![image](images/1.png#layoutTextWidth)


It’s been almost a year since I first wrote about [using Let’s Encrypt SSL Certificates with Istio, 0.8.0](https://medium.com/@prune998/istio-0-8-0-envoy-cert-manager-lets-encrypt-for-tls-d26bee634541) at this time.  
Then [I blogged again](https://medium.com/@prune998/istio-1-0-2-envoy-cert-manager-lets-encrypt-for-tls-certificate-merge-7a774bff66c2) when Istio 1.0.2 came out. I had to build an Operator, [Cert-Merge](https://github.com/prune998/certmerge-operator), to allow to merge all the SSL certificates created in many Secrets by Cert-Manager into ONE single secret that Istio’s Gateway could use.

While building this Operator was cool, and I learnt a lot by this time, I knew this was a temporary solution, a highly insecure one.

Well, I’m happy to tell you that THIS TIME IS OVER !

Since Istio 1.1.x (maybe 1.1.5) there is a new feature called **SDS**. This stands for Secret Delivery Service and allows Istio components to receive SSL Certificates by the API.

### Setup

You have to upgrade your Istio to one of the latest, which is always a good thing anyway. As of today, go for 1.1.7.

Doing this, you have to ENABLE the SDS component of the Gateway.

This is done by adding this line to your Helm generation :

_gateways.istio-ingressgateway.sds.enabled=true_

Here is what I use to generate the manifests :
```bash
helm template install/kubernetes/helm/istio - name istio  
- set tracing.enabled=false  
- set ingress.enabled=false  
- set gateways.istio-ingressgateway.enabled=true  
- set gateways.istio-ingressgateway.sds.enabled=true  
- set gateways.istio-egressgateway.enabled=true  
- set servicegraph.enabled=false  
- set kiali.enabled=true  
- set kiali.dashboard.jaegerURL=[https://jaeger.](https://jaeger.%7B%7B)local.domain  
- set kiali.prometheusAddr=[http://prometheus-k8s.monitoring:9090](http://prometheus-k8s.monitoring:9090)  
- set kiali.dashboard.grafanaURL=[http://grafana.monitoring:3000](http://grafana.monitoring:3000)  
- set prometheus.enabled=false  
- set grafana.enabled=false  
- set global.proxy.autoInject=disabled  
- set global.k8sIngressSelector=ingressgateway  
- set global.k8sIngressHttps=false  
- set global.tracer.zipkin.address=zipkin.monitoring:9411  
- set global.outboundTrafficPolicy.mode=REGISTRY_ONLY  
- set galley.enabled=true  
- set global.proxy.accessLogFile="/dev/stdout"  
- namespace istio-system > install/kubernetes/generated.yaml
```

### Usage

Now your Istio mesh is working, you can create gateways that use SDS to grab the SSL certificate.

You can check the Istio’s doc at [https://istio.io/docs/examples/advanced-gateways/ingress-certmgr/](https://istio.io/docs/examples/advanced-gateways/ingress-certmgr/)

This official Doc is using an **Ingress** resource instead of a plain **Gateway** + **VirtualService**… I don’t know why it’s done this way, and I thought using Ingress resources with Istio was deprecated. If anyone have informations on that, please comments.

Here is what I did for testing :

#### Certificate

Create your certificate as usual… something like :
```yaml
apiVersion: certmanager.k8s.io/v1alpha1  
kind: Certificate  
metadata:  
  name: cert-hello.mydomain.com  
  namespace: istio-system  
spec:  
  commonName: hello.mydomain.com  
  dnsNames:  
  - hello.mydomain.com  
  issuerRef:  
    kind: ClusterIssuer  
    name: letsencrypt-prod  
  secretName: cert-hello.mydomain.com
```

This will create a new TLS secret named **cert-hello.mydomain.com**

#### Gateway

This is the fun part. In your Gateway, instead of giving the path to your key/cert, just set the keyword “SDS” :
```yaml
apiVersion: networking.istio.io/v1alpha3  
kind: Gateway  
metadata:  
  name: gw-hello-mydomain-com  
  namespace: default  
spec:  
  selector:  
    istio: ingressgateway  
  servers:  
  - hosts:  
    - hello.mydomain.com  
    port:  
      name: https-443-hello-mydomain-com ← this must be unique  
      number: 443  
      protocol: HTTPS  
    tls:  
      credentialName: cert-hello.mydomain.com ← the certificate name you created above  
      mode: SIMPLE  
      privateKey: sds  
      serverCertificate: sds
```

And VOILA !

Well, you have to setup your VirtualService, Service and Deployment, but this is as usual, nothing new….

Enjoy !

#### EDIT 1

You **NEED** to keep the _Secret_ holding the SSL _Certificate_ in the **same _Namespace_** as your Istio Ingress Gateway. (see [github issue here](https://github.com/istio/istio/issues/6486#issuecomment-495606248))  
You can still put your _Gateway_/_VirtualService_ definitions where you want.

#### EDIT 2

There is a presentation on that at KubeCon Europe 2019 (Spain) : [https://www.youtube.com/watch?v=QlQyqCaTOh0](https://www.youtube.com/watch?v=QlQyqCaTOh0)

#### EDIT 3

Don’t use the _istio-ingressgateway-certs_ Secret for SDS.  
As stated by Vladimir Pouzanov :
> SDS explicitly filters out (Secrets with) prefixes of “istio” and “prometheus”   
> :-) of course it’s not documented.   
> It will also skip secrets that have a field named “token” (commonly the service accounts).

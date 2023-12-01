---
title: "Istio 0.8.0 (Envoy) + Cert-Manager + Let’s Encrypt for TLS"
author: "Prune"
date: 2018-06-26T18:57:13.220Z
lastmod: 2023-11-30T22:05:28-05:00

description: ""

subtitle: "A few months back I wrote a blog post on how to use Cert-Manager to provide SSL certificates for Istio."

image: "/posts/2018-06-26_istio-0.8.0-envoy-certmanager-lets-encrypt-for-tls/images/1.jpeg" 
images:
 - "/posts/2018-06-26_istio-0.8.0-envoy-certmanager-lets-encrypt-for-tls/images/1.jpeg"
 - "/posts/2018-06-26_istio-0.8.0-envoy-certmanager-lets-encrypt-for-tls/images/2.png"


aliases:
    - "/istio-0-8-0-envoy-cert-manager-lets-encrypt-for-tls-d26bee634541"

---

![image](/posts/2018-06-26_istio-0.8.0-envoy-certmanager-lets-encrypt-for-tls/images/1.jpeg#layoutTextWidth)


A few months back I wrote a blog post on [how to use Cert-Manager to provide SSL certificates for Istio](https://medium.com/@prune998/istio-envoy-cert-manager-lets-encrypt-for-tls-14b6a098f289).

Since then, Istio reached version 0.8.0 and changed the Ingress API to a new version using [Kubernetes Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/). It is called the Route Rules v1alpha3.

### What have changed ?

Istio had a great blog post about it [here](https://istio.io/blog/2018/v1alpha3-routing/). To sum it up quickly, instead of using Ingress manifests with annotations, you now have to define a Gateway, which defines the **Layer 4** configuration, and a VirtualService which is the **Layer 6/7** part.

You can go strait to the docs [here](https://istio.io/docs/tasks/traffic-management/ingress/) and the reference [here](https://istio.io/docs/reference/config/istio.networking.v1alpha3/).

So, what does that implies to our old (pre 0.8.0) setup ?   
Well, let’s start from scratch and we’ll see…

### Setup Istio

Setting up Istio is almost straightforward… do it the way you want, using the Helm chart with Tiller, without it or go with the Demo manifest that you may have (or not) depending on where you got Istio from.

My personal flavour is to use the Helm binary to create a static Deployment Manifest and use Kubectl to apply it. It goes something like :
`helm template install/kubernetes/helm/istio --name istio --set tracing.enabled=false --set ingress.enabled=false --set servicegraph.enabled=false --set prometheus.enabled=false --set global.proxy.policy=disabled --set grafana.enabled=false --namespace istio-system &gt; install/kubernetes/generated.yaml``kubectl create namespace istio-system``kubectl apply -n istio-system -f install/kubernetes/generated.yaml`

### Setup Cert-Manager

It’s almost the same for cert-manager. Just clone it and apply the Manifest :
`git clone [https://github.com/jetstack/cert-manager.git](https://github.com/jetstack/cert-manager.git)  
cd [cert-manager](https://github.com/jetstack/cert-manager.git)  
kubectl apply -f cert-manager/contrib/manifests/cert-manager/with-rbac.yaml`

If it goes well you should see a pod started :
`kubectl -n cert-manager get pods``NAME                            READY     STATUS    RESTARTS   AGE  
cert-manager-794b55b96d-9b9zh   1/1       Running   0          3h`

### Setup AWS Route53

Since the beginning my DNS was hosted on AWS using Route53. Still, my previous blog post was about using the HTTP01 provider, which requires to setup a website which can answer to the Let’s Encrypt handshake.

Cert-Manager is not (yet) compatible with how Istio 0.8.0 setup the Ingress. So it would be a real pain to use the HTTP provider again.

I decided to use the DNS01 provider, which is supported by both Cert-Manager and AWS Route53, and is far easier to setup that I thought.

#### Setup Policy

go to the AWS Dashboard -&gt; IAM -&gt; policies ([https://console.aws.amazon.com/iam/home?#/policies](https://console.aws.amazon.com/iam/home?#/policies)) and create a Policy like :
`{  
    &#34;Version&#34;: &#34;2012-10-17&#34;,  
    &#34;Statement&#34;: [  
        {  
            &#34;Effect&#34;: &#34;Allow&#34;,  
            &#34;Action&#34;: [  
                &#34;route53:GetHostedZone&#34;,  
                &#34;route53:ListHostedZones&#34;,  
                &#34;route53:ListHostedZonesByName&#34;,  
                &#34;route53:GetHostedZoneCount&#34;,  
                &#34;route53:ChangeResourceRecordSets&#34;,  
                &#34;route53:ListResourceRecordSets&#34;,  
                &#34;route53:GetChange&#34;  
            ],  
            &#34;Resource&#34;: &#34;*&#34;  
        }  
    ]  
}`

Here is mine :

![image](/posts/2018-06-26_istio-0.8.0-envoy-certmanager-lets-encrypt-for-tls/images/2.png#layoutTextWidth)


#### Setup User

Go to the `user` tab and create a new user, applying the above policy to it. Select the **Programmatic access checkbox.** On the last page you will find the Access Key and the Secret Key. Note them down.

You will need to set the Secret Key in a Kubernetes Secret so the Cert-Manager can use it. This can be done by a single shell command using, again, kubectl :
`kubectl -n cert-manager create secret generic prod-route53-credentials-secret --from-literal=secret-access-key=&lt;your secret key here&gt;`

This way the key is securely usable by your K8s cluster.

### Create your certificate

As before, you need to create an Issuer and a Certificate. In this example we’ll use a ClusterIssuer, which is an Issuer not tied to a specific Namespace. This way you can create some certificates in any namespace. Stick to regular Issuers if you need more control.

#### ClusterIssuer

This ClusterIssuer is using the `acme-v02` API.

Set the `privateKeySecretRef` to the name of the secret you want Cert-Manager to use. It have to be a new secret as it will be used to elect the `master` Cert-Manager instance in case you start many of them.

`secretAccessKeySecretRef` is the name of the secret we just created before.
`apiVersion: certmanager.k8s.io/v1alpha1  
kind: ClusterIssuer  
metadata:  
  name: letsencrypt-prod  
  namespace: cert-manager  
spec:  
  acme:  
    server: [https://acme-v02.api.letsencrypt.org/directory](https://acme-v02.api.letsencrypt.org/directory)  
    email: [m](mailto:sthomas@moncoyote.com)e@ici.com  
    privateKeySecretRef:  
      name: letsencrypt-prod  
    dns01:  
      providers:  
        - name: aws-dns-prod  
          route53:  
            region: ca-central-1  
            accessKeyID: &lt;your access key from AWS&gt;  
            secretAccessKeySecretRef:  
              name: prod-route53-credentials-secret  
              key: secret-access-key`

#### Certificate

You will need to create a `Certificate Manifest` so Cert-Manager can perform the request using the ACME API.

Before that, ensure that all the domain names you are requesting for are properly setup in your DNS server, in this cas, route53.

Here is where we also **have a choice to make**.

Beeing an admin (sysops, devops or SRE, you name it) for 20 years now, I would go to create an SSL certificate for every website, ie, for every FQDN that serves a different purpose. This way it’s easier to manage, expire (revoke) or split.

In fact, two things here almost prevent us from doing so :

*   using Let’s Encrypt you programatically manage your certificates so you don’t have to care how you renew or revoke them (almost) as Cert-Manager will do that for you.
*   Istio does not (really) support Ingresses with multiple certificates. To be clearer, in Istio version 0.8.0 and the new IngressGateway, only one `Kubernetes Secret` is mounted inside the IngressGateway Pod. 
Someone started a discussion about that [there](https://github.com/istio/istio/issues/6486#issuecomment-400367378), which I commented.

So, for now, I recommend going with only one Certificate with all your FQDNs in it. Like :
`apiVersion: certmanager.k8s.io/v1alpha1  
kind: Certificate  
metadata:  
  name: domain-ingress-certs  
  namespace: istio-system  
spec:  
  acme:  
    config:  
    - dns01:  
        provider: aws-dns-prod  
      domains:  
      - my.domain.com  
      - subnet.domain.com  
      - www.otherdomain.com  
  commonName: my.domain.com  
  dnsNames:  
  - my.domain.com  
  - subnet.domain.com  
  - www.otherdomain.com  
  issuerRef:  
    kind: ClusterIssuer  
    name: letsencrypt-prod  
  secretName: istio-ingressgateway-certs`

Let’s break this down :

*   the `Certificate` will be created in the secret called `istio-ingressgateway-certs` in the namespace `istio-system`. This is needed as the Istio Ingress Gateway is looking for this specific secret in it’s own namespace. DON’T MESS WITH IT, the `secretName` IS HARDCODED ! (see comments :) )
*   the issuer is named `letsencrypt-prod` and its kind is `ClusterIssuer`
*   we are using the DNS-01 `provider` which is called `aws-dns-prod`, as defined, again, in the `ClusterIssuer`
*   the 3 domains will use the DNS-01 challenge, as they are all listed under the `domains` list of the `dns01` provider. We could also have decided to use another provider for some of them… This is really agile !
*   The SSL certificate will have `my.domain.com` as CommonName and will also be valid for all the 3 domain names listed under the `dnsNames` line.

When you push that using `kubectl`, Cert-Manager will connect to your AWS account and create some TXT records that will be used by Let’sEncrypt to ensure that you own the right to update the DNS.   
They will look like :
`_acme-challenge.my.domain.com TXT &#34;some value here&#34;`

Once the DNS propagated and the Domain Ownership validated, Cert-Manager will create your **istio-ingressgateway-certs** secret, with two files in it : `tls.crt`and `tls.key`

### Configuring the Istio Ingress Gateway

The final step for this setup is to configure Istio to use use the certificate.

With the new API starting from version 0.8.0, you have two resources to setup : the Gateway and the Virtual Service.

#### Gateway

The gateway is your OSI Layer 4 configuration. It tells Istio (Envoy) to listen on a port and, if needed, activate SSL. (ok, ssl is not layer4, but…well, it’s complicated :) )
`apiVersion: networking.istio.io/v1alpha3  
kind: Gateway  
metadata:  
  name: web-gateway  
  namespace: test  
spec:  
  selector:  
    istio: ingressgateway  
  servers:  
  - hosts:  
    - my.domain.com  
    port:  
      name: http  
      number: 80  
      protocol: HTTP  
  - hosts:  
    - my.domain.com  
    - my.domain.com:443  
    - subnet.domain.com  
    - subnet.domain.com:443  
    port:  
      name: https  
      number: 443  
      protocol: HTTPS  
    tls:  
      mode: SIMPLE  
      privateKey: /etc/istio/ingressgateway-certs/tls.key  
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt`

So, we define here a `Gateway` name `web-gateway`, answering `my.domain.com` on both HTTP and HTTPS and `subnet.domain.com` and HTTPS.  
For HTTPS, I had to double the DNS names with the `:port` extension. I still don’t know if it’s a bug or a feature, but I opened another issue for that [here](https://github.com/istio/istio/issues/6469).

As a side note here, DON’T create another gateway for port 443 or 80 in the cluster, as they will both try to bind the same IP/port. Instead, either :

*   add more FQDN to the domain list or
*   create another `server` entry and use the same port

### UPDATE 2018/08/22 !

I don’t know if I was mistaken or if something changed with Istio 1.0.0, but you CAN create multiple gateways on the same port. Just use different names and use the SAME certificate file, as Istio IngressGateway still only use one Secret for now.  
Ex :
`apiVersion: networking.istio.io/v1alpha3  
kind: Gateway  
metadata:  
  name: gateway-mydomain  
  namespace: test  
spec:  
  selector:  
    istio: ingressgateway  
  servers:  
  - hosts:  
    - my.domain.com  
    - my.domain.com:443  
    port:  
      name: https-mydomain  
      number: 443  
      protocol: HTTPS  
    tls:  
      mode: SIMPLE  
      privateKey: /etc/istio/ingressgateway-certs/tls.key  
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt  
---  
apiVersion: networking.istio.io/v1alpha3  
kind: Gateway  
metadata:  
  name: gateway-otherdomain  
  namespace: test  
spec:  
  selector:  
    istio: ingressgateway  
  servers:  
  - hosts:  
    - other.domain.com  
    - other.domain.com:443  
    port:  
      name: https-otherdomain  
      number: 443  
      protocol: HTTPS  
    tls:  
      mode: SIMPLE  
      privateKey: /etc/istio/ingressgateway-certs/tls.key  
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt`

#### VirtualService

In fact, we’ve done everything we needed to get an SSL cert via Let’s Encrypt.  
The VirtualService is the layer 6/7 configuration, which will split the traffic to your Kubernetes Services.

Since we’re here anyway, let me show you one possible config :
`apiVersion: networking.istio.io/v1alpha3  
kind: VirtualService  
metadata:  
  name: domain-http  
  namespace: test  
spec:  
  gateways:  
  - web-gateway  
  hosts:  
  - my.domain.com  
  - my.domain.com:443  
  http:  
  - match:  
    - uri:  
        prefix: /  
    route:  
    - destination:  
        host: my-http-service  
        port:  
          number: 1080`

You can also create another one for the subdomain if you want it to go to another website :
`apiVersion: networking.istio.io/v1alpha3  
kind: VirtualService  
metadata:  
  name: subnet-http  
  namespace: test  
spec:  
  gateways:  
  - web-gateway  
  hosts:  
  - subnet.domain.com  
  - subnet.domain.com:443  
  http:  
  - match:  
    - uri:  
        prefix: /  
    route:  
    - destination:  
        host: subnet-http-service  
        port:  
          number: 1081`

### Conslusion

I find this solution far better than the previous one with HTTP-01 challenge. No more ingress or services to remove.

Of course this implies using a supported DNS provider, as of today, one of Google cloud, AWS Route53, Clouflare, Akamai ([https://cert-manager.readthedocs.io/en/latest/reference/issuers/acme/dns01.html#supported-dns01-providers](https://cert-manager.readthedocs.io/en/latest/reference/issuers/acme/dns01.html#supported-dns01-providers))

Also, as mentioned, you have to use only one certificate for all your domains. Now that Let’s Encrypt also support star certificates (`*.domain.com` ) there may some good reasons to do so, but still I don’t like it.

Also, as of today (20180626), I see no way for the Istio IngressGateway to automatically reload it’s configuration when the certificate, so the `Kubernetes Secret`, changes.   
From my point of view, the `Istio Pilot` service should monitor the secret and send a kind of `SIGHUP` signal the the Ingressgateway Envoy when needed…

Stay tuned :)

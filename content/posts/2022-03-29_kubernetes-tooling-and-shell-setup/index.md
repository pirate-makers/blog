---
title: "Kubernetes tooling and shell setup"
author: "Prune"
date: 2022-03-29T16:54:21.215Z
lastmod: 2023-11-30T22:23:45-05:00

description: ""

subtitle: "How to be productive fast with Kubernetes"

image: "images/2.png" 
images:
 - "images/1.png"
 - "images/2.png"
 - "images/3.jpg"
 - "images/4.png"
 - "images/5.png"
 - "images/6.jpg"
 - "images/7.jpg"
 - "images/8.jpg"

tags: ["devops", "gitops", "kubernetes", "tooling", "productivity"]

aliases:
    - "/kubernetes-tooling-and-shell-setup-f48f30bdc727"

---

_How to be productive fast with Kubernetes_

![image](images/1.png#layoutTextWidth)


**Updates**:  
- 20220410: added some Dasel examples  
- 20220410: I’ll be giving a talk about this post April the 12th at the Canadian CNCF and Kubernetes meetup: [https://lnkd.in/ep9yaj6Z](https://lnkd.in/ep9yaj6Z)  
- 20220412: add commands to build a patched kubecolor  
- 20220413: [recording of the K8s/CNCF CANADA Meetup talk](https://www.youtube.com/watch?v=lmefhvXYnnI)

A ton of writing had been done about how to setup your shell and all the tooling that goes with it to use Kubernetes.   
Well, I think it needed another one blog post (and talk) about it !

This one is focussing on Apple Mac setup, and specifically ZSH setup, but beside few small changes, it should work the same for Bash or even on Linux.

It’s also a primer, not an advanced setup. But it should contain all the basics so a new user, or a developper, can get going quickly.

Well, do whatever you want with this blog post. I’m writing it as a reference for myself 🙏

### What is Kubectl ?

Come on, we all know that: _kubectl_ is the CLI to interact with the K8s API !

![image](images/2.png#layoutTextWidth)


_kubectl_ is taking your human-readable requests and translate them to a REST call against the Kubernetes API server.

Then, the server answer with some information, mostly JSON. Usually, _kubectl_ dump that in a human-readable way, or, quite often, in YAML, because we all love YAML !

Here, _kubectl_ is usually doing the minimum, and things quickly gets messy when you have a large cluster with hundreds of resources.

Because of that, a bunch of talented people started building tooling around _kubectl_ and the K8s API so we can spend less time reading _kubectl_ outputs and spend more time doing the important stuff: snacking, watching Hell’s Kitchen show and plowing snow (last one is true when you live in Quebec City, QC, Canada)

OK, let’s go now.

### Kubectl

Of course it all starts with _kubectl_… it’s up to you, there’s too many ways to intall it to give them all here ! _gcloud_ can install one, brew, curl… find your own way !

Here’s one with _curl:_
```bash
curl -LO "[https://dl.k8s.io/release/$(curl](https://dl.k8s.io/release/$%28curl) -L -s [https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl](https://dl.k8s.io/release/stable.txt%29/bin/darwin/amd64/kubectl)"  
chmod 755 kubectl
```

Or using Brew…
`brew install kubectl`

And here’s a Linux one (don’t expect more Linux example):
```bash
curl -LO "[https://dl.k8s.io/release/$(curl](https://dl.k8s.io/release/$%28curl) -L -s  
[https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl](https://dl.k8s.io/release/stable.txt%29/bin/linux/amd64/kubectl)"  
chmod 755 kubectl
```

Always try to use the same _kubectl_ version as the server you are targeting, or +/- one version.   
BTW, this _kubectl version_ command is a great way to check for your server’s version:

```bash
kubectl version
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.2"}
Server Version: version.Info{Major:"1", Minor:"20+", GitVersion:"v1.20.9-gke.1001"}
WARNING: version difference between client (1.22) and server (1.20) exceeds the supported minor version skew of +/-1
```

### Kubecolor

[KubeColor](https://github.com/hidetatz/kubecolor) is used to Colourize your _kubectl_ output. It makes reading all those lines of resources easier !

Install:
```bash
brew install dty1er/tap/kubecolor
# add in your .zshrc  
alias k=kubecolor
```

Result:

![image](images/3.jpg#layoutTextWidth)


Until the [PR 86](https://github.com/hidetatz/kubecolor/pull/86) is merged, you may reach an issue when using the **ctx** or **ns** commands, where the whole output is displayed in yellow and hiding the selected default value. In the meantime, clone my own fork and build the binary yourself:
```bash
git clone [git@github.com](mailto:git@github.com):prune998/kubecolor.git
git checkout prune/ctx-no-color
cd cmd/kubecolor && go build && cp kubecolor /usr/local/bin
```

### ZSH Setup

Alias, Completion, Tooling… in your .zshrc: use **k** instead of **kubectl** and reclaim 1s of your life at every command!
```bash
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
alias k=kubecolor  
source <(kubectl completion zsh)
complete -F __start_kubectl k
compdef kubecolor=kubectl
source <;(stern --completion=zsh)
ulimit -n 2048          # kubectl opens one cnx (file) per resource

# gcloud  
source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

# AWS  
complete -C '/usr/local/bin/aws_completer' aws
```

#### ZSH customization:

*   [Oh-My-ZSH](https://ohmyz.sh/) : lots of features in your shell
Use plugins !!
```bash
plugins=(brew kubectl git python tmux vault terraform)
```

* Themes
  - [Agnoster ZSH theme](https://github.com/agnoster/agnoster-zsh-theme): better prompt using Powerline Fonts
  - [PowerLevel10k](https://github.com/romkatv/powerlevel10k): emphasizes speed, flexibility and out-of-the-box experience
* Fonts
  - Powerline Font: recommend [NerdFonts](https://www.nerdfonts.com/) Inconsolata or Firacode

Here’s an example prompt when customizing all this. Of course, it’s possible to add more Kubernetes related stuff in the prompt, but it’s going to get messy quickly:

![image](images/4.png#layoutTextWidth)


### Krew

[_Krew_](https://krew.sigs.k8s.io) is a plugin manager for _kubectl_.  
Install: [https://krew.sigs.k8s.io/docs/user-guide/setup/install/](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)
```bash
kubectl krew list

PLUGIN  VERSION  
ctx     v0.9.4  
krew    v0.4.1  
ns      v0.9.4  
whoami  v0.0.36

kubectl krew search

NAME                            DESCRIPTION                                         INSTALLED  
access-matrix                   Show an RBAC access matrix for server resources     no  
blame                           Show who edited resource fields.                    no  
cert-manager                    Manage cert-manager resources inside your cluster   no  
ctx                             Switch between contexts in your kubeconfig          yes  
...
```

Kool Krew Plugins to have:

*   **ctx**: quick context ( current cluster ) changes
*   **ns**: quick current namespace changes
*   **whoami**: who the cluster thinks you are from your authentication
*   **who-can**: RBAC rules introspection

Example **ctx** usage to manage your contexts:
```bash
# list all the existing context, current one in yellow  
k ctx

arn:aws:eks:us-east-1:111111111111:cluster/eks-example  
gke-dv-st-cluster-1  
gke-dev_us-central1_test-gke-cluster

# change context “manually”  
kubectl config use-context gke-dev_us-central1_test-gke-cluster

# change the context using ctx  
k ctx gke-dev_us-central1_test-gke-cluster

# delete context (why not ?)  
k ctx -d gke-dv-st-cluster-1
```

Example using **ns** to change default namespace:
```bash
# List all namespaces, current NS in yellow (not in Medium blogs...)  
k ns
datadog-agents  
default         <----  
kube-public  
kube-system

# Set default NS by hand  
kubectl config set-context --current --namespace=kube-system

# Set default Namespace  
k ns kube-system
```

### Cloud provider setup

#### AWS

First, install the awscli:

```bash
curl "[https://awscli.amazonaws.com/AWSCLIV2.pkg](https://awscli.amazonaws.com/AWSCLIV2.pkg)" -o "AWSCLIV2.pkg"  
sudo installer -pkg AWSCLIV2.pkg -target /
```

Then, setup SSO login:
```bash
export AWS_DEFAULT_REGION=us-east-1  
export AWS_PAGER="" # prevent aws cli to auto-page = display inline  
export BROWSER=echo # Do not open a browser, let you choose which browser to open
complete -C '/usr/local/bin/aws_completer' aws # add that to .zshrc for completion

# remove dandling env variables  
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

# configure (may ask questions here)  
aws configure sso  
aws sso login --profile profile_xxxxxx  
export AWS_PROFILE=profile_xxxxxx
```

Configure _kubectl_ context to use your EKS cluster:
```bash
aws eks update-kubeconfig \   
    --region us-east-1    \  
    --name <cluster_name> \  
    --alias <friendly_name>
```

#### Google

Install Google CLI (gcloud):
```bash
brew install --cask google-cloud-sdk  
gcloud components install kubectl # Optional
gcloud init  
gcloud auth login
gcloud config set compute/region us-east1
```

Configure _kubectl_ to use your GKE cluster:
```bash
gcloud container clusters get-credentials <cluster> --project <project>
```

### Stern

[Stern](https://github.com/wercker/stern) allows you to tail **** the logs of **multiple pods** on Kubernetes and **multiple containers** within the pod.   
Each result is colour coded for quicker debugging.

Install:
```bash
brew install stern
stern -n my-namespace dv-oma
```

Stern will tail the logs of all pods matching _dv-oma_ as a pattern. There’s a ton of options to further filter what you want to display:

![image](images/5.png#layoutTextWidth)


### Kustomize

[Kustomize](https://kustomize.io/) is a Kubernetes native configuration management (templating)

*   Bundled with _kubectl_, but not all the features are available
*   Better install the full version for your CI/CD pipelines
*   Only output rendered YAML, you have to apply it later

Ex:
```bash
kubectl   kustomize --enable-alpha-plugins /path/to/kustomize/folder
kustomize build     --enable-alpha-plugins /path/to/kustomize/folder
```

Render and apply the _kustomization_:
```bash
kustomize build --enable-alpha-plugins /path/to/kustomize/folder | kubectl apply -f -
```

Kustomize requires a _kustomization.yaml_ file in the target folder, which link resources together, patch them, use generators to create new resources and plugins to patch/generate new yaml. Ex:
```yaml
# cat /path/to/kustomize/folder/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1  
kind: Kustomization
resources:  
  - my_resources_file.yaml  
  - ../base
patches:  
  - ./manifests/my_patch.yaml
generators:  
  - my_generator.yaml
```

### Kubernetes Dashboards

#### K9s

[K9s](https://github.com/derailed/k9s) — Kubernetes CLI To Manage Your Clusters In Style!

*   Open-Source
*   In your terminal, like top
*   CRUD operations on K8s resources
*   nothing to install server-side
*   lightweight

```bash
brew install k9s

k9s -n <namespace>      # To run K9s in a given namespace
k9s --context <context> # Start K9s in an existing KubeConfig context
k9s --readonly          # Start K9s in readonly mode - with all cluster modification  
                          commands disabled
```
![K9s](images/6.jpg#layoutTextWidth)


#### Lens

[Lens](https://k8slens.dev/) is the only IDE you’ll ever need to take control of your Kubernetes clusters (well, that’s what they say)

*   Launch on your own desktop, no server-side install
*   Include advanced config to reach remote clusters
*   Manage CustomResourceDefinitions (CRD)
*   Nice UI
*   Multi-cluster
![image](images/7.jpg#layoutTextWidth)


### VsCode extensions for Kubernetes

I’m sure there are a lot more than these, but I would consider these as essentials:

*   [Kubernetes](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools): Develop, deploy and debug Kubernetes applications
*   [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml): Language Support, with built-in Kubernetes syntax support
*   [Indent-Rainbow](https://github.com/oderwat/vscode-indent-rainbow): helper to better see Yaml indentations
![Indent-Rainbow](images/8.jpg#layoutTextWidth)


### Local Kubernetes

Here’s a minimal list of solutions to deploy a local Kubernetes cluster on your laptop:

#### Kind

*   [Kind](https://kind.sigs.k8s.io/) is a local K8s cluster
*   Official Kubernetes tool to create lightweight K8s clusters
*   Support ingress / LB (with some tuning)
*   Work with Docker and Podman (and rootless with some more sweat)
```bash
brew install kind
kind create cluster --help
```

#### K3s

[K3s](https://k3s.io/) is the Rancher take on local clusters. Both ARM64 and ARMv7 are supported

```bash
sudo k3s server &
# Kubeconfig is written to /etc/rancher/k3s/k3s.yaml  

sudo k3s kubectl get node
```

#### Minikube

[Minikube](https://k3s.io/) is certainly the oldest of all. Still supported, well documented and support different container runtimes, so you can get rid of Docker !
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
minikube start
```

### Bonus tooling

Here’s few more tools to help working with Kubernetes resources (and YAML)

#### KubePug

Use [KubePug](https://github.com/rikatz/kubepug) to ensure your cluster is not using deprecated resources:
> Verifies the current kubernetes cluster or input files, checking whether exists objects in this deprecated API Versions, allowing the user to check before migrating
```bash
kubectl krew install deprecations
k deprecations --k8s-version=v1.22.0
```

#### Dive

Use [Dive](https://github.com/wagoodman/dive) to inspect the Docker Images. It’s a terminal app that enables you to deep-dive into your container’s layers and all:
> Ensure your Docker (container) images are not too big and does not contain unnecessary data
```bash
brew install dive
dive cilium/cilium:v1.9.10
```

#### Dasel

Use [Dasel](https://github.com/TomWright/dasel) to query and modify data structures using selector strings:
> Comparable to jq / yq, but supports JSON, YAML, TOML, XML and CSV with zero runtime dependencies
```bash
brew install dasel
```

Here’s some examples of what you can do quickly:
```bash
# Select the image for a container named auth
dasel select -f deployment.yaml -s "spec.template.spec.containers.(name=auth).image" tomwright/x:v2.0.0

# Change the image for a container named auth
dasel put string -f deployment.yaml -s "spec.template.spec.containers.(name=auth).image" "tomwright/x:v2.0.0"

# Update replicas to 3
dasel put int -f deployment.yaml -s "spec.replicas" 3

# Add a new env var
dasel put object -f deployment.yaml -s "spec.template.spec.containers.(name=auth).env.[]" -t string -t string name=MY_NEW_ENV_VAR value=MY_NEW_VALUE

# Update an existing env var
dasel put string -f deployment.yaml -s "spec.template.spec.containers.(name=auth).env.(name=MY_NEW_ENV_VAR).value" NEW_VALUE
```

### More Bonus: Containers without Docker

#### Colima

[Colima](https://github.com/abiosoft/colima) Container runtimes on macOS (and Linux) with minimal setup

*   Intel and M1 Macs support
*   Simple CLI interface
*   Docker and Containerd support
*   Port Forwarding
*   Volume mounts
*   Kubernetes
*   Replace Docker-for-Desktop

```bash
brew install colima  
brew install docker  
colima start                       # default using Docker runtime  
colima start --with-kubernetes     # start kubernetes local cluster  
colima start --runtime containerd --with-kubernetes  # remove docker completely  

colima status  
INFO[0000] colima is running  
INFO[0000] runtime: docker       # or containerd  
INFO[0000] arch: x86_64  
INFO[0000] kubernetes: enabled  

cat ~/.colima/colima.yaml  
vm:  
    cpu: 2  
    disk: 60  
    memory: 2  
    arch: x86_64  
    forward_agent: false  
    mounts: []  
runtime: containerd  
kubernetes:  
    enabled: true  
    version: v1.22.2  

colima nerdctl run -- -ti --rm alpine:latest sh  
/ # ...

colima nerdctl ps  
CONTAINER ID    IMAGE                              COMMAND    CREATED           STATUS    PORTS    NAMES  
47e87f00711d    docker.io/library/alpine:latest    "sh"       18 seconds ago    Up                 alpine-47e87``  

kubectl ctx  
colima
  
kubectl get pods -A  
NAMESPACE     NAME                                     READY   STATUS    RESTARTS   AGE  
kube-system   coredns-85cb69466-bz5mw                  1/1     Running   0          8m18s  
kube-system   local-path-provisioner-64ffb68fd-2g9gz   1/1     Running   0          8m18s  
kube-system   metrics-server-9cf544f65-t6tzs           1/1     Running   0          8m18s
```

### Podman

[Podman](https://podman.io/) is the container Swiss-Army knife from RedHat:

*   multiple image formats including the OCI and Docker image formats
*   full management of container lifecycle
*   container image management (managing image layers, overlay filesystems, etc)
*   Podman 3.4+ now support M1 Apple Macs
*   Replaces Docker for Desktop

```bash
brew install podman  
podman machine init  
podman machine start  
podman info
podman run registry.fedoraproject.org/fedora:latest echo hello
alias docker=podman
```

### Conclusion

Well, this list is not 100% complete. Who could build and maintain such a list ?   
Kubernetes is still a highly evolving ecosystem and new tools and patterns keeps emerging every week.

Feel free to comment and share your favorite tools and I’ll add them here.

This post is abstracted from a talk that I built for [CNCF/Kubernetes Canada](https://community.cncf.io/cloud-native-canada/) Meetups. Please contact me if you’re organizing a meetup and are interested.

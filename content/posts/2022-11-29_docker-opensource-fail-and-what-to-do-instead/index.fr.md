---
title: "Ratés avec Docker.io & OpenSource (et quoi faire à la place...)"
author: "Prune"
date: 2022-11-29T14:31:56.257Z
lastmod: 2023-11-30T22:24:45-05:00

description: ""

subtitle: "Ah Docker… what a sad story… The coolest and most promising openSource project, used by millions, and not able to make any profit out of…"

image: "images/1.png" 
images:
 - "images/1.png"
 - "images/2.jpg"
 - "images/3.jpeg"
 - "images/4.png"
 - "images/5.png"
 - "images/6.png"
 - "images/7.png"
 - "images/8.png"


aliases:
    - "/docker-opensource-fail-and-what-to-do-instead-1459f962064"

---

![Docker Fail](images/1.png#layoutTextWidth)


Ah Docker… what a sad story… The coolest and most promising openSource project, used by millions, and not able to make any profit out of it…

After a split of the many different parts of Docker, there was a move to finally try to make money with Docker Hub and Docker-For-Desktop.

Good or bad, I don’t know. What I know is that many openSource alternatives to Docker-For-Desktop now exist, and work perfectly, at least on macs, even on new M1/M2 processors.

Archy and I talked about it, too much, during our KubeCon NA 2022 session, that [you can see on Youtube](https://youtu.be/TKYAEjNg4Hw) or [read on our companion website](https://cloud-native-canada.github.io/k8s_setup_tools/).

To name a few, [Colima](https://github.com/abiosoft/colima), [Rancher Desktop](https://rancherdesktop.io/), [PodMan](https://iongion.github.io/podman-desktop-companion/)… Check [here](https://cloud-native-canada.github.io/k8s_setup_tools/local_cluster/options/colima/), [here](https://cloud-native-canada.github.io/k8s_setup_tools/local_cluster/options/rancher/) and [here](https://cloud-native-canada.github.io/k8s_setup_tools/local_cluster/podman/) for install examples, and learn a lot more. OK, we’re done with advertising :)

Kubernetes itself [moved away from the Docker Shim](https://kubernetes.io/blog/2022/02/17/dockershim-faq/) (another docker component) in the latest versions.

Going back to Docker… When building my KubeCon talk, I realized that one of my favorite project, [KubeColor](https://cloud-native-canada.github.io/k8s_setup_tools/kubectl_tooling/kubecolor/), was mostly un-maintained for almost 2 years. As a good OpenSource user (and after many tries to reach the creator, through all means possible), I decided to “fork” it and start maintaining it.

Lucky for me, the `kubecolor` Github Org wasn’t existing yet. I ended up creating [https://github.com/kubecolor/kubecolor](https://github.com/kubecolor/kubecolor) !

{{< image src="images/2.jpg" alt="KubeColor" position="center" style="border-radius: 0px; background-color: #eeeeee;" >}}


That allowed me to also offer KubeColor install through `brew` with a cool command line, `brew install kubecolor/tap/kubecolor` .

But an OpenSource project is not complete until you have a docker image available !

### Docker OSS

Back in the time, Docker Hub was free. stop.

It was easy to create an org and publish OSS projects. Really few clicks away.

Today, well, there’s a specific program for that: [Docker-Sponsored Open Source Program](https://www.docker.com/community/open-source/application/).

![image](images/3.jpeg#layoutTextWidth)


What you get with that is:

*   free autobuilds
*   rate-limit removal for all users pulling public images from your project namespace
*   special badging on Docker Hub (this will be visible within two weeks)

So I applied to this program, somewhere in **September**.

And I waited…

Waited…

I finally got an answer on **November 23**:
> Congratulations! Your project has been approved for the Docker-Sponsored Open Source program

Well, I don’t have the exact timeline, but oh man, OpenSource is moving fast… but I was waiting…
> A Docker Team subscription will be allocated to the project organization Docker ID specified in your application within the next 3 weeks

3 weeks ?

### Docker Miss

So, 3 days later, **November 26**, I received another email:
> We have been trying to get in touch with you, please provide us with the requested information. If we don’t hear back from you in 5 days, this case will be automatically marked as ‘Closed’.

Wait, what ? 5 days ?

November 26 is the ThanksGiving week-end, right ?

And of course, **November 28**, the deadline was over, I missed my turn:
> Thank you for submitting your request. Since we have not heard back from you in 5 days, your case has been automatically marked as ‘Closed’.

### What to do to not waste your time

I told you, OpenSource is moving fast.

Do you really think I waited all this time ? OF COURSE NOT !

As soon as my apply to Docker OSS program was done, I started looking for alternatives… and I didn’t had to look far away…

### **GITHUB !**

I already had a Github Org for the project. Github (like other companies supporting OSS) started to add new features to their offer as soon as Docker shifted to a “paid product”. [Including “Docker” Images registries](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

And [Github offers Actions for free](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions) (with limited CPU time) !

How long did it took me to port everything to Github ?

Answer is: not much

#### Releasing Binaries

Because KubeColor is a Go program, I used the `goreleaser/goreleaser-action` to build the Release. This includes multi-OS binaries, package and so on. It’s all the stuff you fine in [the Release section of the project](https://github.com/kubecolor/kubecolor/releases).

Just create a `.github/workflows/release.yml` file in your repo and add:
``` yaml
name: goreleaser

on:
  push:
    tags:
      - '*'

jobs:
  goreleaser:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - run: git fetch --force --tags
      - name: Set up Go
        uses: actions/setup-go@v3
        with:
          go-version: '>=1.19.1'
          cache: true
      - name: Run GoReleaser
        uses: goreleaser/goreleaser-action@v3
        with:
          distribution: goreleaser
          version: latest
          args: release --rm-dist
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GLOBAL_GITHUB_TOKEN: ${{ secrets.GLOBAL_GITHUB_TOKEN }}
```


The `GITHUB_TOKEN` secret is auto-provided by the Github Action pipeline.

The `GLOBAL_GITHUB_TOKEN` is one I created with more privileges.

**GoReleaser** actually use a config file, in the root of your project, named `.goreleaser.yml`. Here’s mine:

``` yaml
release:

before:
  hooks:
    - go mod tidy
    - make testshort

builds:
- id: kubecolor
  main: ./cmd/kubecolor/main.go
  binary: kubecolor
  ldflags:
    - -s -w
    - -X main.Version={{.Version}}
  goos:
    - windows
    - darwin
    - linux
  goarch:
    - arm64
    - amd64
    - ppc64le

archives:
- builds:
  - kubecolor
  replacements:
    darwin: Darwin
    linux: Linux
    windows: Windows
    amd64: x86_64
  format: tar.gz
  format_overrides:
    - goos: windows
      format: zip

brews:
- name: kubecolor
  tap:
    owner: kubecolor
    name: homebrew-tap
    token: "{{ .Env.GLOBAL_GITHUB_TOKEN }}"
  homepage: "https://github.com/kubecolor/kubecolor"
  description: "Colorize your kubectl output"
  license: "MIT"
  folder: Formula
  install: |
    bin.install "kubecolor"

checksum:
  name_template: 'checksums.txt'

changelog:
  sort: asc
  filters:
    exclude:
    - '^docs:'
    - '^test:'
```

As you can see, the `GLOBAL_GITHUB_TOKEN` is used to “publish” the needed files into another GitHub project, `homebrew-tap`.

So before running this action, you have to create another Github project: [https://github.com/kubecolor/homebrew-tap](https://github.com/kubecolor/homebrew-tap)

You don’t have to put anything in there. The GoReleaser will do that for you.

The `GLOBAL_GITHUB_TOKEN` is actually a [Personnal Token](https://github.com/settings/tokens) from my user, with sufficient privileges to manager both repos.

#### KubeColor Docker Image

![image](images/4.png#layoutTextWidth)


While having a docker image for KubeColor is not strictly needed, well, people will ask for it if there’s none…

Again, we’re going to use a Github Action for that. Create the file `.github/workflows/publish_docker_image.yml` :

```yaml
name: Publish docker image
on:
  push:
    branches:
      - 'main'
    tags:
      - '*'
jobs:
  push_to_registry_on_merge:
    name: Push docker image on merge to main
    runs-on: ubuntu-latest
    if: (!contains(github.event.head_commit.message, 'skip ci') && !startsWith(github.ref, 'refs/tags/'))
    steps:
      - name: Check out the repo
        uses: actions/checkout@v3
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v1
        with:
          registry: ghcr.io
          username: prune998
          password: ${{ secrets.GH_CONTAINER_REGISTRY_PUSHER }}
      - name: Build and push
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:${{ github.sha }}
  push_to_registry_on_tag:
    name: Push docker image to GitHub Container Registry on tag
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - name: Check out the repo
        uses: actions/checkout@v3
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v1
        with:
          registry: ghcr.io
          username: prune998
          password: ${{ secrets.GH_CONTAINER_REGISTRY_PUSHER }}
      - name: Build and push
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:${{ github.ref_name}}
            ghcr.io/${{ github.repository }}:latest
```

Here, we are using the `ghcr.io` Container (Docker) Registry. It’s as simple as that…

I have two different steps to tag the image differently if I merge to main branch or tag a release.

I’m no GH Actions expert, let me know if there’s a better (DRY-er) way for that. I just had to move fast…

Here, I’m using another Secret, `GH_CONTAINER_REGISTRY_PUSHER`, which allows this pipeline to push into the registry.

The registry lives at the ORG level. The **GHCR** is actually called `Packages` in the Org Setup at `https://github.com/organizations/<your org>/settings/packages` . You have to set it to Public so it’s a public repo.

You can then access your `packages` at `https://github.com/orgs/<your org>/packages`

![image](images/5.png#layoutTextWidth)


There’s not much to see about it:

![image](images/6.png#layoutTextWidth)


When you click on the `Package Settings` at the right here, you can then change the visibility (public/private):

![image](images/7.png#layoutTextWidth)

![image](images/8.png#layoutTextWidth)


### Wrap-up

To me, Docker is gone. We hopefully have alternatives for everything that was docker before.

I’m not sure what’s going to happen to docker in the future. I know a lot of big companies are paying so their docker images has no download or bandwidth limits, so I guess they will keep on for some time.

I’m really happy of this GitHub alternative though, which is really fast to setup, free and more secure as everything stays at the same place.

Note: All docker related images were generated using StableDiffusion at [https://huggingface.co/spaces/lnyan/stablediffusion-infinity](https://huggingface.co/spaces/lnyan/stablediffusion-infinity)

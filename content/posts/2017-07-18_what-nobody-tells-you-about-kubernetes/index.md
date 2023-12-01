---
title: "What nobody tells you about Kubernetes"
author: "Prune"
date: 2017-07-18T12:03:59.403Z
lastmod: 2023-11-30T22:05:26-05:00

description: ""

subtitle: "This is a first post in a long serie to come about what you never heard and maybe never thought about when using K8s (Kubernetes), and…"


tags: ["devops", "gitops", "kubernetes"]

aliases:
    - "/what-nobody-tells-you-about-kubernetes-3218b47c74d"

---

This is a first post in a long serie to come about what you never heard and maybe never thought about when using K8s (Kubernetes), and maybe other orchestration tools.

I’ve been using [Kubernetes](https://kubernetes.io/) for a long time. In fact, at some point, I decided not to use K8s for the company I was working for, because it was too new, unstable, not easy to deploy… At this time, I also decided not to use Marrathon, which was brand new and too linked to the (crappy) Mesos/Hadoop ecosystem (it’s better now with DC/OS).

My setup was composed of ubuntu servers + kickstart to set them up if physical+ Ansible to setup the server and deploy applications. That was working great !   
Until some management decided to move to [Openshift](https://www.openshift.com/).

Oh man ! Openshift ! It’s like using a two year old K8s with a RedHat interface. And if you’re using the Enterprise licences, you’re another year late. True Story, but not this one (maybe later).

Promises are great when you move to an orchestration tool like K8s. What is sold includes :

*   no service breakdown
*   easy deployment
*   reproducible deployment
*   tons of metrics
*   log gathering made easy
*   maximum resource usage
*   no resource exhaustion
*   no network outage

But many other things are not pushed to the front shelves, like, well, you still need to manage your logs, you disk space, your resources, your deployments, and the most important thing : you are using someone else’s work as your deployment script and image !

You can translate that : **using K8s is easy as someone else did the hard job for me**.

So, for the first post, and as an example, here is something that NOBODY tells you about Kubernetes !

### Logs gathering with Fluentd + ES + Kibana

Many blog posts are explaining how to do this. It’s SO easy.

Well, if it’s so easy, why do we still have to install it ? Why isn’t it bundled ?
> Use Helm Charts, it’s so easy to deploy

Well, that is true if you don’t want to use latest release/features. What my experience is, is that [“official” Helm Chart](https://github.com/kubernetes/charts) for ES (which is still in the incubator) is installing ES 2.4. New releases of Fluentd/Kibana require a newer ES. And knowing that they are now at version 5.5, who want’s to go with the old (and not supported anymore ? have to confirm that) 2.4 version that I was using 3 or 4 years ago ?

That is where your logging journey begins.

In the coming articles I’ll get into each of the painful story I went through.

Please, don’t be mad at me, I’m not saying K8s is crap or not production ready. I’m just saying that K8s is a forest and many, many, goblins, unicorns, princesses and dragons are hiding inside it.

Also, I’m no expert. I’m always learning, and I’m trying to give a feedback of all this learning. I will have (I do have) newbie problems, because I don’t know this or that. But most of the time, it ends as beeing a really small thing I wasn’t aware of, because nobody is telling it.

My conclusion is that the problem here is not K8s, but what you are (not) doing with it :

*   you are not installing JMX in java application (to scrape metrics with Prom)
*   you are not logging in JSON
*   you are keeping Info logs in your deployments
*   you are using outdated version
*   you don’t know what you are deploying
*   you are using Docker Images without having the Dockerfile to build them (related to the point above)
*   you are doing things by hand instead of code

And so on…

And still, you are blogging about what you’re doing. You are releasing you code on Github (because you are cool and you enjoy Opensource).  
And others are reading your blog post and think like “wow that’s amazing, I need that in my company.

Until the next day, when all the data is lost because your Deployment is not using a persistent storage !

Stay tuned for the next posts, like :

*   ES official images are 650M large ! Why ? (tip : they don’t know how to compile -static + other fun facts)
*   Fluent-bit is not parsing your application Json logs (you need an option !!!)
*   Missing JMX activation inside Java application images

### Writer

I’m known as Prune and I’ve been working in the Internet/Hosting/Media industry for almost 20 years. I’ve been from Telnet to SSH, from shell script to Orchestration and Cloud computing and am still learning.

I’m now living in Quebec, Canada and am working as a system architect/ops for a company involved in road driving security devices/apps.

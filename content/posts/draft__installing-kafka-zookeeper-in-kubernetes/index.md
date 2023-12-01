---
title: "Installing Kafka + Zookeeper in Kubernetes"
author: ""
date: 
lastmod: 2023-11-30T22:24:50-05:00
draft: true
description: ""

subtitle: "Hello there ! Going on with K8s findings and mysteries, I had to install a Kafka cluster."




---

Hello there ! Going on with K8s findings and mysteries, I had to install a Kafka cluster.

Kafka is a really great solution to stream data. You have **producers** inserting some data into **brokers** “topics”, then you have **consumers** reading them. So easy !

This is 100% micro-services compatible, because every service can consume some data from the Kafka topic and offer an API.  
Then, others micro-services can ask for specific processed information.   
Ok, my description is over-simplistic, but I’m not here to teach you how micro-services are working (for now).

### installing Kafka

So you have a K8s cluster and you need a Kafka service. Well, in fact, to be able to deploy Kafka, you need Zookeeper, the “_other”_ Etcd or Consul. It acts as a meeting points where Kafka can manage, well, less and less things as Kafka is working hard to remove this dependency. But for the moment it’s needed.   
Ok now I’m going to stop explaining stuff like that, because one, your are not a newbie and you know what Kafka/Zk/K8s are and two, explaining so quickly is just not explaining at all.

So you need Zookeeper. Let’s move on to that first.

### installing Zookeeper

If, like me, you’re trying to use Helm Charts for your deployments, YOU ARE LUCKY !   
The official Helm Chart for Kafka also install Zookeeper thanks to its dependency. So you can go helming right away

### installing Kafka (finaly)
`helm install --name=kafka incubator/kafka --namespace=kafka`

Wait few minutes and you should have a working Kafka + Zk cluster of 3 nodes (each). 

This was actually SOOOO easy ! Thanks K8s, thanks Helm.   
Come back soon for the next post !

WAIT WAIT WAIT

### what nobody tells you

What is not told, is that :

*   you won’t get any metrics from kafka or zookeeper
*   you won’t get any useful logs as they are not Json

Why ? Well, because most of time, people don’t care. Hopefully, Prometheus guys do care, and they made a JMX exporter for Prometheus, which is a missing piece  of most of the metrics solutions. Most of them use a local agent that will call Kafka or ZK “cli tool” to get some metrics.   
I hope you see how ugly this is ? 

So, back to the JMX exporter !

You will find great resources out there to get help installing it. Most of the time, only explaining how to install it in Kafka, or in Zk, not both.

Installing it is quite easy. You put the jar + a config file, you add an environment variable and you start Kafka/Zk.

Another advantage to this is that your end up with your own Docker Image. Remember, “never us latest image”, well, you just pinned your own image that will only change when you want/need. 

Let’s dive into this…

### create docker image for Zookeeper

First, grab the needed files
`wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.9/jmx_prometheus_javaagent-0.9.jar  
wget https://raw.githubusercontent.com/prometheus/jmx_exporter/master/example_configs/zookeeper.yaml`

Then create the Dockerfile
`FROM gcr.io/google_samples/k8szk:v2  
# base image dockerfile [https://github.com/kubernetes/contrib/blob/master/statefulsets/zookeeper/Dockerfile](https://github.com/kubernetes/contrib/blob/master/statefulsets/zookeeper/Dockerfile)``ARG CI_COMMIT_TAG=&#34;none&#34;  
ARG CI_COMMIT_SHA=&#34;none&#34;  
ARG NOW=&#34;unknown&#34;``LABEL vendor=&#34;Coyotelab&#34; \  
      version=&#34;${CI_COMMIT_TAG}&#34; \  
      release-date=&#34;${NOW}&#34; \  
      commit=&#34;${CI_COMMIT_SHA}&#34;``WORKDIR /opt/zookeeper  
COPY jmx_prometheus_javaagent-0.9.jar .  
COPY zookeeper.yaml .``# we keep no entrypoint for now to be comptible with the official image  
#ENTRYPOINT [&#39;sh&#39;, &#39;-c&#39;, &#39;zkGenConfig.sh &amp;&amp; SERVER_JVMFLAGS=&#34; -javaagent:/opt/zookeeper/jmx_prometheus_javaagent-0.9.jar=7071:/opt/zookeeper/zookeeper.yaml &#34; zkServer.sh&#39;]  
#CMD [&#39;start-foreground&#39;]`

Straightforward… 

*   build from the sample zk image from k8s (this could be improved too)
*   import some variables
*   label your image
*   copy your JXM exporter files
*   start ZK. This is commented to be compatible with the current K8s deployment files

Now you can build the image. My build is done automaticaly by gitlab-CI, then the image is pushed in the repo. For you poor guys with CI/CD, use :
`export APP=&#39;zookeeper&#39; APP_VERSION=3.4.9 NOW=$(date +&#34;%Y%m%d%H%M%S&#34;)  
docker build -t coyotelab/${APP}:${APP_VERSION} --build-arg CI_COMMIT_TAG=whatever --build-arg CI_COMMIT_SHA=whenever --build-arg NOW=${NOW} .`

Just to go a step ahead, you will have to ensure that your K8s Stateful Set is using your new image and starting it with the right env and command :
`apiVersion: apps/v1beta1  
kind: StatefulSet  
metadata:  
...  
spec:  
  replicas: 3  
  template:  
  ...  
    spec:  
      containers:  
 **- command:  
        - sh  
        - -c  
        - zkGenConfig.sh &amp;&amp; SERVER_JVMFLAGS=&#34; -javaagent:/opt/zookeeper/jmx_prometheus_javaagent-0.9.jar=7071:/opt/zookeeper/zk-exporter.yaml&#34;  
          exec zkServer.sh start-foreground**  
        env:  
        - name: ZK_CLIENT_PORT  
          value: &#34;2181&#34;  
        - name: ZK_SERVER_PORT  
          value: &#34;2888&#34;  
        - name: ZK_ELECTION_PORT  
          value: &#34;3888&#34;  
        ...`

### create docker image for Kafka

### update the Helm chart

### Issues you may still encounter 

There is a strange bug with the latest JXM exporter (0.9) where it gets crazy when you have too many cores on your server ([https://github.com/prometheus/jmx_exporter/issues/156](https://github.com/prometheus/jmx_exporter/issues/156)). And guess what ? That happened to me !   
The solution for now is to use the latest code, so building yourself the 0.10_SNAPSHOT version.   
This is again quite easy :
``git clone https://github.com/prometheus/jmx_exporter.git  
cd jmx_exporter/  
docker run --rm -v $PWD:/build -w /build maven mvn package  
cp `jmx_prometheus_javaagent/target/jmx_prometheus_javaagent-0.10-SNAPSHOT.jar where_you_need_it`

Now you just have to re-write the code above with the right name for the 0.10 jar :)  
I know I’m a jerk, you’re losing your time reading me, but guess what ? I’m telling you the truth on what’s going on in the K8s forest !

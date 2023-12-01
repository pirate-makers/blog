---
title: "Using Jsonnet does not have to be complex"
author: "Prune"
date: 2019-06-04T19:25:40.908Z
lastmod: 2023-11-30T22:15:15-05:00

description: "Jsonnet is not a new tool but is not widely used. This is mostly due to the first impression you have when using it : too complex."

subtitle: "Using Jsonnet instead of Helm for Kubernetes Manifests"

image: "/content/posts/2019-06-04_using-jsonnet-does-not-have-to-be-complex/images/1.png" 
images:
 - "/content/posts/2019-06-04_using-jsonnet-does-not-have-to-be-complex/images/1.png"
 - "/content/posts/2019-06-04_using-jsonnet-does-not-have-to-be-complex/images/2.png"


aliases:
    - "/using-jsonnet-does-not-have-to-be-complex-54b1ad9b21db"

---

![image](/content/posts/2019-06-04_using-jsonnet-does-not-have-to-be-complex/images/1.png#layoutTextWidth)


[Jsonnet](https://jsonnet.org/) is not a new tool but is not widely used. This is mostly due to the first impression you have when using it : too complex.

I’ll try to explain what I’ve set up to generate Kubernetes manifests for all my Micro-Services.

### Kubernetes / Jsonnet

The obvious gain you have when using Jsonnet is that you template JSON files instead of YAML.   
While YAML is easier to read by humans, it is far less computational friendly. There’s a must read about that : [Lee Briggs post about “Why the fuck are we templating YAML”](http://leebriggs.co.uk/blog/2019/02/07/why-are-we-templating-yaml.html)

Jsonnet is just “yet another templating tool” so you can use it to template your Kubernetes manifests. Many tools have been made to ease that, including (and not limited) to :

*   [Ksonnet](https://ksonnet.io/), which adds specific Kubenetes functions on top of Jsonnet
*   [Kr8](https://kr8.rocks/)
*   more… check [this article about Kubernetes deployment templating](https://blog.argoproj.io/the-state-of-kubernetes-configuration-management-d8b06c1205)

While the team behind Ksonnet stepped back, the [Ksonnet lib](https://github.com/ksonnet/ksonnet-lib) is still maintained. It’s the only things that matters to us.  
Ksonnet was supposed to be a tool that takes care of everything from templating to variable managements, but was really hard to apprehend.

I decided to just do plain Jsonnet, with the addition of the Bitnami lib for Kubernetes.

Jsonnet is (was) a C++ project, which you can download/build/install… It was lately ported to Go (Golang), and it’s now the official build, the one where they will port new features and tuning first (according to comments in some issues).   
From my own experience with my small templates, using the Go version shorted the build time to 1:45 to nearly 25 seconds. So, go Go :
`go get github.com/google/go-jsonnet/cmd/jsonnet  
$GOPATH/bin/jsonnet --version0`

### Starting point

We are actually using a Mono-Repo to hold all our microservices, written in Go.  
Because of that I decided to store the Jsonnet templates inside the same repo, and ensure the Dev team manage them when they change the commandline or options of the micro-services.

Here is how it’s done :

![image](/content/posts/2019-06-04_using-jsonnet-does-not-have-to-be-complex/images/2.png#layoutTextWidth)


Let’s dive in and re-create all this :

“jsonnet” directory holds all the Jsonnet stuff. Inside it, we have one directory for each application (micro-service) that is managed by Jsonnet. Let’s pretend we have a Helloworld application :
`mkdir -p jsonnet/helloworld  
cd jsonnet`

### Defaults

default-env.jsonnet contains some default global variables that apply to all apps. We have to define here ALL the variables that could be used inside our generic templates.   
Later, those variables will be used as constants.  
Don’t forget it’s a JSON file :
`{  
  &#34;app&#34;: &#34;&#34;,  
  &#34;commitId&#34;: &#34;&#34;,  
  &#34;namespace&#34;: &#34;&#34;,``  &#34;repoUrl&#34;: &#34;your.docker.repo:4567&#34;,``  labels: {  
    &#34;appgroup&#34;: &#34;mycompany&#34;,  
    &#34;metrics&#34;: &#34;true&#34;,  
  },``&#34;command&#34;: [],  
  &#34;args&#34;: [],  
  &#34;env&#34;: {  
    LOGLEVEL: &#34;WARN&#34;,  
    LOGLEVEL: &#34;WARN&#34;,  
    LOGLEVELDEV: &#34;DEBUG&#34;,  
    LOGLEVELINTEGRATION: &#34;INFO&#34;,  
    HTTPPORT: &#34;1080&#34;,  
  },``  kubeconfig: {  
    &#34;replicas&#34;: 1,  
    &#34;mem_limit&#34;: &#34;250Mi&#34;,  
    &#34;mem_request&#34;: &#34;100Mi&#34;,  
    &#34;cpu_limit&#34;: &#34;0.01&#34;,  
    &#34;cpu_request&#34;: &#34;0.1&#34;,  
    &#34;istio&#34;: false,  
    &#34;readOnlyRootFilesystem&#34;: true,  
    &#34;liveness&#34;: true,  
    &#34;readiness&#34;: true,  
  },  
  &#34;volumeMounts&#34;: {},  
  &#34;volumes&#34;: {},``  &#34;ports&#34;: {  
    &#34;http&#34;: {  
      &#34;containerPort&#34;: 1080,  
      &#34;protocol&#34;: &#34;TCP&#34;,  
    },  
    &#34;grpc&#34;: {  
      &#34;containerPort&#34;: 1081,  
      &#34;protocol&#34;: &#34;TCP&#34;,  
    }  
  },``}`

### Templates

Now we have our Generic Templates, for Kubernetes Deployments and Services.  
It uses the kube.libsonnet
`local kube = import &#34;kube.libsonnet&#34;;``{  
  config:: error &#34;this file assumes a config variable&#34;,  
  labels+:: {} + $.config.labels,``deployment: kube.Deployment(  
  labels+:: {} + $.config.labels,  
  metadata+: {  
    labels+: $.labels,  
    namespace:: $.config.namespace,  
  },  
  spec+: {  
    replicas: 2,  
    template+: {  
    spec+: {  
      volumes_+: $.config.volumes,  
      containers_+: {``      default: kube.Container($.config.app) {  
        image: $.config.image_path + &#34;:&#34; + $.config.commitId,  
        resources: {  
          requests: {   
            cpu: $.config.kubeconfig.cpu_request,  
            memory: $.config.kubeconfig.mem_request  
          },  
          limits: {  
            cpu: $.config.kubeconfig.cpu_limit,  
            memory: $.config.kubeconfig.mem_limit  
          },  
        },  
        livenessProbe: if $.config.kubeconfig.liveness then {  
          httpGet:{  
            path: &#34;/healthz&#34;,  
            port: &#34;http&#34;,  
            scheme: &#34;HTTP&#34;  
          },  
          initialDelaySeconds: 3,  
          periodSeconds: 3,  
        },  
        readinessProbe: if $.config.kubeconfig.readiness then {  
          httpGet:{  
            path: &#34;/ready&#34;,  
            port: &#34;http&#34;,  
                  scheme: &#34;HTTP&#34;  
          },  
          initialDelaySeconds: 3,  
          periodSeconds: 3,  
        } else if $.config.kubeconfig.liveness  
        then{  
          httpGet:{  
            path: &#34;/healthz&#34;,  
            port: &#34;http&#34;  
          },  
          initialDelaySeconds: 3,  
          periodSeconds: 3,  
        },  
        args: $.config.args,  
        command: $.config.command,  
        env_: $.config.env,  
        ports_+: $.config.ports,  
        volumeMounts_+: $.config.volumeMounts,  
      }}  
    }}  
  }  
}}`

All this is quite like a regular deployment, in JSON, with some $.variable replacement.

Services are not really different :
`local kube = import &#34;kube.libsonnet&#34;;``{  
  config:: error &#34;this file assumes a config variable&#34;,  
  dep:: error &#34;this file assumes a deployment variable&#34;,  
  portName:: &#34;http&#34;,``  labels+:: {} + $.config.labels,``  // set the Service name to the app name when it&#39;s the GRPC port, else, add the port name  
  local serviceName = if  $.portName == &#34;grpc&#34; then $.config.app else $.config.app + &#34;-&#34; + $.portName,``  // set the service type to enable external acces in minikube  
  local serviceType = if $.config.environment == &#34;minikube&#34; then &#34;NodePort&#34; else &#34;ClusterIP&#34;,``  service: kube.Service(serviceName) {  
    metadata+: {  
      labels+: $.labels,  
      namespace:: $.config.namespace,  
    },  
    target_pod: $.dep.deployment.spec.template,  
    spec: {  
      ports: [  
        {  
        name: $.portName,  
        port: $.config.ports[$.portName].containerPort,  
        targetPort: $.config.ports[$.portName].containerPort,  
        }  
      ],  
      selector: {  
        app: $.config.app,  
      },  
      type: serviceType,  
    },  
  },  
}`

### LibSonnet

This files comes from the Bitnami Labs, you can download it from [https://github.com/bitnami-labs/kube-libsonnet/blob/master/kube.libsonnet](https://github.com/bitnami-labs/kube-libsonnet/blob/master/kube.libsonnet)

### Applications

Now let’s dive in the specific files for each applications.
`cd helloworld`

#### default.jsonnet

This file holds the variables that are global to all environments. For example, the application “helloworld” will have the same same whether you deploy in Dev or in Prod…
`{  
  local constant = import &#34;../default-env.jsonnet&#34;,  
  kubeconfig: {  
    replicas: 1,  
    mem_limit: &#34;400Mi&#34;,  
    mem_request: &#34;100Mi&#34;,  
    cpu_limit: 1,  
    cpu_request: &#34;10m&#34;,  
    istio: &#34;true&#34;,  
    readOnlyRootFilesystem: true,  
    liveness: true,  
    readiness: true,  
  },  
  labels: {  
    &#34;main_path&#34;: &#34;true&#34;,  
  },  
  affinity: {},  
  env: {  
    HTTPPORT: constant.env.HTTPPORT,  
    LOGLEVEL: constant.env.LOGLEVEL,  

    TOKENPRIVKEY : {  
      secretKeyRef : {  
        name: &#34;helloword-keys&#34;,  
        key: &#34;private_key&#34;  
      }},  
  }  
}`

Here we create a constant variable which holds some values that we consider constants. Those values comes from the **default-env.jsonnet** file we created earlier.  
For example, after this step, **env.LOGLEVEL** is set to the default **LOGLEVEL**, which is _WARN_.

#### dev.jsonnet
`{  
  local default = import &#34;./default.jsonnet&#34;,  
  local constant = import &#34;../default-env.jsonnet&#34;,  
  environment: &#34;dev&#34;,  
  kubeconfig+: default.kubeconfig + {  
  },  
  labels+: default.labels + {  
  },  
  env+: default.env + {  
    LOGLEVEL: constant.env.LOGLEVELDEV,  
  }  
}`

This is where funny stuff happens

first we “import” the defaut files from above and assign it to the **default** variable and we import the global default-env.jsonner, stored as **constant** variables.   
Then we overload the **kubeconfig** and **labels** variables (with nothing at this time).  
Next the **env** variable is also overloaded with values from the **default** variable and we set the LOGLEVEL to a constant, **LOGLEVELDEV**.

#### integration.jsonnet

The prod file is not much different, except it sets few things differently :
`{  
  local default = import &#34;./default.jsonnet&#34;,  
  local constant = import &#34;../default-env.jsonnet&#34;,  
  environment: &#34;integration&#34;,  
  kubeconfig+: default.kubeconfig + {  
    replicas: 10,  
  },  
  labels+: default.labels + {  
  },  
  env+: default.env + {  
    LOGLEVEL: constant.env.LOGLEVELINTEGRATION,  
  }  
}`

Creating the manifests from this file will scale the deployment to 10 replicas and set the application logs to the _INFO_ level (LOGLEVELINTEGRATION: “INFO” from default-env.jsonnet)

#### template.jsonnet

This is where everything gets mashed ups to define which manifests we need for this specific application.
`local config = import &#34;../default-env.jsonnet&#34;;  
local kube = import &#34;../kube.libsonnet&#34;;``local environmentVars = std.extVar(&#39;env&#39;);  
local commitId = std.extVar(&#39;commit&#39;);  
local namespace = std.extVar(&#39;namespace&#39;);``local localApp = config + environmentVars + {  
  app: &#34;helloworld&#34;,  
  commitId: commitId,  
  namespace: if namespace != &#34;&#34; then namespace else null,         //Namespace is not used in templates for now  
  project: &#34;helloworld&#34;,  
  group: &#34;servers&#34;,``// computed vars  
  deployment_name: &#34;%s&#34; % [self.app],  
  repoPath: &#34;%s/%s&#34;% [self.group,self.project],  
  image_path: if environmentVars.environment != &#34;minikube&#34; then &#34;%s/%s/%s/%s&#34; % [self.repoUrl, self.repoPath, self.appGroup, self.app] else &#34;%s/%s&#34; % [self.appGroup, self.app],``// merge env and labels !!! don&#39;t remove  
  env: environmentVars.env,  
  labels+: config.labels + environmentVars.labels + {  
    &#34;app&#34;: $.app,  
    &#34;group&#34;: $.group,  
    &#34;project&#34;: $.project,  
    &#34;commit&#34;: $.commitId,  
    &#34;version&#34;: $.commitId,  
    &#34;track&#34;: $.namespace,  
    &#34;environment&#34;: $.environment  
  },  
  ports: {  
    http: {  
      containerPort: std.parseInt($.env.HTTPPORT),  
      protocol: &#34;TCP&#34;  
    }  
  },  
};``// List of templates to generate  
local serviceHttp = (import &#34;../generic-service.jsonnet&#34;) + {  
  config: localApp,  
  portName: &#34;http&#34;  
};``local deployment = (import &#34;../generic-deployment.jsonnet&#34;) + {  
  config: localApp,  
};``// final list of all manifests  
local all = [deployment.deployment, serviceHttp.service];``// generate a K8s list  
{  
  apiVersion: &#34;v1&#34;,  
  kind: &#34;List&#34;,  
  items: all,  
}`

Here we use some _std.extVar(‘’)_ expressions. This tells Jsonnet that this value have to come from the command line. This is what we want : a way to define some variables at the time we generate the manifest.

Then we create new variables with concatenated data.

finally, we import the _generic-*.jsonnet_ files, which will create the manifests and store the result in variables.

The last part is to put all those variables in a _JSON List_ manifest.

Note that there may be some smarter ways to do this. I’m not a Jsonnet expert, and sometimes there are many ways of doing things. [Prometheus-Operator](https://github.com/coreos/kube-prometheus) Jsonnet is one of the best, and hardest, I’ve seen. It makes a huge usage of Mixins. That may be something I’ll use in the next iteration.

Back to our files here.

So we’re creating a **serviceHttp** that is using the _../generic-service.jsonnet_ file, and a **deployment** using the _../generic-deployment.jsonnet_

### Usage

So, how do you generate your helloworld manifest ?
``cd jsonnet/helloworld````jsonnet --ext-code-file env=dev.jsonnet --ext-str commit=$(git describe  --always --tags --long --abbrev=8) --ext-str namespace=&#34;&#34;` `template.jsonnet``

*   ext-code-file is the file to load as the environment file and is stores into the variable env
*   ext-str allows to set a variable from the command line

the cool this is that this command does NOT depend on the application you’re trying to build. Just _cd ../app-2_ and use the same command to build your template.

### Customization

Let’s say you want a GRPC port along your HTTP port for the Helloworld application ?

Let’s change the jsonnet/helloworld/template.jsonnet file :

*   add the code to marshal the generic-service.jsonnet again, with a different port name (add)`local serviceGrpc = (import &#34;../generic-service.jsonnet&#34;) + {  
  config: localApp,  
  portName: &#34;grpc&#34;  
};`

*   add this now port to the list of things you want to dump (replace old line) :`// final list of all manifests``local all = [deployment.deployment, serviceGrpc.service, serviceHttp.service];`

### Conclusion

I think that whatever I do/say, Jsonnet will always be complicated. I’ve been doing a lot of Go Templates and Jinja2 (Ansible), and, sadly, yes, Jsonnet is less interesting to read.

But when it comes to Kubernetes, where the alternatives are Helm and Kustomize, you quickly understant that Jsonnet have tons of benefits.

I hope you’ll give a try to Jsonnet and won’t blame me for pushing you about it :)

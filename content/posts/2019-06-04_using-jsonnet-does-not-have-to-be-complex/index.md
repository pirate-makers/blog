---
title: "Using Jsonnet does not have to be complex"
author: "Prune"
date: 2019-06-04T19:25:40.908Z
lastmod: 2023-11-30T22:15:15-05:00

description: "Jsonnet is not a new tool but is not widely used. This is mostly due to the first impression you have when using it : too complex."

subtitle: "Using Jsonnet instead of Helm for Kubernetes Manifests"

image: "images/1.png" 
images:
 - "images/1.png"
 - "images/2.png"


tags: ["devops", "json", "kubernetes"]

aliases:
    - "/using-jsonnet-does-not-have-to-be-complex-54b1ad9b21db"

---

![image](images/1.png#layoutTextWidth)

In this Post I’ll try to explain what I’ve set up to generate Kubernetes manifests for all my Micro-Services using [Jsonnet](https://jsonnet.org/).

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

[Jsonnet](https://jsonnet.org/) is (was) a C++ project, which you can download/build/install… It was lately ported to Go (Golang), and it’s now the official build, the one where they will port new features and tuning first (according to comments in some issues).   
From my own experience with my small templates, using the Go version shorted the build time to 1:45 to nearly 25 seconds. So, go Go :
```bash
go get github.com/google/go-jsonnet/cmd/jsonnet  
$GOPATH/bin/jsonnet --version0
```

### Starting point

We are actually using a Mono-Repo to hold all our microservices, written in Go.  
Because of that I decided to store the Jsonnet templates inside the same repo, and ensure the Dev team manage them when they change the commandline or options of the micro-services.

Here is how it’s done :

![image](images/2.png#layoutTextWidth)


Let’s dive in and re-create all this :

`jsonnet` directory holds all the Jsonnet stuff. Inside it, we have one directory for each application (micro-service) that is managed by Jsonnet. Let’s pretend we have a Helloworld application :
```bash
mkdir -p jsonnet/helloworld  
cd jsonnet
```

### Defaults

default-env.jsonnet contains some default global variables that apply to all apps. We have to define here ALL the variables that could be used inside our generic templates.   
Later, those variables will be used as constants.  
Don’t forget it’s a JSON file :
```json
{  
  "app": "",  
  "commitId": "",  
  "namespace": "",
  "repoUrl": "your.docker.repo:4567",
  "labels": {  
    "appgroup": "mycompany",  
    "metrics": "true",  
  },
  "command": [],  
  "args": [],  
  "env": {  
    "LOGLEVEL": "WARN",  
    "LOGLEVELDEV": "DEBUG",  
    "LOGLEVELINTEGRATION": "INFO",  
    "HTTPPORT": "1080",  
  },
  "kubeconfig": {  
    "replicas": 1,  
    "mem_limit": "250Mi",  
    "mem_request": "100Mi",  
    "cpu_limit": "0.01",  
    "cpu_request": "0.1",  
    "istio": false,  
    "readOnlyRootFilesystem": true,  
    "liveness": true,  
    "readiness": true,  
  },  
  "volumeMounts": {},  
  "volumes": {},
    "ports": {  
    "http": {  
      "containerPort": 1080,  
      "protocol": "TCP",  
    },  
    "grpc": {  
      "containerPort": 1081,  
      "protocol": "TCP",  
    }  
  },
}
```

### Templates

Now we have our Generic Templates, for Kubernetes Deployments and Services.  
It uses the kube.libsonnet
```json
local kube = import "kube.libsonnet";
{  
  config:: error "this file assumes a config variable",  
  labels+:: {} + $.config.labels,
  deployment: kube.Deployment(  
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
        containers_+: {
          default: kube.Container($.config.app) {  
          image: $.config.image_path + ":" + $.config.commitId,  
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
              path: "/healthz",  
              port: "http",  
              scheme: "HTTP"  
            },  
            initialDelaySeconds: 3,  
            periodSeconds: 3,  
          },  
          readinessProbe: if $.config.kubeconfig.readiness then {  
            httpGet:{  
              path: "/ready",  
              port: "http",  
              scheme: "HTTP"  
            },  
            initialDelaySeconds: 3,  
            periodSeconds: 3,  
          } else if $.config.kubeconfig.liveness  
          then{  
            httpGet:{  
              path: "/healthz",  
              port: "http"  
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
  }}
```

All this is quite like a regular deployment, in JSON, with some $.variable replacement.

Services are not really different :
```json
local kube = import "kube.libsonnet";
{  
  config:: error "this file assumes a config variable",  
  dep:: error "this file assumes a deployment variable",  
  portName:: "http",
  labels+:: {} + $.config.labels,
  // set the Service name to the app name when it's the GRPC port, else, add the port name  
  local serviceName = if  $.portName == "grpc" then $.config.app else $.config.app + "-" + $.portName,
  // set the service type to enable external acces in minikube  
  local serviceType = if $.config.environment == "minikube" then "NodePort" else "ClusterIP",
  service: kube.Service(serviceName) {  
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
}
```

### LibSonnet

This files comes from the Bitnami Labs, you can download it from [https://github.com/bitnami-labs/kube-libsonnet/blob/master/kube.libsonnet](https://github.com/bitnami-labs/kube-libsonnet/blob/master/kube.libsonnet)

### Applications

Now let’s dive in the specific files for each applications.
`cd helloworld`

#### default.jsonnet

This file holds the variables that are global to all environments. For example, the application “helloworld” will have the same same whether you deploy in Dev or in Prod…
```json
{  
  local constant = import "../default-env.jsonnet",  
  kubeconfig: {  
    replicas: 1,  
    mem_limit: "400Mi",  
    mem_request: "100Mi",  
    cpu_limit: 1,  
    cpu_request: "10m",  
    istio: "true",  
    readOnlyRootFilesystem: true,  
    liveness: true,  
    readiness: true,  
  },  
  labels: {  
    "main_path": "true",  
  },  
  affinity: {},  
  env: {  
    HTTPPORT: constant.env.HTTPPORT,  
    LOGLEVEL: constant.env.LOGLEVEL,  

    TOKENPRIVKEY : {  
      secretKeyRef : {  
        name: "helloword-keys",  
        key: "private_key"  
      }},  
  }  
}
```

Here we create a constant variable which holds some values that we consider constants. Those values comes from the **default-env.jsonnet** file we created earlier.  
For example, after this step, **env.LOGLEVEL** is set to the default **LOGLEVEL**, which is _WARN_.

#### dev.jsonnet
```json
{  
  local default = import "./default.jsonnet",  
  local constant = import "../default-env.jsonnet",  
  environment: "dev",  
  kubeconfig+: default.kubeconfig + {  
  },  
  labels+: default.labels + {  
  },  
  env+: default.env + {  
    LOGLEVEL: constant.env.LOGLEVELDEV,  
  }  
}
```

This is where funny stuff happens

first we “import” the defaut files from above and assign it to the **default** variable and we import the global default-env.jsonner, stored as **constant** variables.   
Then we overload the **kubeconfig** and **labels** variables (with nothing at this time).  
Next the **env** variable is also overloaded with values from the **default** variable and we set the LOGLEVEL to a constant, **LOGLEVELDEV**.

#### integration.jsonnet

The prod file is not much different, except it sets few things differently :
```json
{  
  local default = import "./default.jsonnet",  
  local constant = import "../default-env.jsonnet",  
  environment: "integration",  
  kubeconfig+: default.kubeconfig + {  
    replicas: 10,  
  },  
  labels+: default.labels + {  
  },  
  env+: default.env + {  
    LOGLEVEL: constant.env.LOGLEVELINTEGRATION,  
  }  
}
```

Creating the manifests from this file will scale the deployment to 10 replicas and set the application logs to the _INFO_ level (LOGLEVELINTEGRATION: “INFO” from default-env.jsonnet)

#### template.jsonnet

This is where everything gets mashed ups to define which manifests we need for this specific application.
```json
local config = import "../default-env.jsonnet";  
local kube = import "../kube.libsonnet";
local environmentVars = std.extVar('env');  
local commitId = std.extVar('commit');  
local namespace = std.extVar('namespace');
local localApp = config + environmentVars + {  
  app: "helloworld",  
  commitId: commitId,  
  namespace: if namespace != "" then namespace else null,         //Namespace is not used in templates for now  
  project: "helloworld",  
  group: "servers",
  // computed vars  
  deployment_name: "%s" % [self.app],  
  repoPath: "%s/%s"% [self.group,self.project],  
  image_path: if environmentVars.environment != "minikube" then "%s/%s/%s/%s" % [self.repoUrl, self.repoPath, self.appGroup, self.app] else "%s/%s" % [self.appGroup, self.app],
  // merge env and labels !!! don't remove  
  env: environmentVars.env,  
  labels+: config.labels + environmentVars.labels + {  
    "app": $.app,  
    "group": $.group,  
    "project": $.project,  
    "commit": $.commitId,  
    "version": $.commitId,  
    "track": $.namespace,  
    "environment": $.environment  
  },  
  ports: {  
    http: {  
      containerPort: std.parseInt($.env.HTTPPORT),  
      protocol: "TCP"  
    }  
  },  
};
// List of templates to generate  
local serviceHttp = (import "../generic-service.jsonnet") + {  
  config: localApp,  
  portName: "http"  
};
local deployment = (import "../generic-deployment.jsonnet") + {  
  config: localApp,  
};
// final list of all manifests  
local all = [deployment.deployment, serviceHttp.service];
// generate a K8s list  
{  
  apiVersion: "v1",  
  kind: "List",  
  items: all,  
}
```

Here we use some _std.extVar(‘’)_ expressions. This tells Jsonnet that this value have to come from the command line. This is what we want : a way to define some variables at the time we generate the manifest.

Then we create new variables with concatenated data.

finally, we import the _generic-*.jsonnet_ files, which will create the manifests and store the result in variables.

The last part is to put all those variables in a _JSON List_ manifest.

Note that there may be some smarter ways to do this. I’m not a Jsonnet expert, and sometimes there are many ways of doing things. [Prometheus-Operator](https://github.com/coreos/kube-prometheus) Jsonnet is one of the best, and hardest, I’ve seen. It makes a huge usage of Mixins. That may be something I’ll use in the next iteration.

Back to our files here.

So we’re creating a **serviceHttp** that is using the _../generic-service.jsonnet_ file, and a **deployment** using the _../generic-deployment.jsonnet_

### Usage

So, how do you generate your helloworld manifest ?
```bash
cd jsonnet/helloworld

jsonnet --ext-code-file env=dev.jsonnet \
        --ext-str commit=$(git describe  --always --tags --long --abbrev=8) \
        --ext-str namespace="" template.jsonnet
```

*   `ext-code-file` is the file to load as the environment file and is stores into the variable env
*   `ext-str` allows to set a variable from the command line

the cool this is that this command does NOT depend on the application you’re trying to build. Just _cd ../app-2_ and use the same command to build your template.

### Customization

Let’s say you want a GRPC port along your HTTP port for the Helloworld application ?

Let’s change the jsonnet/helloworld/template.jsonnet file :

*  add the code to marshal the generic-service.jsonnet again, with a different port name (add)
   ```json
       local serviceGrpc = (import "../generic-service.jsonnet") + {  
         config: localApp,  
         portName: "grpc"  
       };
   ```

*  add this now port to the list of things you want to dump (replace old line):
   ```json
   // final list of all manifests
   local all = [deployment.deployment, serviceGrpc.service, serviceHttp.service];
   ```

### Conclusion

I think that whatever I do/say, Jsonnet will always be complicated. I’ve been doing a lot of Go Templates and Jinja2 (Ansible), and, sadly, yes, Jsonnet is less interesting to read.

But when it comes to Kubernetes, where the alternatives are Helm and Kustomize, you quickly understant that Jsonnet have tons of benefits.

I hope you’ll give a try to Jsonnet and won’t blame me for pushing you about it :)

+++
title = "Sebastien (Prune) THOMAS — Resume"
slug = "resume"
description = "Resume of Sebastien THOMAS — Lead Platform Engineer (DevOps / SRE)"
date = 2026-10-22
layout = "resume"
pdf = "/resume-en.pdf"
pdfLabel = "Download PDF"
+++

**Lead Platform Engineer (DevOps / SRE)**

Lévis, Québec, Canada · +1 (581) 307-8232 · [cv@lecentre.net](mailto:cv@lecentre.net)
[github.com/prune998](https://github.com/prune998) · [piratemakers.ca/posts](https://piratemakers.ca/posts/)

---

## Profile

SRE and production-engineering profile with **25+ years** operating production internet infrastructure — from the bare-metal hosting era (AOL, RTL) to Kubernetes fleets across AWS, GCP, and Azure.

I build the automation that takes infrastructure from installed to reliably in production: **CI/CD, GitOps with Argo CD, observability, and lifecycle tooling** — with a bias for turning manual toil and recurring failures into automated detection and repair.

Switched to **Go development** and now AI. I'm currently building an AI-driven **"Platform Factory"** that automates platform operations and deployments remediations end to end.

## Highlights

- **25+ years running production infrastructure** — Linux/Solaris/UNIX systems engineering since 1998, hands-on from physical-server hosting (Club-Internet, Freesbee, AOL, RTL) through cloud-native fleets.
- **Golang (Go)** for production automation and services — provisioning, CI/CD, monitoring, load-testing and general tools.
- **Kubernetes early adopter**; multi-cloud fleets (Kops on AWS, GKE, Azure AKS); **GitOps at fleet scale: Argo CD (contributor), Kargo, custom ApplicationSets**.
- **Production reliability:** SRE field engineering at Tetrate (Istio/Envoy); observability migrations (Prometheus/Thanos → VictoriaMetrics, Grafana, Loki); HTTP/2 + gRPC load-testing tooling.
- **OSS:** KubeColor maintainer; patches/features for Cilium, Stern, Argo CD, cert-manager...
- **CNCF Ambassador** (2024–), KubeCon speaker, meetup organizer — clear communication, cross-team ownership.

## Technical Skills

- **Languages:** Go, Python (past), C, JavaScript/HTML/CSS.
- **Kubernetes & Fleet Automation:** early adopter — Kops on AWS, GKE, Azure AKS; Operators, Helm; Argo CD (ApplicationSets), Kargo promotions; multi-tenant shared hosting platforms.
- **Production Reliability & Observability:** Prometheus, Thanos, VictoriaMetrics, Grafana, Loki, Fluentd, Jaeger, Zipkin, SkyWalking; incident response and root-cause analysis in SRE roles; load-testing (HTTP/2, gRPC).
- **Linux & Server Lifecycle:** Linux/UNIX engineering since 1998 — architecture, provisioning, and maintenance of hosting infrastructure at scale.
- **Networking:** TCP/IP, gRPC, HTTP/2, most internet protocols.
- **Cloud:** AWS, GCP, Azure; Docker, and Cloud Native ecosystem, Cloudflare.
- **Data & Streaming:** Kafka, ZooKeeper, NATS, etcd, Redis, MongoDB, PostgreSQL, MySQL, Elasticsearch (ELK), Cassandra, Hadoop.
- **AI:** Claude, Zed, Opencode, Llamacpp, Agents, Agent-gateway, skills

## Work Experience

### Lead Software Engineer — Wunderkind (2022 – Present)

Infrastructure/Platform Team

- Building an AI-driven "Platform Factory": agentic automation that turns recurring platform operations into autonomous workflows.
- Own developer-facing infrastructure abstractions: Terraform, Kubernetes, GCP, Helm, CI/CD across GitLab and GitHub — product teams ship without touching raw infrastructure.
- Led the GitLab→GitHub migration: GitHub Actions, Argo CD, Kargo promotions, custom Argo ApplicationSets — fleet-wide GitOps delivery.
- Migrated observability from Prometheus/Thanos to VictoriaMetrics, Grafana, and Loki.

*Tech: Kubernetes, GCP, Terraform, Helm, Argo CD, Kargo, GitHub Actions, VictoriaMetrics, Grafana, Loki, Claude (agentic AI).*

### Lead Software Engineer — The New York Times (2020 – 2022)

Delivery Platform Team, serving all NYT services

- Built a shared, multi-tenant hosting platform on Kubernetes with Cilium.
- Extended CI/CD capabilities platform-wide: Terraform, Drone, Kubernetes, Vault.
- Drove cloud rationalization across GCP and AWS.

*Tech: Kubernetes, Cilium, Terraform, Drone, Vault, GCP, AWS.*

### Customer & Site Reliability Engineer — Tetrate (2019 – 2020)

Extended Service Mesh across platforms (Istio/Envoy field engineering)

- Worked directly with customer dev teams to adapt the product to their environments and specific needs.
- Improved CI/CD and testing to ship a more robust product to customers.
- Turned field learnings into tested use cases, features, and documentation.

*Tech: Kubernetes, AWS, GCE, Istio, Envoy, SkyWalking, CircleCI, Prometheus, Grafana, Go, gRPC, Terraform, Vault.*

### Lead DevOps — Coyote (2017 – 2019)

Community-based driving-assistant appliance and mobile app

- Built the Kubernetes-based multi-cloud fleet (Kops on AWS, GKE, Azure AKS).
- Delivered streamlined automation tooling: CI/CD, infrastructure-as-code, monitoring.
- Deployed production-grade Service Mesh (Istio) and Operators.
- Contributed to the microservice architecture in a data-streaming environment (Kafka, NATS, gRPC).
- Built load-testing and deployment tooling for HTTP/2 and gRPC client-to-server traffic.
- Mentored and trained ~20 people (dev, ops, run, QA) on cloud-native tools and the twelve-factor microservice paradigm.

*Tech: Kubernetes, Istio, Envoy, GCE, AWS, Azure, ZooKeeper, Kafka, NATS, etcd, GitLab CI, Prometheus, Grafana, Ansible, Jsonnet, Helm, Go, Vue.js.*

### DevOps Engineer — Ticketmaster / LiveNation (2016 – 2017)

Event ticketing platform · System & DevOps worldwide team, London (UK)

- Automated the infrastructure and drove the switch to AWS and Kubernetes.

*Tech: GitLab CI workflows, Chef cookbooks, Terraform, AWS.*

### Lead Infrastructure Architect — AXA (2013 – 2016)

Insurance and banking

- Created a multi-cloud platform hosting a large-scale CMS application, enabling AXA entities to rapidly publish customer-facing websites.
- Automated build and deployment of applications (Java, Scala, Node.js) with Ansible, Docker, and Python.
- Migrated Docker deployments to OpenShift.
- Recruited and led a 6-person ops team across France and Hong Kong.

*Tech: Elasticsearch (ELK), Redis, MongoDB, ZooKeeper, Kafka, Docker, Cassandra, Hadoop, Nginx, HAProxy, Python, Ansible, Centreon, InfluxDB, Jenkins, Java, Scala, Node.js, AWS (EC2, S3, SES), LDAP, Ubuntu Linux, Btrfs, Tomcat, Jetty, Git, VMware ESX, OpenShift.*

## Earlier Career (1998 – 2013)

- **UNIX System Engineer — AOL** (2002–2004): technical expertise, architecture, and maintenance of the hosting infrastructure — physical-server-era operations at internet scale ("expert Sybase DBA" training).
- **Lead System & Network Manager — RTL** (2006–2009): France's largest radio broadcaster. Designed the infrastructure and managed a team of 8. Presented the first Oracle 11g French setup at Oracle OpenWorld 2009.
- **UNIX / network engineering 1998–2013:** Club-Internet (Grolier/Lagardère), None Networks, Kaptech, BT France / Azur-Multimedia / Nokia (contractor), Active Telecom (VoIP), SPI / Lucien Barrière, DJJ Consultants, Université Laval (1998 placement). Full history available.

## Education

- **1998** — DUT, Systems & Networks Administration — Université de Provence (Marseille Luminy)
- **1995** — Baccalauréat, Industrial Sciences (computers & electronics), *with honors* — Lycée de Haute Provence

## Languages

French (native) · English (fluent — spoken, written, technical)

## Community & Interests

CNCF Ambassador (2024–) · CNCF/K8s meetup organizer (Eastern Canada & Canada) · KubeCon speaker · Technical blogger at piratemakers.ca · Woodworking, ice hockey, 3D printing, DJing.

## References

Available on request.

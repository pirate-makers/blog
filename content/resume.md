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

Switched to **Go development** and building with AI. I'm currently working on an AI-driven **"Platform Factory"** that automates platform operations and deployments remediations end to end.

## Highlights

- **25+ years running production infrastructure** — Linux/Solaris/UNIX systems engineering, hands-on from physical-server hosting (Club-Internet, Freesbee, AOL, RTL) through cloud and cloud-native fleets.
- **Golang (Go)** for production automation and services — provisioning, CI/CD, monitoring, load-testing and general tools.
- **Kubernetes early adopter**; multi-cloud fleets (Kops on AWS, GKE, Azure AKS); **GitOps at fleet scale: Argo CD (contributor), Kargo, custom ApplicationSets**.
- **Production reliability:** SRE field engineering at Tetrate (Istio/Envoy); observability migrations (Prometheus/Thanos → VictoriaMetrics, Grafana, Loki); HTTP/2 + gRPC load-testing tooling.
- **OSS:** KubeColor maintainer; patches/features for Cilium, Stern, Argo CD, cert-manager...
- **CNCF Ambassador** (2024–), KubeCon speaker, meetup organizer — clear communication, cross-team ownership.

## Technical Skills Summary

- **Languages:** Go, Python (past), C, JavaScript/HTML/CSS.
- **Kubernetes & Fleet Automation:** early adopter — Kops on AWS, GKE, Azure AKS; Operators, Helm; Argo CD (ApplicationSets), Kargo promotions; multi-tenant shared hosting platforms.
- **Production Reliability & Observability:** Prometheus, Thanos, VictoriaMetrics, Grafana, Loki, Fluentd, Jaeger, Zipkin, SkyWalking; incident response and root-cause analysis in SRE roles; load-testing (HTTP/2, gRPC).
- **Linux & Server Lifecycle:** Linux/UNIX engineering — architecture, provisioning, and maintenance of hosting infrastructure at scale.
- **Networking:** TCP/IP, gRPC, HTTP/2, most internet protocols.
- **Cloud:** AWS, GCP, Azure; Docker, and Cloud Native ecosystem, Cloudflare.
- **Data & Streaming:** Kafka, ZooKeeper, NATS, etcd, Redis, MongoDB, PostgreSQL, MySQL, Elasticsearch (ELK), Cassandra, Hadoop.
- **AI:** Claude, Gemini and local AI, Opencode, Llamacpp, Agents, Agent-gateway, MCP and skills

## Work Experience

### Lead Software Engineer — Wunderkind (2022 – Present)

Infrastructure/Platform Team

- Building an AI-driven "Platform Factory": agentic automation that turns recurring platform operations into autonomous workflows.
- Owned developer-facing infrastructure abstractions: Terraform, Kubernetes, GCP, Helm, CI/CD across GitLab and GitHub — product teams ship without touching raw infrastructure and 95% without infra team help.
- Led the 10 year old GitLab+CI/CD to GitHub+Actions migration: 700 repos moved, CI with GH actions, CD with Argo CD, Kargo promotions, custom Argo ApplicationSets and repository discovery — fleet-wide GitOps delivery.
- Migrated observability from Prometheus/Thanos to VictoriaMetrics, Grafana, and Loki, cutting down 99% of false positive oncalls and alerts.
- Created Internal Developper Platform (IDP) and Application Registry and AI tooling to standardize our repos. Allowing 80% faster project boostrap.

*Tech: Kubernetes, GCP, Terraform, Helm, Argo CD, Kargo, GitHub Actions, VictoriaMetrics, Grafana, Loki, Claude (agentic AI), Go.*

### Lead Software Engineer — The New York Times (2020 – 2022)

Delivery Platform Team, serving all NYT services

- Built a shared, multi-tenant hosting platform on Kubernetes with Cilium to host all NYT applications, allowing fast deployment cycles.
- Extended CI/CD capabilities platform-wide: more CI/CD metrics, enhanced reliability, prepared for GitOps.
- Drove cloud rationalization across GCP and AWS, enhancing security and limitting privileges.

*Tech: Kubernetes, Cilium, Terraform, Drone, Vault, GCP, AWS, ArgoCD.*

### Customer & Site Reliability Engineer — Tetrate (2019 – 2020)

Extended Service Mesh across platforms (Istio/Envoy field engineering)

- Worked directly with customer dev teams (Fico, Sony) to improve Istio and Service Mesh performance at large scale.
- Improved CI/CD and testing to ship a more robust product to customers.
- Turned field learnings into tested use cases, features, and documentation.
- Gave Istio, Envoy and Service-Mesh training to customers

*Tech: Kubernetes, AWS, GCE, Istio, Envoy, SkyWalking, CircleCI, Prometheus, Grafana, Go, gRPC, Terraform, Vault.*

### Lead DevOps — Coyote (2017 – 2019)

Community-based driving-assistant appliance and mobile app (like Waze)

- Built the Kubernetes-based multi-cloud fleet (Kops on AWS, GKE, Azure AKS) to host the new rewrite of the old platform, delivering 800x better performances.
- Delivered streamlined automation tooling: CI/CD, infrastructure-as-code, monitoring.
- Deployed production-grade Service Mesh (Istio) and Operators.
- Contributed to the microservice architecture development in a data-streaming environment (Kafka, NATS, gRPC).
- Built load-testing and deployment tooling for HTTP/2 and gRPC client-to-server traffic, allowing continuous testing and performance improvments.
- Mentored and trained ~20 people (dev, ops, run, QA) on cloud-native tools and the twelve-factor microservice paradigm.

*Tech: Kubernetes, Istio, Envoy, GCE, AWS, Azure, ZooKeeper, Kafka, NATS, etcd, GitLab CI, Prometheus, Grafana, Ansible, Jsonnet, Helm, Go, Vue.js.*

### DevOps Engineer — Ticketmaster / LiveNation (2016 – 2017)

Event ticketing platform · System & DevOps worldwide team, London (UK)

- Automated the infrastructure and drove the switch to AWS and Kubernetes.

*Tech: GitLab CI workflows, Chef cookbooks, Terraform, AWS.*

### Lead Infrastructure Architect — AXA (2013 – 2016)

Creating per-agence hosting service for worldwide AXA Insurance and banking agencies. Using Big-Data for per-customer/per-country customization.

- Created a multi-cloud platform hosting a large-scale CMS application, enabling AXA entities to rapidly publish customer-facing websites.
- Automated build and deployment of applications (Java, Scala, Node.js) with Ansible, Docker, and Python.
- Migrated Docker deployments to Kubernetes/OpenShift.
- Recruited and led a 6-person ops team across France and Hong Kong.

*Tech: Elasticsearch (ELK), Redis, MongoDB, ZooKeeper, Kafka, Docker, Cassandra, Hadoop, Nginx, HAProxy, Python, Ansible, Centreon, InfluxDB, Jenkins, Java, Scala, Node.js, AWS (EC2, S3, SES), LDAP, Ubuntu Linux, Btrfs, Tomcat, Jetty, Git, VMware ESX, OpenShift.*

## Earlier Career (1998 – 2013)

- **UNIX System Engineer — AOL** (2002–2004): technical expertise, architecture, and maintenance of the hosting infrastructure in France — physical-server-era operations at internet scale ("expert Sybase DBA" training).
- **Lead System & Network Manager — RTL** (2006–2009): France's largest radio broadcaster. Built hosting and streaming platform and first 100% digital studio. Platform team manager of 8 engineers. Presented first Oracle 11g French setup at Oracle OpenWorld 2009.
- **UNIX / network engineering 1998–2013:** Club-Internet (Grolier/Lagardère), None Networks, Kaptech, BT France / Azur-Multimedia / Nokia (contractor), Active Telecom (VoIP), SPI / Lucien Barrière, DJJ Consultants, Université Laval (1998 placement). Full history available.

## Education

- **1998** — DUT (University Technical Diploma), Systems & Networks Administration — Université de Provence (Marseille Luminy, France)
- **1995** — Baccalauréat, Industrial Sciences (computers & electronics), *with honors* — Lycée de Haute Provence (France)

## Languages

French (native) · English (fluent — spoken, written, technical)

## Community & Interests

CNCF Ambassador (2024–) · CNCF/K8s meetup organizer (Eastern Canada & Canada) · KubeCon speaker · Technical blogger at piratemakers.ca · Woodworking, ice hockey, 3D printing, DJing.

## References

Available on request.

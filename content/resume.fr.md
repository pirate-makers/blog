+++
title = "Sebastien (Prune) THOMAS — CV"
slug = "resume"
description = "CV de Sebastien THOMAS — Ingénieur responsable de plateforme informatique  (Tech Lead / DevOps / SRE)"
date = 2026-10-22
layout = "resume"
pdf = "/resume-fr.pdf"
pdfLabel = "Télécharger le PDF"
+++

**Ingénieur responsable de plateforme informatique (Lead Engineer, Tech Lead, DevOps / SRE)**

Lévis, Québec, Canada · +1 (581) 307-8232 · [cv@lecentre.net](mailto:cv@lecentre.net)
[github.com/prune998](https://github.com/prune998) · [piratemakers.ca/posts](https://piratemakers.ca/posts/)

---

## Profil

Profil SRE et ingénierie de production avec **plus de 25 ans** d'exploitation d'infrastructures Internet — de l'ère de l'hébergement sur serveurs physiques (AOL, RTL) aux cloud Kubernetes sur AWS, GCP et Azure.

Je construis l'automatisation qui fait passer une infrastructure de « installée » à « fiable en production » : **CI/CD, GitOps avec Argo CD, observabilité et outillage du cycle de vie** — avec une obsession : transformer le travail manuel et les pannes récurrentes en détection et réparation automatisées.

**Développement Go** et désormais l'IA. Je construis actuellement une **« Platform Factory »** pilotée par l'IA qui automatise de bout en bout les opérations de plateforme et la remédiation des déploiements.

## Faits saillants

- **Plus de 25 ans d'exploitation d'infrastructures de production** — ingénierie systèmes Linux/Solaris/UNIX depuis 1998, de l'hébergement sur serveurs physiques (Club-Internet, Freesbee, AOL, RTL) aux flottes cloud-native.
- **Golang (Go)** pour l'automatisation de production et les services — provisioning, CI/CD, monitoring, outils de test de charge et outillage général.
- **Adopteur précoce de Kubernetes** ; flottes multi-cloud (Kops sur AWS, GKE, Azure AKS) ; **GitOps à l'échelle de la flotte : Argo CD (contributeur), Kargo, ApplicationSets sur mesure**.
- **Fiabilité en production :** ingénierie / SRE chez Tetrate (Istio/Envoy) ; migrations d'observabilité (Prometheus/Thanos → VictoriaMetrics, Grafana, Loki) ; outillage de test de charge HTTP/2 + gRPC.
- **OSS :** mainteneur de KubeColor ; correctifs et fonctionnalités pour Cilium, Stern, Argo CD, cert-manager…
- **Ambassadeur CNCF** (depuis 2024), conférencier KubeCon, organisateur de meetups — communication claire, responsabilité transverse.

## Compétences techniques

- **Langages :** Go, Python (par le passé), C, JavaScript/HTML/CSS.
- **Kubernetes & automatisation Cloud :** Kops sur AWS, EKS, GKE, Azure AKS ; Operators, Helm ; Argo CD (ApplicationSets), promotions Kargo ; plateformes d'hébergement mutualisées multi-locataires.
- **Fiabilité & observabilité de production :** Prometheus, Thanos, VictoriaMetrics, Grafana, Loki, Fluentd, Jaeger, Zipkin, SkyWalking ; réponse aux incidents et analyse de causes en rôle SRE ; test de charge (HTTP/2, gRPC).
- **Linux & cycle de vie des serveurs :** ingénierie Linux/UNIX — architecture, provisioning et maintenance d'infrastructures d'hébergement à grande échelle.
- **Réseaux :** TCP/IP, gRPC, HTTP/2, la plupart des protocoles Internet.
- **Cloud :** AWS, GCP, Azure ; Docker et l'écosystème Cloud Native, Cloudflare.
- **Données & streaming :** Kafka, ZooKeeper, NATS, etcd, Redis, MongoDB, PostgreSQL, MySQL, Elasticsearch (ELK), Cassandra, Hadoop.
- **IA :** Claude, Zed, Opencode, Llamacpp, Agents, Agent-gateway, skills

## Expérience professionnelle

### Lead Software Engineer — Wunderkind (2022 – aujourd'hui)

Équipe Infrastructure/Plateforme

- Construction d'une « Platform Factory » pilotée par l'IA : automatisation agentique qui transforme les opérations de plateforme récurrentes en flux de travail autonomes.
- Maintien des abstractions d'infrastructure orientées développeurs : Terraform, Terragrunt, Kubernetes, GCP, Helm, CI/CD sur GitLab et GitHub — les équipes produit livrent sans toucher à l'infrastructure brute.
- Pilotage de la migration GitLab→GitHub : GitHub Actions, Argo CD, promotions Kargo, ApplicationSets Argo sur mesure — livraison GitOps à l'échelle de la flotte.
- Migration de l'observabilité de Prometheus/Thanos vers VictoriaMetrics, Grafana et Loki.
- Creation et deployment d'une plateforme de developement interne et d'un registre d'applications (Go, Webhooks, Actions).

*Tech : Kubernetes, GCP, Terraform, Helm, Argo CD, Kargo, GitHub Actions, VictoriaMetrics, Grafana, Loki, Claude (IA agentique).*

### Lead Software Engineer — The New York Times (2020 – 2022)

Équipe Delivery Platform, au service de tous les services du NYT

- Construction d'une plateforme d'hébergement mutualisée multi-locataires sur Kubernetes avec Cilium.
- Extension des capacités CI/CD à l'échelle de la plateforme : Terraform, Drone, Kubernetes, Vault.
- Pilotage de la rationalisation cloud entre GCP et AWS.

*Tech : Kubernetes, Cilium, Terraform, Drone, Vault, GCP, AWS.*

### Ingénieur client & fiabilité de production (SRE) — Tetrate (2019 – 2020)

Extension du Service Mesh sur les plateformes (ingénierie de terrain Istio/Envoy)

- Travail direct avec les équipes de développement clientes pour adapter le produit à leurs environnements et besoins spécifiques.
- Amélioration du CI/CD et des tests pour livrer un produit plus robuste aux clients.
- Transformation des apprentissages de terrain en cas d'usage testés, fonctionnalités et documentation.

*Tech : Kubernetes, AWS, GCE, Istio, Envoy, SkyWalking, CircleCI, Prometheus, Grafana, Go, gRPC, Terraform, Vault.*

### Lead DevOps — Coyote (2017 – 2019)

Assistant d'aide à la conduite communautaire (boîtier embarqué et application mobile)

- Construction de la flotte multi-cloud basée sur Kubernetes (Kops sur AWS, GKE, Azure AKS).
- Livraison d'un outillage d'automatisation rationalisé : CI/CD, infrastructure-as-code, monitoring.
- Déploiement d'un Service Mesh (Istio) et d'Operators de qualité production.
- Contribution à l'architecture microservices dans un environnement de flux de données (Kafka, NATS, gRPC).
- Construction d'outils de test de charge et de déploiement pour le trafic client-serveur HTTP/2 et gRPC.
- Formation et mentorat d'une vingtaine de personnes (dev, ops, run, QA) sur les outils cloud-native et le paradigme microservices twelve-factor.

*Tech : Kubernetes, Istio, Envoy, GCE, AWS, Azure, ZooKeeper, Kafka, NATS, etcd, GitLab CI, Prometheus, Grafana, Ansible, Jsonnet, Helm, Go, Vue.js.*

### Ingénieur DevOps — Ticketmaster / LiveNation (2016 – 2017)

Plateforme de billetterie · Équipe Système & DevOps mondiale, Londres (Royaume-Uni)

- Automatisation de l'infrastructure et pilotage de la migration vers AWS et Kubernetes.

*Tech : workflows GitLab CI, cookbooks Chef, Terraform, AWS.*

### Architecte d'infrastructure principal — AXA (2013 – 2016)

Assurance et banque

- Création d'une plateforme multi-cloud hébergeant une application CMS à grande échelle, permettant aux entités AXA de publier rapidement des sites web orientés clients.
- Automatisation du build et du déploiement des applications (Java, Scala, Node.js) avec Ansible, Docker et Python.
- Migration des déploiements Docker vers OpenShift (Kubernetes).
- Recrutement et management d'une équipe de 6 ingénieurs ops répartie entre la France et Hong Kong.

*Tech : Elasticsearch (ELK), Redis, MongoDB, ZooKeeper, Kafka, Docker, Cassandra, Hadoop, Nginx, HAProxy, Python, Ansible, Centreon, InfluxDB, Jenkins, Java, Scala, Node.js, AWS (EC2, S3, SES), LDAP, Ubuntu Linux, Btrfs, Tomcat, Jetty, Git, VMware ESX, OpenShift.*

## Début de carrière (1998 – 2013)

- **Ingénieur systèmes UNIX — AOL** (2002–2004) : expertise technique, architecture et maintenance de l'infrastructure d'hébergement — opérations de l'ère des serveurs physiques à l'échelle d'Internet (formation « expert Sybase DBA »).
- **Responsable systèmes & réseaux — RTL** (2006–2009) : la plus grande station de radio de France. Conception de l'infrastructure et management d'une équipe de 8 personnes. Présentation de la première installation française d'Oracle 11g à Oracle OpenWorld 2009.
- **Ingénierie UNIX / réseaux 1998–2013 :** Club-Internet (Grolier/Lagardère), None Networks, Kaptech, BT France / Azur-Multimedia / Nokia (prestataire), Active Telecom (VoIP), SPI / Lucien Barrière, DJJ Consultants, Université Laval (stage 1998). Historique complet disponible.

## Formation

- **1998** — DUT, Administration Systèmes & Réseaux — Université de Provence (Marseille Luminy)
- **1995** — Baccalauréat, Sciences industrielles (informatique & électronique), *avec mention* — Lycée de Haute Provence

## Langues

Français (langue maternelle) · Anglais (courant — parlé, écrit, technique)

## Communauté & centres d'intérêt

Ambassadeur CNCF · Organisateur de meetups CNCF/K8s (Est du Canada & Canada) · Conférencier KubeCon · Blogueur technique sur piratemakers.ca · Menuiserie, hockey sur glace, impression 3D, DJing.

## Références

Disponibles sur demande.

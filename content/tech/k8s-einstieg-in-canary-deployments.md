---
categories:
- tech
comments: true
date: "2019-08-01T16:00:00+08:00"
description: Aufbau einer DevOps-Pipeline für eine Multiservice-Anwendung in Kubernetes 
draft: true
tags:
- devops
- docker
- gcp
- k8s
title: Einstieg in Canary Deployments
type: post
images:
  - src: y2019/k8s-deployment-overview-1.png
    width: 1000
    height: 560
    title: Microservice-Architektur der Beispielanwendung
    orientation: l
    type: screenshot
    featured: false
  - src: y2019/k8s-deployment-overview-2.png
    width: 1000
    height: 560
    title: Microservice-Architektur mit Canary-Deployments
    orientation: l
    type: screenshot
    featured: false
  - src: y2019/k8s-canary-master-deployment.png
    width: 953
    height: 570
    title: Das erfolreiche master-Deployment stellt alle Bilder grün dar
    orientation: l
    type: screenshot
    featured: false
  - src: y2019/k8s-canary-simple-lb-1.png
    width: 953
    height: 570
    title: 
    orientation: l
    type: screenshot
    featured: false
    group: k8s-lb
  - src: y2019/k8s-canary-simple-lb-2.png
    width: 953
    height: 570
    title: 
    orientation: l
    type: screenshot
    featured: false
    group: k8s-lb
  - src: y2019/k8s-canary-simple-lb-3.png
    width: 953
    height: 570
    title: 
    orientation: l
    type: screenshot
    featured: false
    group: k8s-lb
---

## Abstract

Dieser Beitrag hat das Ziel, alle notwendigen Schritte aufzuzeigen, mit denen man eine DevOps-Pipeline in einem Kubernetes-Cluster aufbaut. Grundlegend basiert dies auf der sehr ausführlichen [Anleitung in der GCP-Doku](https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build). Dabei wurde das Beispiel erweitert, um ein realistischeres Anwendungsszenario abzudecken: eine moderne Anwendung mit zugrundeliegender Microservices-Architektur die mit Canary-Deployments zu schnellen Production-Deployments führt und dabei die Gesamtqualität der Anwendung nur in einem kontrollierten Rahmen gefährdet. Dabei zeige ich die Herausforderungen auf, vor die uns ein klassisches Kubernetes-Cluster stellt.

## Problemstellung

Das zuvor genannte, umfassende Tutorial deckt meiner Meinung nach nicht den Use-Case moderner Softwarearchitekturen ab. Daher habe ich eine Beispielanwendung gebaut, die aus insgesamt drei Komponenten besteht. Es gibt ein _frontend_, welches neben der Website auch noch einen Endpunkt mit dynamischen Grafiken anbietet (`/local/*`). Die Startseite bindet dabei Bilder von diesem lokalen Service ein. Zusätzlich referenziert die Seite aber auch einen weiteren Endpunkt im _frontend_ (`/remote/*`), der Bilder von zwei entfernten Microservices (_rectangle_ und _circle_) abfragt. Neben dem automatischen Deployment drei verschiedener Komponenten ist eine Herausforderung, wie in solch einer Architektur _canary_-Deployments realisiert werden.

{{< screenshot "y2019/k8s-deployment-overview-1.png" >}}

## Einrichtung einer DevOps-Pipeline

Alle folgenden Schritte basieren auf einer Implementierung in der _Google Cloud Platform_ (_GCP_), da die angebotenen Services wirklich gut verzahnt sind und schnelle Erfolge bei geringsten Kosten versprechen. Für das Nachvollziehen der Schritte reicht es, ein neues Projekt anzulegen und sich in der Web-Console die _Cloud Shell_ zu öffnen. Das zugehörige Git Repo befindet sich auf [GitHub](https://github.com/adulescentulus/k8s-canary-example)

### APIs aktivieren

In dem Projekt müssen einige APIs aktiviert werden:

```
  gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    sourcerepo.googleapis.com \
    containeranalysis.googleapis.com
```

### Einen k8s-Cluster bereitstellen

Mit einem Befehl kann ein neuer Cluster konfiguriert werden. Ich habe mich hier auf die Zone `europe-west4-b` festgelegt und die Pipelinekonfiguration ist darauf abgestimmt. Zur Verringerung der Kosten nutze ich immer _preemptible_ Nodes, da diese geringere Kosten verursachen.

```
  gcloud container clusters create canary-example \
     --num-nodes 2 --preemptible --zone europe-west4-b
```

### Git konfigurieren

Falls nicht schon früher geschehen müssen wir Git für unseren Nutzer noch konfigurieren.

```sh
git config --global user.email "[YOUR_EMAIL_ADDRESS]"
git config --global user.name "[YOUR_NAME]"
```

### Zwei neue Git Repos anlegen

Das Beispiel ist für zwei Git Repos konfiguriert, die im Kontext des Projekts angelegt werden. Diese legen wir nun an.

```
gcloud source repos create canary-example
gcloud source repos create canary-env
```

### Das Beispiel-Repo klonen

Mein Beispiel-Repo wird nun in das GCP-Repo geklont

```sh
cd ~
git clone https://github.com/adulescentulus/k8s-canary-example.git canary-example
cd ~/canary-example
PROJECT_ID=$(gcloud config get-value project)
git remote add google \
    "https://source.developers.google.com/p/${PROJECT_ID}/r/canary-example"
git push google master
git push google canary:canary
```

### Berechtigung erteilen für den Zugriff auf die Kubernetes Engine

```sh
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer
```

### Deployment-Repo einrichten

Die aktive k8s-Konfiguration liegt in dem Repo _canary-env_. Dieses wird nun mit Dateien aus dem _canary-example_ Repo initialisiert.

```sh
cd ~
gcloud source repos clone canary-env
cd ~/canary-env
git checkout -b production
cd ~/canary-env
cp -R ~/canary-example/env-template/* ~/canary-env/
git add .
git commit -m "Create cloudbuild.yaml and folders for deployment"
git checkout -b candidate
git push origin production
git push origin candidate
```

### Schreibzugriff für Cloud Build auf Repo

Damit die Pipeline funktioniert, muss _Cloud Build_ Git Commits im Repo _canary-env_ durchführen. Diese Berechtigung müssen wir auch noch erteilen.

```sh
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} \
    --format='get(projectNumber)')"
cat >/tmp/canary-env-policy.yaml <<EOF
bindings:
- members:
  - serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com
  role: roles/source.writer
EOF
gcloud source repos set-iam-policy \
    canary-env /tmp/canary-env-policy.yaml
```

### Automatisches Deployment konfigurieren

Ein Build unserer Applikationen in _canary-example_ schreibt die gewünschte k8s-Konfiguration in das _canary-env_ Repo. Dies löst einen automatischen Bau aus. Dafür konfigurieren wir in _Cloud Build_ einen neuen Trigger für das Projekt _canary-env_:

- Name: Push to candidate
- Branch (regex): candidate
- Build configuration: cloudbuild.yaml

### Automatische Builds für die Services

In dem Quell-Repo _canary-example_ sind ingesamt drei eigenständige Services untergebracht. Um nun das Bauen dieser anzustoßen, müssen nun drei Build Trigger für den _master_-Branch angelegt werden, hier beispielhaft für das _frontend_:

- Name: "frontend: Push to master"
- Branch (regex): master
- Included files filter: frontend/*
- Build configuration: frontend/cloudbuild.yaml

Diese drei Trigger kann man nun nacheinander manuell ausführen. Wichtig ist aber, dass die Builds nicht gleichzeitig starten (der Zeitabstand von einer Minute je Build hat sich bewährt), denn alle drei Builds schreiben in das _canary-env_ Repo und das kann nicht gleichzeitig funktionieren.

Zur Vorbereitung legen wir noch zwei Trigger für den _canary_-Branch an von den Services _frontend_ und _rectangle_:

- Name: "frontend: Push to canary"
- Branch (regex): canary
- Included files filter: frontend/*
- Build configuration: frontend/cloudbuild.yaml

Diese führen wir aber noch nicht aus!

### Anwendung prüfen

Nach dem Anstoßen der drei Builds sollten diese erfolgreich gelaufen sein und insgesamt drei Builds von _canary-env_ ausgelöst haben. Ein Besuch der _GKE_ Services-Seite sollte nun eine öffentliche IP mit Load-Balancer für unseren Service _frontend_ zeigen. Rufen wir diese auf, dann sollte es so aussehen:

{{< screenshot "y2019/k8s-canary-master-deployment.png" >}}

Die Bilder in der ersten Zeile werden alle durch die _frontend_-Service ausgeliefert. Erst die beiden unteren Zeilen liefern Bilder, die das _frontend_ von den jeweiligen Backends _rectangle_ und _circle_ abruft. Alle Bilder werden in der Version auf _master_ in allen Services in Grün dargestellt.

### Canary-Deployment durchführen

Um nun ein Canary-Deployment durchzuführen bedarf es keiner weiteren, großen Anstrungen. Mit den Build-Triggern für den _canary_-Branch haben wir schon alles vorbereitet. Ein Commit auf diesen Branch würde die Änderungen bauen und im k8s-Cluster ausrollen. Die Änderungen sind aber schon auf dem Branch vorhanden und müssen nun nur noch durch manuelles Auslösen der Build-Trigger ausgerollt werden. Die Builds für _frontend_ und _rectangle_ löst man wieder mit einer Minute Verzögerung aus.

{{< screenshot "y2019/k8s-deployment-overview-2.png" >}}

Das Ergebnis lässt sich nach wenigen Minuten in der _Cloud Console_ prüfen:
```sh
gcloud container clusters get-credentials canary-example --zone europe-west4-b
kubectl get deployment.apps -L branch
```

Das Ergebnis sollte folgende Ausgabe sein:

```
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE     BRANCH
circle-master      1         1         1            1           52m     master
frontend-canary    1         1         1            1           2m47s   canary
frontend-master    1         1         1            1           56m     master
rectangle-canary   1         1         1            1           2m46s   canary
rectangle-master   1         1         1            1           50m     master
```

Das Deployment enthält nun auch Instanzen des _canary_-Branch und kann nun durch Aufruf der Seite erneut getestet werden. Die Canary-Änderung im _frontend_ setzt die Rahmen _aller_ Bilder auf Blau und auch die lokalen Rechtecke werden in der Farbe Blau dargestellt. Die Canary-Änderung für _rectangle_ stellt alle Rechtecke ebenfalls in Blau dar und sollte sich in der zweiten Zeile auswirken. 

Das tatsächliche Ergebnis mehrer Aufrufe der Seite hintereinander sollte ungefähr so aussehen:

{{< screenshot-carousel title="Das Ergebnis des Canary-Deployments nach mehreren Aktualisierungen des Browsers" group="k8s-lb">}}

Das Ergebnis ist also durchwachsen. Jede Aktualisierung gleicht einem wilden Blinken unserer Bilder und wir können ein Problem von Canary-Deployments mit k8s-Bordmitteln feststellen.

## Fehleranalyse

Bei der Fehlerbetrachtung müssen wir zwei Phänomene unterscheiden: Die unterschiedlichen Farben in der ersten Zeile von "Serving local images" und die in der zweiten Zeile, die Rechtecke in "Serving remote images".

Das erste Fehlerbild betrifft die Darstellung von Bildern, die alle, wie auch die `index.html`, vom _frontend_-Service bereitgestellt werden. Allerdings sind für die `index.html` und die vier Bilder insgesamt fünf HTTP-Requests notwendig. Jeder Request hat die Chance entweder vom _master_- oder _canary_-Release bedient zu werden. 

Das zweite Fehlerbild zeigt uns die "Komplexität" unserer Applikation und die Grenzen eines "dummen" Load-Balancers auf. Unsere Services hängen voneinander ab, das heißt, dass ein Zugriff auf das _canary-frontend_ auch einen nachgelagerten Zugriff auf das _canary-rectangle_-Service auslösen müsste. Der Load-Balancer selektiert die Deployments in unserer k8s-Konfiguration nur nach Labels `app=frontend` oder `app=rectangle` und prüft nicht, ob der Request eventuell von einem _canary_-Service initiiert wurde.

Die Lösung dieser beiden Problem ist nach meinem Kenntnisstand nicht trivial und kann eventuell durch einen Ingress-Controller (in Teilen) oder mit einem Service-Mesh wie [istio](https://istio.io) gelöst werden. Meine Lösungen werde ich im Rahmen dieser Artikelserie hier im Blog veröffentlichen.

## Details der Deployment-Pipeline

Zu Beginn habe ich nur die Schritte der Anleitung mit wenig Details weggeschrieben. Ich möchte hier noch auf ein paar Details der Implementierung eingehen. Einige Dinge werden in dem bereits verlinkten [Tutorial der GCP Doku](https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build) erläutert.

### k8s-Konfiguration

Jeder Service ist selbst für eine funktionierende k8s-Konfigurationsdatei verantwortlich. In jedem Projektverzeichnis befindet sich eine `k8s.yaml.tpl` die am Ende des Builds in das _canary-env_-Projekt übertragen wird. Dabei wird in dem Template der aktuelle Branch als Label gesetzt. Ebenso wird der Commit-SHA für das Docker-Image und die _GCP_-Project-ID ersetzt. Die Datei wird dann im Ziel-Repo mit dem Branch als Suffix abgelegt, so dass jeder Branch eine separate Konfiguration besitzt.

Jede Änderung im _canary-env_-Repo führt zu einem _kubectl_-Durchlauf. Es werden immer zuerst alle Canary-Deployments gelöscht und dann alle Konfigurationsdateien in den drei Service-Verzeichnissen angewandt. Das sorgt zwar immer für ein Aus- und Anschalten der Canary-Services, aber so bleibt die Cluster-Konsistenz gewahrt.

### Löschen der Canary-Deployments

Wie zuvor erwähnt führt jeder _canary-env_-Build eine Cluster-Konfiguration durch und löscht Canary-Deployments. Wird nun ein Service auf dem _master_-Branch deployed werden hier _alle_ anderen Branch-Konfigurationen für diesen Service gelöscht, so dass diese nicht mehr neu deployed werden. Das macht auch Sinn. Im Continuous Deployment Lifecycle sollte ein Canary-Feature immer auf _master_ gemerged werden, was das Canary-Deployment überflüssig macht.

### Probleme bei vielen Commits

Die aktuelle Implementierung hat definitiv noch einen Haken: parallele Commits in den einzelnen Services. Dadurch dass jeder Build auch in das _canary-env_-Repo schreibt, kann die parallele Ausführung zu einem unerwarteten Abbruch wegen eines Git-Fehlers führen. Dies läßt sich in _Google Cloud Build_ leider nicht einschränken. Parallele Builds sind definitiv vorgesehen. Man könnte dies nur durch clevere Scripts in der Build-Pipeline beheben.

### Quarkus und GraalVM

Wie auch schon bei meinem [Test von Google Cloud Run]({{< relref "google-cloud-run-ausprobiert" >}}) setze ich konsequent auf [Quarkus](https://quarkus.io), dem "Kubernetes Native Java stack". Die Startzeiten der Container sind phänomenal. Alle Service-Builds in meinem Beispielprojekt laufen wegen der kürzeren Compile-Zeit in einer JVM. In der `cloudbuild.yaml` kann einfach zwischen `Dockerfile.jvm` und `Dockerfile.native` gewechselt werden, um noch weiter von den Optimierungen der _GraalVM_ zu profitieren.

## Fazit

Canary-Deployments in komplexeren Microservice-Architekturen sind leider keine einfache Angelegenheit. Es ist definitiv eine lösbare Aufgabe, wenn man erst einmal alle Probleme vor Augen hat. Diese Artikelserie wird in der Folge hoffentlich mindestens eine Lösung hervorbringen.

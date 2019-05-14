---
aliases:
- /post/google-cloud-run-ausprobiert/
type: post
categories:
- tech
comments: true
date: "2019-04-19T20:50:00+12:00"
description: "Auf der Cloud Next 2019 wurde Cloud Run vorgestellt: Container starten erst bei einem Aufruf und man bezahlt nur für die Dauer des Requests. Meine Erfahrungen."
draft: false
tags:
- devops
- docker
- serverless
- gcp
- graalvm
- spring
- aws
- tutorial
title: Google Cloud Run ausprobiert
images:
  - src: gcp_build_triggers.png
    width: 1498
    height: 446
    title: Übersicht der Build Trigger
    orientation: l
    type: screenshot
  - src: gcp_build_history.png
    width: 2410
    height: 418
    title: Ergebnis eines erfolgreichen Builds
    orientation: l
    type: screenshot
  - src: gcp_run_logs.png
    width: 2062
    height: 472
    title: Logausgaben unseres Microservice in der GCP Console
    orientation: l
    type: screenshot
---

## Abstract

Ich befasse mich mit einem Java-Microservice, welches bei _Google Cloud Run_ deployed wird und betrachte es als Alternative zu _AWS Lambda_. Dabei gehe ich auch auf das Thema Kaltstartzeit der Container ein und befasse mich in diesem Kontext auch mit den Vorteilen der _GraalVM_.

## Google Cloud Next 2019

Dieses Jahr hat Google auf der eigenen Cloud-Messe _Cloud Next_ wieder einige interessante Dinge vorgestellt, darunter _Google Cloud Run_. _Cloud Run_ ermöglicht den Betrieb von Containern als HTTP-Endpunkte nur für die Zeit eines Requests. Daraus leitet Google auch den Preis ab: es wird in 100ms Intervallen abgerechnet, jenachdem wie lang ein Request tatsächlich braucht. Google stellt damit eine einfache Möglichkeit zur Verfügung, überall gleich laufende Container in der Cloud zu geringen Kosten zu betreiben und positioniert sich in meinen Augen als (einfache?) Alternative zu _AWS Lambda_. Wie es sich schlägt, werde ich versuchen hier am Beispiel zu skizzieren.

## Voraussetzungen

Um die folgenden Schritte nachvollziehen zu können braucht man folgendes:

1. ein _Google Cloud Platform_-Konto (GCP)
2. ein neues GCP-Projekt, in dem die Umgebung aufgebaut wird
3. ein funktionierendes Abrechnungskonto, Anleitung in der [Doku](https://cloud.google.com/run/docs/quickstarts/build-and-deploy#before-you-begin)
4. ein eingerichtetes [Cloud SDK](https://cloud.google.com/sdk/)
5. eine installierte _gcloud beta component_ laut [Doku](https://cloud.google.com/run/docs/quickstarts/build-and-deploy), siehe `gcloud components install beta`
4. optional: ein GitHub-Repo-Fork von [gcloud-run-examples](https://github.com/adulescentulus/gcloud-run-examples), um die Docker-Images zu bauen

## Betrieb eines Spring Boot Containers

### Lokale Entwicklung / Test

Für den Test habe ich mir das [Spring Boot Greeting Service](https://spring.io/guides/gs/rest-service/) genommen. Dieses ist in meinem Beispiel-Repo [gcloud-run-examples](https://github.com/adulescentulus/gcloud-run-examples) im Ordner `spring` zu finden. Dies habe ich um ein `Dockerfile` erweitert, welches zuerst das JAR mittels Maven baut. Im gleichen `Dockerfile` wird mittels [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/) das fertige JAR mit seinen Libs in ein minimales OpenJDK-Alpine-Image kopiert. Im Project-Root reicht also folgender Docker-Befehl lokal, um das Anwendungs-Image zu erstellen:

```
docker build -t grolland/greeting-spring .
```

Danach steht das Image zur Verfügung und der Container kann live gestartet werden:

```
docker run --rm -it -p 8080:8080 grolland/greeting-spring
```

Ein einfacher Aufruf von http://localhost:8080/greeting sollte eine Begrüßung im JSON-Format ausgeben.

```
{"id":1,"content":"Hello, World!"}
```

### Google Cloud Build

Damit _Cloud Run_ einen Container starten kann, muss erstmal ein Image dafür existieren. Im vorherigen Schritt haben wir dies nur lokal erzeugt. Man kann das lokale Image zum Beispiel im _Docker Hub_ hochladen. Google bietet aber mit _Cloud Build_ einen Dienst an, um dies alles vollautomatisch im GCP-Umfeld zu erledigen. Das schöne: aktuell hat man täglich 120 Minuten kostenlose Build-Zeit.

In der GCP Console wechselt man also auf _Cloud Build_ und legt einen neuen Trigger an. Dieser sorgt dafür, dass bei jeder Code-Änderung ein neues Build angestoßen wird. Nach der Auswahl von GitHub als Quelle müsst ihr den Zugriff auf euer GitHub-Konto authorisieren. Danach wählt ihr das Repo "gcloud-run-examples" aus. Im Konfigurationsdialog sollte folgendes konfiguriert sein:

{{< table >}}
| Feld                          | Wert | Beschreibung |
---                             | --- | ---
| Name                          | Spring: Push to master |  |
| Trigger type                  | Branch |  |
| Branch (Regex)                | master | |
| Included files filter (glob)  | spring/* | Nur Änderungen in diesem Verzeichnis beobachten|
| Build configuration           | Dockerfile | |
| Dockerfile directory          | /spring/ | Quellverzeichnis für Image |
| Image name                    | gcr.io/###deine-projectid###/gcloud-run-examples/spring:$SHORT_SHA | das kann beliebig gewählt werden |
| Timeout                       | 300 | |
{{< /table >}}

{{< screenshot "gcp_build_triggers.png" >}}

In der Trigger-Übersicht sollte jetzt der Trigger stehen. Dieser wird bei einem Commit getriggert oder man löst ihn manuell mit "Run trigger" aus. In der _Cloud Build_ History im linken Menü sollte nach wenigen Minuten ein erfolgreiches Build stehen und einem fertigen Image-Namen, wie z.B. `gcr.io/gcloud-example-237604/gcloud-run-examples/spring:22d667f`

{{< screenshot "gcp_build_history.png" >}}

### Google Cloud Run Deployment

Jetzt haben wir ein Docker-Image welches mit _Cloud Run_ instanziert werden kann. Den im vorherigen Schritt erzeugten Imagenamen müssen wir kopieren, um dieses nun zu referenzieren. Einfachheitshalber kann man das nun mit einem einzigen Befehl des SDK in _Cloud Run_ deployen:

```
gcloud beta run deploy gcloud-example-spring --image gcr.io/hier-der-vollständige-image-name --concurrency=default --allow-unauthenticated --memory=256Mi --set-env-vars=MaxRAM=256m
```

Dieser Einzeiler erzeugt einen neuen Service mit Namen "gcloud-example-spring", der in einem Container mit 256 MB RAM bereitgestellt wird. Die zusätzliche Umgebungsvariable sagt der JVM, wieviel RAM zur Verfügung steht. Dies ist ein bekannter [Issue](https://cloud.google.com/run/docs/issues#java) bei Google und betrifft das bekannte [Java Container Problem](https://blogs.oracle.com/java-platform-group/java-se-support-for-docker-cpu-and-memory-limits).

Die Ausführung des Befehls erzeugt noch eine Nachfrage, in welcher Region der Dienst deployed werden soll. Dies kann per Kommandozeile eigentlich angeben werden, ermöglicht aber später neu hinzugekommene Regionen leicht zu erkennen. Aktuell wird nur _us-central1_ unterstützt.

Nach kurzer Zeit wird die Kommandozeile eine Adresse ausgeben, wo der Service nun zu finden ist. Ruft man jetzt diese URL auf, so erhalten wir unsere erwartete Antwort:

```sh
time curl https://gcloud-example-spring-zufallsid-uc.a.run.app/greeting
{"id":1,"content":"Hello, World!"}
real	0m16.808s
```

Wiederholt man nun den Aufruf des Webservice, dann ergeben sich Antwortzeiten von wenigen Millisekunden, da der Container und damit die Java-Anwendung bereits initialisiert ist. Man muss dazu sagen, dass ich die Tests aus einer VM im gleichen Rechenzentrum in _us-central1_ gemacht habe. Aus Deutschland dauern die Anfragen über den großen Teich entsprechend länger.

In der _GCP_ Console im Menü unter _Cloud Run_ sieht man den eben deployten Service und kann auch dort die Logs einsehen. Bei dem ersten Start sieht man die Meldungen von Spring Boot und auch die unglaubliche Initialisierungszeit:

```
[ main] hello.Application : Started Application in 11.667 seconds (JVM running for 15.434)
```

Dies kann man für den ersten Versuch hinnehmen, denn anhand der vorgestellten Schritte kan man ganz einfach ein Cloud-Microservice deployen, welches man aufgrund der Docker-Basis überall laufen lassen und einfach migrieren kann. Wer sich damit nicht zufrieden geben will, der fragt sich bestimmt: **Geht das nicht schneller?**

Eine mögliche Lösung beschreibe ich im nächsten Abschnitt.

## Quarkus-Framework als GraalVM Native Application

### Schnelleinstieg

Ohne mich zu lang damit aufzuhalten möchte ich nur kurz schildern, wie ich auf diese Kombination kam. Während des Lesens von IT-/DevOps-News ist mir vor kurzem [der Artikel bei Heise](https://www.heise.de/developer/meldung/Java-Framework-Quarkus-Red-Hat-vereint-reaktive-und-imperative-Programmierung-4328905.html) über _Quarkus_ über den Weg gelaufen und "meine" Themen FaaS, Kubernetes und Cloud-native sind in dem Fall erwähnt worden. Daher habe ich mich im Zuge der Einführung von _Cloud Run_ damit beschäftigt und einige Themen sind schon sehr interessant:

- **Hot Deploy** von Code-Änderungen in der Entwicklung: ein einfaches `mvn quarkus:dev` startet den Server und setzt Code-Änderungen ohne Neustart um
- In Verbindung mit **GraalVM** wird der Code _vorcompiliert_ und optimiert, dies führt als sogenannte _Native Application_ zu extrem geringen Startzeiten

### Lokale Entwicklung / Test

Mein Beispiel basiert wieder auf einem [offiziellen Beispiel](https://quarkus.io/guides/spring-di-guide). Es befindet sich im Beispiel-Repo im Unterordner `quarkus-di` und benutzt ebenfalls Spring-Dependency-Injection.

Die Entwicklung einer Quarkus-Anwendung bringt, wie schon erwähnt, einen Vorteil: _hot code deploy_ bei der lokalen Entwicklung mittels `mvn quarkus:dev`. Um am Ende eine Native Application zu erstellen, führt man `mvn package -Pnative` aus, um für das aktuelle OS eine native Anwendung zu erstellen. Mit unserem Ziel Docker muss diese Anwendung eine 64Bit Linux Executable sein. Dies alles wird in dem beigefügten `Dockerfile` gemacht und wie schon im Spring-Beispiel zuvor reicht ein Docker-Befehl, um das Image zu bauen und zu starten:

```
docker build -t grolland/greeting-quarkus-di .
docker run --rm -it -p 8080:8080 grolland/greeting-quarkus-di
```

Das `Dockerfile` basiert für das Maven-Build auf dem Image `grolland/quarkus-mvn-static:graalvm-1.0.0-rc15`, welches ich auf Basis der [Beispiele](https://github.com/quarkusio/quarkus-images/tree/graalvm-1.0.0-rc14/centos-quarkus-maven) um statische Bibliotheken von _glibc_ und _zlib_ [erweitert](https://github.com/adulescentulus/quarkus-images/commit/471981ddb1fd5fe283537a64bfb9bf4b0b784844) habe, damit die Native Application auch im minimalen Alpine-Umfeld funktioniert.

### Google Cloud Build

Um ein Image in der _GCP_ zu bauen nehmen wir wieder _Cloud Build_ und erstellen einen weiteren Trigger:

{{< table >}}
| Feld                          | Wert | Beschreibung |
---                             | --- | ---
| Name                          | Quarkus-di: Push to master |  |
| Trigger type                  | Branch |  |
| Branch (Regex)                | master | |
| Included files filter (glob)  | quarkus-di/* | Nur Änderungen in diesem Verzeichnis beobachten|
| Build configuration           | Dockerfile | |
| Dockerfile directory          | /quarkus-di/ | Quellverzeichnis für Image |
| Image name                    | gcr.io/###deine-projectid###/gcloud-run-examples/quarkus-di:$SHORT_SHA | das kann beliebig gewählt werden |
| Timeout                       | 600 | |
{{< /table >}}

Wichtig ist der hohe Timeout, da durch den Precompile-Prozess die Erstellung einer Native Application ungleich länger dauert als ein einfaches JAR.

Nach dem erfolgten Build sollte ein neues Image bereitstehen, welches wir im nächsten Schritt deployen werden.

### Google Cloud Run Deployment

Mit dem _Cloud SDK_ stoßen wir nun ein Deployment unseres zweiten Service an:

```
gcloud beta run deploy gcloud-example-quarkus-di --image gcr.io/hier-der-vollständige-image-name --concurrency=default --allow-unauthenticated --memory=128Mi --set-env-vars=XMX=90m
```

Kurze Zeit später steht eine neuer Endpunkt zur Verfügung und ein Aufruf des Endpunkts sollte erfolgreich sein.

```
time curl https://gcloud-example-quarkus-di-zufallsid-uc.a.run.app/greeting
{"content":"HELLO WORLD!","id":0}
real	0m2.720s
```

Das Ergebnis finde ich überragend. Wir haben für die Cold Start Zeitspanne eine Reduktion von ursprünglich 16 Sekunden auf knapp unter 3 Sekunden erreicht. Interessanterweise zeigt das Log unseres Service eine Initialisierungszeit für Quarkus von 166 ms an:

```
INFO [io.quarkus] (main) Quarkus 0.11.0 started in 0.166s. Listening on: http://0.0.0.0:8080
```

Daraus schließe ich, dass das Deployment des laufenden Containers bei Google (natürlich) auch eine gewisse Zeit dauert. Völlig überrascht war ich, dass die Cold Start Time bei meinen Tests an verschiedenen Tagen nur manchmal vorzufinden war, das heißt nach einem Tag hatte ich manchmal das Glück, dass mein Container noch lief und kein Cold Start stattfand.

{{< screenshot "gcp_run_logs.png" >}}

Der aufmerksame Leser wird auch die unterschiedliche Befehlszeile erkannt habe, in der ich dem Container 128 MB RAM gebe und der Anwendung selbst bis zu 90 MB Heap Memory. Dies hat soweit bei meinen Tests funktioniert und sollte je nach Anwendung auch gezielt optimiert werden. Im Vergleich zu unserem Spring Boot Container haben wir hier aber tatsächlich nur den halben Speicher benutzt. Die Spring Boot Version startet mit 128 MB erst garnicht.

## Vergleich zu AWS Lambda

Ich habe bisher einige kleine private Projekte mittels _AWS Lambda_ umgesetzt, dazu gehören die [dynamischen Bildgrößen](https://github.com/adulescentulus/serverless-image-resizing) und das [Location Tracking](https://github.com/adulescentulus/inreach-mail-tracker) auf der [Karte](/rtw/) hier im Blog. Allen Projekten gemein war, dass ohne eine Standardimplementierung mit erzeugten Code-Templates, API-Gateway-Definitionen und Cloudformation-Templates alles ein Krampf war. Auch Kollegen, die sich mit dem Thema befasst haben, fanden den Einstieg nicht intuitiv. Dies wird dann noch durch die schwierige Testbarkeit vorsichtig formuliert "holprig", obwohl es mittlerweile mit [AWS SAM CLI](https://github.com/awslabs/aws-sam-cli) einen Lösungsansatz gibt.

Anhand meiner Beispiele war es hoffentlich nachvollziehbar, dass die Entwicklung eines einfachen Microservice nur aus sehr wenigen Schritten besteht, die sich gut in Templates verpacken lassen. Hier kann sich der Entwickler tatsächlich mit seinem Code beschäftigen und braucht keine AWS-Ausbildung.

Zu Gute halten muss man _AWS Lambda_ aber trotzdem die strenge Trennung der Schichten, d.h. das API-Gateway muss immer (mehr oder weniger) implementiert werden. Während meiner Recherchen zu diesem Artikel hat A Cloud Guru auch einen [Artikel](https://read.acloud.guru/the-good-and-the-bad-of-google-cloud-run-34455e673ef5) zu _Cloud Run_ veröffentlicht und gut herausgearbeitet, dass durch das API-Gateway die Schnittstelle zum Microservice klar definiert werden kann und der eigene Service sich nicht mit Validierung vom Input beschäftigen muss. Ebenso kann sich das API-Gateway um (auch externe) Authentifzierung kümmern.

Aus meiner persönlichen Erfahrung muss ich aber auch hier wieder den hohen Anfangsaufwand für die Implementierung in die Argumentation bringen. Meine letzten Microservices bei _AWS Lambda_ hatten eine API-Gateway-Konfiguration vom Typ `aws_proxy`, wo alle Requests einfach ohne Vorbehandlung zum Microservice weitergeleitet werden. Und habe ich schon die Probleme beim lokalen Test erwähnt ...?

Kommen wir zu einem eher rationalen Vergleich: den Kosten. _AWS_ verlangt für 1 GB Arbeitsspeicher im kleinsten Abrechnungsintervall von 100 ms 0,000001667 USD, die Kosten steigen mit dem Arbeitsspeicher linear an. Pro Million Anfragen werden noch 0,20 USD berechnet. Dazu kommt noch das API-Gateway, welches pro Million Aufrufe 3,50 USD kostet. Rechnet man alles zusammen beläuft sich das auf 0,000005167 USD pro Request. Das API-Gateway macht einen vergleichsweise hohen Anteil aus.

Bei Google bekommt man immer eine vCPU für den Container zugeteilt. Das macht pro 100 ms für die vCPU 0,00000240 USD. Dazu kommt der Arbeitsspeicher mit 0,00000025 USD pro Gigabyte in dem Zeitfenster. Pro Million Requests werden bei Google 0,40 USD fällig, ein API-Gateway braucht es nicht. Dies summiert sich auf 0,00000305 USD pro 100 ms.

Wenn man also rein die kurzlebigen Requests bis zu 100 ms Laufzeit betrachtet, ist Google aktuell 40% günstiger pro Request. Etwas wichtiges fehlt dabei noch: Im Vergleich zu _AWS Lambda_ kann _Cloud Run_ **parallele Anfragen** durch eine Instanz bearbeiten, das heißt die CPU/RAM-Preise werden nicht für jeden Request separat berechnet, sondern eine Gesamtausführungszeit vom Beginn des ersten Requests bis zum Ende des letzten Requests in Rechnung gestellt. Dies kann zu erheblichen Einsparungen führen, aber auch zu eventuellen Concurrency-Problemen (Entwicklerverantwortung), die schon A Cloud Guru im o.g. Artikel festgestellt hat.

## Fazit

Grundsätzlich kann ich ein positives Fazit ziehen. _Cloud Run_ liefert schon in dieser Beta eine wunderbar flexible Alternative zu _AWS Lambda_. Sicherlich hätte ich mich noch mit den _Cloud Functions_ beschäftigen können, aber das Angebot als Container-as-a-Service ist aus Entwicklersicht einfach zu benutzen und dazu noch kosteneffizient. Je nach Projekt und damit auch Anforderung kann das anders aussehen. 

Gleichzeitig gibt es aber noch das Problem, dass sich der Arbeitsspeicher nicht für den Container bemerkbar macht und somit manuelle Workarounds (die Umgebungsvariablen `MaxRAM` und `XMX` in den Beispielen) notwendig sind. Das wird hoffentlich in der Beta-Phase behoben.

Dies war nur eine kurze Betrachtung und ich hoffe jemand zieht daraus einen Mehrwert. Ich werde auch demnächst versuchen, die Integration in einen Kubernetes-Cluster zu testen. Dies ist ein spannender Punkt, den Google bei der Vorstellung stark hervorgehoben hat. 

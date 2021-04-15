---
aliases:
- /post/mongodb_verbindung_hinter_firewall/
type: post
categories:
- tech
comments: true
date: "2018-09-23T15:52:41+02:00"
description: Wie erreicht man ein MongoDB-Cluster, wenn die Firewall dazwischen liegt
  und man das CLI für Dumps benutzen möchte.
draft: false
tags:
- devops
- docker
title: MongoDB-Cluster Verbindung durch Firewall
---

Auf Arbeit stand ich vor dem Problem, auf einem [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)-Cluster einen Dump einspielen zu müssen. Dafür ist aber die Benutzung der Kommandozeilenwerkzeuge `mongodump` und `mongorestore` unabdingbar. Die Herausforderung war aber eine, die mich regelmäßig quält: das Sicherheitsbedürfnis des Unternehmens steht an oberster Stelle und wir müssen somit immer über den Unternehmens-Proxy oder dedizierte Jumphosts gehen, die für bestimmte Verbindungen freigeschaltet sind.

Bei der Verbindung zu einem Replica Set steht man vor der Herausforderung, dass der Client eine Verbindung zu allen Nodes machen will und bekommt dabei die Serveradressen von der Gegenseite mitgeteilt. Dies macht es nicht so einfach, die Verbindungen einzeln per SSH zu tunneln. Man muss dafür immer an den Hostnames herumfummeln (siehe dieser [Beitrag](https://blockdev.io/connecting-to-a-mongo-replica-set-via-ssh/)). Das Problem ist jetzt wieder, dass Hostnames unter Windows als Nicht-Admin wieder schwer zu ändern sind ... ein Teufelskreis.

Da ich immer wieder die Vorteile (Reproduzierbarkeit, Plattformunabhängigkeit, ...) von Docker betone, habe ich mir meine Gedanken gemacht, um ein relativ einfaches Setup mit Docker zu realisieren, so dass ich auf dem Rechner selbst auch die MongoDB-Tools in Docker nutzen kann.

Das ganze Setup habe ich unter Windows (Git Bash) und MacOS getestet und erwartet einen Rechner, den ich als SSH-Jumphost nutzen kann und der somit ausgehende Verbindungen zu Port 27017, respektive den MongoDB Atlas Hosts hat. Los geht's:

## SSH Tunnel
Auf dem lokalen Rechner wird nun eine SSH Verbindung und insgesamt 3 Tunnel zu den einzelnen Knoten des Replica Sets aufgebaut. Die Namen der einzelnen Rechner bekommt man in der Weboberfläche von MongoDB Atlas im Menüpunkt _Connect_ (Details für MongoDB 3.4 Clients). Nun machen wir in einer SSH-Verbindung insgesamt 3 Tunnel auf:

`ssh -g -L 27017:your-shard-00.gcp.mongodb.net:27017 -L27018:your-shard-01.gcp.mongodb.net:27017 -L27019:your-shard-02.gcp.mongodb.net:27017 jumphost`

Alle drei Verbindungen lauschen lokal auf drei verschiedenen Ports (27017-27019). Notwendig ist nun noch das Flag `-g`, um den Port "von außen" (dem Docker-Netzwerk) zugänglich zu machen.

## MongoDB verbinden
Für die Verbindung gibt es nun ein `docker-compose`-File, welches das MongoDB-Image (mit den CLI Tools) zur Verfügung stellt. Weiterhin werden noch 3 Container gestartet, um auf die lokalen SSH-Tunnel weiterzuleiten. Wieso 3? Weil jeder der Container auf einer Docker-IP jeweils auf Port 27017 einen Tunnel bereitstellen muss. Docker ermöglicht es uns, dem MongoDB Container diese 3 Container-IPs den Hostnames der Ziel-DB-Knoten zuzuordnen (extra/additional hosts). Dadurch denkt der Client, er verbindet sich mit den 3 Zielhosts und auch SSL macht somit keine Probleme.

{{< gist holygrolli d4a4977abf1b76d314ee74dc78a144d4 >}}

Speichert man die `docker-compose.yml` nun in einem Ordner `mdb`, dann kann man die Container alle starten:

`docker-compose up -d`

Wichtig zu wissen ist noch, dass in der _yml_-Datei der lokale Rechner (der die 3 SSH-Tunnel bereitstellt) aus den beiden Variablen zusammengebaut wird: `${HOSTNAME}.${USERDNSDOMAIN}` Unter Windows in der Git Bash sind diese gesetzt, unter MacOS und Linux muss man diese manuell setzen, so dass man seinen Rechner erreicht.

Im nächsten Schritt verbinden wir uns nun mit dem MongoDB-Container:

`docker-compose exec mongodb bash`

Nun können die Kommandozeilenwerkzeuge mit dem Connection-String benutzt werden. Daten in den und aus dem Container übertragen wir mit `docker cp ...`.

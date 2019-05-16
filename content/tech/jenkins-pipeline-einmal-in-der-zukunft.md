---
categories:
- tech
comments: true
date: "2019-05-16T23:32:05+10:00"
description: Wie kann ich eine Jenkins-Pipeline genau einmal in der Zukunft automatisch ausführen lassen?
draft: false
tags:
- blog
- devops
- hugo
- jenkins
title: Jenkins-Pipeline einmal in der Zukunft ausführen
type: post
images:
  - src: jenkins-cron.png
    width: 442
    height: 370
    title: Buildverlauf - wiederholte Ausführungen sind UNSTABLE
    orientation: l
    type: screenshot
    featured: false
---

Manchmal macht es Sinn, dass ich im Blog einige Beiträge vorab schreibe und später veröffentlichen will. Da der Blog als statische Seiten mit [Hugo](https://gohugo.io) generiert wird, muss die Erzeugung immer mit der Veröffentlichung erfolgen. Das lasse ich von einem bestehenden _Jenkins_ bauen. Um einen Blogbeitrag nun für die Zukunft einzuplanen gibt es im Jenkins eigentlich nur eine Option: zeitgesteuerte Jobs mittels Cron.

Einen Job per Cron zeitgesteuert zu starten bedeutet aber auch ein Problem: der Job wird regelmäßig zum geplanten Zeitpunkt ausgeführt, immer wieder. Eine wiederholte Ausführung ist in diesem Fall also nicht gewünscht. Wie setzt man so einen Build-Job also um?

Die Anforderung waren:

1. Ein manuell ausgeführter Build soll nur die Konfiguration durchführen und keine Aktionen ausführen
2. Der erste zeitgesteuerte Build soll die gewünschte Aktion ausführen
3. Nachfolgende zeitgesteuerte Builds sollen keine Aktionen ausführen

Nach längerer Bastelei bin ich auf eine Lösung gekommen, die eine ausgelagerte Methode benötigt, um festzustellen, ob es sich um einen zeitgesteuerten Build handelt (`isStartedByTimer()`). Diese greift auf die übergebene Build-Variable zu, um den Auslöser auszulesen.

Damit kann man nun eine Build-Stage an eine Bedingung koppeln: Ist der aktuelle Build zeitgesteuert **und** ist der vorhergehende Build kein zeitgesteuerter. Ich gehe hier davon aus, dass der vorangegangene Build man manueller Job ist, um die neue Konfiguration einzulesen. Nur dann wird mein Blog-Build ausgelöst.

Als Bonus wird nach jedem Durchlauf immer der Buildstatus gesetzt, so dass wiederholte zeitgesteuerte Ausführungen den Build als _UNSTABLE_ markieren und dies in der Historie einfacher erkennbar ist.

{{< screenshot "jenkins-cron.png" >}}

Das Ganze im vollständigen JENKINSFILE hier im Gist:

{{< gist adulescentulus 515a795821ca698ff7704cbb7c9c4be3 >}}
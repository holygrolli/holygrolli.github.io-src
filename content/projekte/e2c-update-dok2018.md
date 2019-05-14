---
categories:
- projekte
comments: true
date: "2018-10-10T19:50:45+02:00"
description: Das Programm des DOK-Festivals wurde heute veröffentlicht. Wie stellt
  man sich sein persönliches Programm zusammen?
draft: false
tags:
- e2c
title: Persönliches DOK-Festival-Programm zusammenstellen
---

Letztes Jahr hatte ich damit begonnen, ein kleines Online-Tool zu schreiben, welches mir bei Konferenzen die Planung meines Konferenzprogramms ermöglicht. Viele Konferenzen schaffen es im Jahr 2018 noch nicht, einen eigener Planer für das persönliche Konferenzprogramm auf die Beine zu stellen. Aus diesem Wunsch ist das Tool [Event2Calender](http://e2c.networkchallenge.de/) (kurz: e2c).

Mit dem Tool ist es möglich, unterstützte Programmseiten auszuwerten und daraus Konferenztermine zu extrahieren. Diese werden dem Nutzer dann einzeln angezeigt und er kann sie mit einem Klick auf den Knopf "Add to Google" seinem Google-Kalender hinzufügen. Dafür habe ich mir immer mindestens einen neuen Kalender für die Konferenz angelegt und dort alle Vorträge und Sessions gesammelt, wo ich unbedingt teilnehmen will. Für weniger interessante Termine habe ich mir einen weiteren Kalender angelegt. In der Online-Oberfläche des Google-Kalenders ist es so leicht möglich, Überschneidungen von wichtigen und unwichtigen Terminen zu sehen, Konflikte aufzulösen und das persönliche Programm zu optimieren.

Das ganze hatte ich dann für eine Reihe von Konferenzen erweitert und habe auch nicht vor dem [DOK-Festival](https://www.dok-leipzig.de/) in Leipzig halt gemacht. Der Vorteil des Google-Kalenders ist, dass man diesen auch mit Freunden teilen kann und so schnell gemeinsame Filmtermine finden kann.

Glücklicherweise hat sich 2018 nicht viel beim DOK (auf der Website) geändert, so dass nur minimale Anpassungen notwendig waren. Wenn man sich für das DOK nun sein Programm zusammenstellen will, ruft man die Seite von [Event2Calender](http://e2c.networkchallenge.de/) auf, liest die knappe Anleitung (Bookmarklet/Link in die Lesezeichenleiste ziehen), besucht das DOK-Festival-Programm und öffnet interessante Filme. Jeder Film ist auf einer separaten Seite zu finden. Klickt man nun den vorher gespeicherten Link "+AddToCalender" in seinem Browser, wird man auf die e2c-Seite weitergeleitet und bekommt (hoffentlich) alle Filmtermine angezeigt.

Für die technisch interessierte Leserschaft: das alles wird _serverless_ in der Cloud (AWS) betrieben, mittels S3, API Gateway und Lambda. Der Code und die Pipeline ist bei [GitHub](https://github.com/adulescentulus/event2calendar) zu finden.

---
aliases:
- /post/unternehmensportal-auf-huawei/
type: post
categories:
- tech
comments: true
date: "2018-12-13T19:50:11-05:00"
lastmod: "2019-08-18T08:21:45+02:00"
description: Ein Huawei-Gerät in Verbindung mit dem Microsoft Unternehmensportal ist
  eine schwierige Kombination
draft: false
tags:
- handy
- android
- huawei
title: Microsoft Unternehmens&shy;portal auf Huawei-Telefonen
---

Mein privates Telefon synchronisierte seit ein paar Tagen keine Mails mehr. Für die Synchronisation müssen alle Geräte explizit den Sicherheitsrichtlinien der Firma entsprechen. Trotz der Erfüllung dieser Anforderungen wollte partout keine Mail mehr synchronisiert werden, vielmehr informierte mich immer wieder eine automatische Mail, dass ich doch das Unternehmensportal (früher Microsoft Intune bzw. Company Portal) installieren soll ... cleverer Tipp...

Nach einer kurzen Rücksprache mit den Firmenadmins hat sich herausgestellt, dass die Geräteprofile heimlich auf _Android for Work_ umgestellt wurden, was bedeutete, dass das bisherige Profil meines Geräts einfach nicht mehr funktionieren konnte. Allerdings zeigte sich bei der Neuinstallation des Unternehmensportals, dass die App beim Deployment des _Android for Work_-Profils ständig mit einem schwarzen Bildschirm hängen blieb. Das Arbeitsprofil wurde zwar unter Konten im Telefon angezeigt, leider aber wurde das Deployment wohl wegen des Einfrierens nie beendet.

Nach gefühlt tausenden Installationsversuchen, dem Löschen des Caches und Neuinstallationen war ich schon kurz vor der Aufgabe, da auch die [Rezensionen](https://play.google.com/store/apps/details?id=com.microsoft.windowsintune.companyportal&showAllReviews=true) in Zusammenhang mit Huawei-Geräten nichts positives verlauten ließen.

Nichtsdestotrotz bin ich bei meiner Suche im Netz doch noch fündig geworden. In einem [Thread](https://microsoftintune.uservoice.com/forums/291681-ideas/suggestions/35370883-add-huawei-mate-10-pro-to-intune) über Huawei und das Unternehmensportal steckte die Lösung zum Problem, die bei mir minimal abgeändert funktionierte:

1. Work-Profil unter Konten restlos entfernen
2. Appeinstellungen von Unternehmensportal: Stoppen/Beenden erzwingen
3. App-/Speichereinstellungen von Unternehmensportal: alle Daten komplett löschen
4. Android Einstellungen / Akku / Starten: hier auf _Manuell verwalten_ stellen

Mit der letzten Einstellung wird das recht aggressive Akkumanangement für die App unterbunden und bei einem neuen Anmeldeversuch im Unternehmensportal konnte bei mir _Android for Work_ vollständig installiert werden.

Zusätzlicher Tipp: wenn die Firma noch zusätzlich ein vorkonfiguriertes Exchange-Profil für Gmail ausrollt, dann einfach lange warten. Mein vorzeitig selbst angelegtes Exchange-Konto konnte leider trotzdem nicht genutzt werden. Nach einer kompletten Neuinstallation, warten, immer wieder Einloggen ins Unternehmensportal und auch mal einem Neustart war plötzlich das Exchange-Konto gepusht und nutzbar!

**Update 18.08.2019** in [diesem Beitrag]({{< relref "unternehmensportal-auf-huawei-update-1" >}})
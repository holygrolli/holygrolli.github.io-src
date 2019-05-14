---
aliases:
- /post/garmin-spielstand-benachrichtigung/
type: post
categories:
- tech
comments: true
date: "2019-05-05T23:14:13+09:30"
description: Aktuelle Spielstände sind auf der Garmin-Uhr nicht zu erkennen. Das lässt sich ändern!
draft: false
tags:
- handy
- android
- google
- tasker
- garmin
- tutorial
title: Garmin Benach&shy;richtigungen optimieren
images:
  - src: IMG_20190414_180108.jpg
    width: 3968
    height: 2976
    title: Abgeschnittene Liste der Benachrichtungen
    orientation: l
    type: postimg
    featured: true
  - src: IMG_20190414_180114.jpg
    width: 3968
    height: 2976
    title: Auch in den Details keine Chance auf das Ergebnis
    orientation: l
    type: postimg
    featured: false
  - src: tasker_spielstand.jpg
    width: 2160
    height: 1080
    title: Konfiguration für den Profilauslöser
    orientation: l
    type: screenshot
    featured: false
  - src: IMG_20190414_180126.jpg
    width: 3968
    height: 2976
    title: Neue, vollständige Benachrichtigung in der Liste
    orientation: l
    type: postimg
    featured: false
  - src: IMG_20190414_180134.jpg
    width: 3968
    height: 2976
    title: Die Details sind nun auch vollständig
    orientation: l
    type: postimg
    featured: false
---

Ich bin nun seit Jahren ein Freund der smarten Sportuhren von Garmin. Auch wenn meine letzte Garmin-Uhr letztes Jahr pünktlich nach zwei Jahren den Geist aufgegeben hat, gibt es für mich keine Alternative.

Eine Sache störte mich aber seit einer Ewigkeit gewaltig: Ich lasse mich von der Google-App über Spielstände im Fußball benachrichtigen, nur leider schneidet Garmin die Benachrichtigungen sehr ungünstig ab, so dass man mindestens immer mit der anderen Hand die Benachrichtung antippen muss, um Details zu erfahren. In den meisten Fällen reicht das aber nicht, die wichtige Information, der Spielstand bleibt trotzdem verborgen.

{{< postimg "IMG_20190414_180108.jpg" >}}

{{< postimg "IMG_20190414_180114.jpg" >}}

Nach langer Zeit voll Frust bin ich das Problem nun angegangen. Die Lösung auf dem Android-Telefon benötigt zwei Apps. Zum einen das schweizer Taschenmesser unter den Apps, [Tasker](https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm), und zum anderen als Erweiterung aus dem gleichen Haus [AutoNotification](https://play.google.com/store/apps/details?id=com.joaomgcd.autonotification).

_AutoNotification_ wird in Tasker so konfiguriert, dass es die Benachrichtungen der Google-App abgreift. Ich habe es noch soweit eingeschränkt, dass nur Meldungen mit einem bestimmten Text, wie den Vereinsnamen und den Stichworten "Halbzeit" und "Endstand", herausgefiltert werden, damit Tasker am Ende weniger zu tun hat. Die Konfiguration erfolgt in einem neuen Profil, dessen Auslöser ein Plugin-Event (von _AutoNotification_) ist. Die Konfiguration sieht so aus:

{{< screenshot "tasker_spielstand.jpg" >}}

Danach muss noch ein Task konfiguriert werden, der auf dieses Ereignis reagiert. Der Task prüft zunächst, ob der Titel tatsächlich dem Ergebnismuster eines Spielstands entspricht. Danach werden die beiden Zahlen extrahiert (Variablen _stand1_ und _stand2_). Damit hätten wir eigentlich schon alle notwendigen Informationen. Da aber die Benachrichtigungen von Google alle paar Minuten erscheinen, würde dieses Ereignis zu einer Menge neuer Benachrichtigungen führen. Daher wird nun mit den begrenzten zur Verfügung stehenden Mitteln getrickst. Ich nehme mir einfach den ersten Team-Namen, der sich pro Spiel nicht ändert, erzeuge daraus einen md5-Hash und speichere das in der Variable _newid_. Dann lösche ich alle Buchstaben aus dem md5, um daraus eine Zahl zu machen. Ich gehe bewusst das Risiko ein, dass der md5 auch absolut keine Zahlen enthalten könnte, das ist aber sehr unwahrscheinlich. Diese Zahl wird nun abschließend in der neuen Benachrichtigung von _AutoNotification_ benutzt, um eventuell bestehende Benachrichtigungen zu aktualisieren.

{{< postimg "IMG_20190414_180126.jpg" >}}

{{< postimg "IMG_20190414_180134.jpg" >}}

Ich denke das Ergebnis kann sich sehen lassen und erfüllt nun seinen Zweck der einfachen und schnellen Information für den Nutzer. 

Der Vollständigkeithalber ist hier der Task, wie er in Tasker konfiguriert werden muss:

```
    A1: If [ %antitle ~R .*(\d+) : .*(\d+) ]
    A2: Variable Set [ Name:%stand1 To:%antitle Recurse Variables:Off Do Maths:Off Append:Off ] 
    A3: Variable Search Replace [ Variable:%stand1 Search:(.*) (\d+) : (.*) (\d+) Ignore Case:On Multi-Line:Off One Match Only:Off Store Matches In Array:%matches Replace Matches:On Replace With:$2 ] 
    A4: Variable Set [ Name:%stand2 To:%antitle Recurse Variables:Off Do Maths:Off Append:Off ] 
    A5: Variable Search Replace [ Variable:%stand2 Search:(.*) (\d+) : (.*) (\d+) Ignore Case:Off Multi-Line:Off One Match Only:Off Store Matches In Array: Replace Matches:On Replace With:$4 ] 
    A6: Variable Set [ Name:%team To:%antitle Recurse Variables:Off Do Maths:Off Append:Off ] 
    A7: Variable Search Replace [ Variable:%team Search:(.*) (\d+) : (.*) (\d+) Ignore Case:Off Multi-Line:Off One Match Only:Off Store Matches In Array: Replace Matches:On Replace With:$1 ] 
    A8: Variable Convert [ Name:%team Function:To MD5 Digest Store Result In:%newid ] 
    A9: Variable Search Replace [ Variable:%newid Search:[a-z] Ignore Case:On Multi-Line:Off One Match Only:Off Store Matches In Array: Replace Matches:On Replace With: ] 
    A10: AutoNotification [ Configuration:Title: %stand1 : %stand2
    Text: %antitle
    Status Bar Text Size: 16
    Id: %newid
    Separator: , Timeout (Seconds):20 ] 
```

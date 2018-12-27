+++
date = "2018-08-19T13:27:00+02:00"
title = "URLs einer Website testen"
tags = [
    "devops"]
categories = [
    "tech"
]
#image - "home-bg.jpg" is the default
#coverimage = "some.jpg"
description = "Resourcen einer Website auf der Console prüfen"
draft = false
comments = true
+++

Aktuell hatte ich ein Problem mit einem Webprojekt. Einige Website-Resouren wurden sporadisch, ohne erkennbares Muster, nicht geladen. Um ein eventuelles Muster (oder eben nicht) zu erkennen, musste ein paar Hilfsmittel her.

## Inventar erstellen
Zuerst musste eine Url-Liste erstellt werden, mit allen zu prüfenden Resourcen. Dafür kommt `wget` zum Einsatz. Mit folgendem Befehlt lassen sich alle Urls von einer Hauptseite ermitteln:

```
wget --spider --force-html -r -l1 https://blog.networkchallenge.de 2>output.log
```

Das Output dieses Vorgangs verarbeiten wir nun weiter (es enthält viel mehr als die gesuchten URLs), um die finale Url-Liste zu erzeugen:

```
cat output.log  | grep '^--' | awk '{ print $3 }' > urllist
```

## Prüfen mittels cURL
Bei meiner Recherche bin ich auf ein [Gist](https://gist.github.com/antonbabenko/1600911) gestoßen. Nach minimaler Ergänzung um Zeitstempel und dynamischer Url-Liste kam nun folgendes heraus (gespeichert als `curl_all.sh`):

```
#!/bin/bash
while read LINE; do
  echo -n "$(date +%H:%M:%S) "
  curl -o /dev/null --silent --progress-bar --head --write-out '%{http_code} %{time_starttransfer} %{url_effective}\n' "$LINE"
done < $1
```

## Dauertest aller URLs
Nun haben wir alles zusammen, um kontinuierlich die URLs zu prüfen und Fehler beim Laden zu erkennen. Das erstellte Skript `curl_all.sh` arbeitet die Liste nur einmal ab. Für einen Dauertest rufen wir das Skript nun in einer Schleife auf:

```
while true; do ./curl_all.sh urllist_test; done > load_test.log
```

Das `load_test.log` wird nun mit Prüfergebnissen gefüllt und wir können es gezielt (parallel und am Ende) nach HTTP-Status-Codes prüfen, die nicht mit 2 (200 - OK) beginnen:

```tail -f load_test.log | grep "^..:..:.. [^2]"```

## Gist

Alles herunterladbar als Gist:

{{< gist adulescentulus 4ee663291474cd519a4b948f21e5ab48 >}}

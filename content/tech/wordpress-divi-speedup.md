---
categories:
- allgemein
- reise
- tech
- vonoben
comments: true
date: "2019-06-16T00:31:19+10:00"
description: Erste Schritte zur Verbesserung der Ladezeiten von Wordpress mit dem Divi Theme. Meine Lösung aus der Misere.
draft: false
tags:
- blog
- hugo
- wordpress
title: Divi Theme beschleunigen
type: post
images:
  - src: divi_speedup_sizes.png
    width: 832
    height: 1128
    title: In Wordpress registrierte Bildgrößen
    orientation: l
    type: screenshot
    featured: false
  - src: divi_speedup_lazyload.png
    width: 1268
    height: 910
    title: Einstellungen für Lazy Load
    orientation: l
    type: screenshot
    featured: false
  - src: divi_speedup_scale.png
    width: 1278
    height: 528
    title: Einstellungen für Skalierung hochgeladener Bilder
    orientation: l
    type: screenshot
    featured: false
  - src: divi_speedup_rwp.png
    width: 728
    height: 898
    title: Einstellungen für zu nutzende Bildgrößen
    orientation: l
    type: screenshot
    featured: false
---

Früher (!!!) habe ich selbst mal den Blog mit _Wordpress_ betrieben und bin wegen der ständigen Updates, Sicherheitslücken und Administrationsbedarfs gezielt auf _Hugo_, einen sogenannten _Static Site Generator_ [umgestiegen]({{< relref "erster_post" >}}). Nebenbei habe ich mich vor wenigen Monaten noch auf _mobile first_ [konzentriert]({{< relref "umstellung-auf-amp" >}}). Dadurch hat sich die Geschwindigkeit nicht nur spürbar, sondern auch messbar verbessert.

Nichtsdestotrotz musste ich mich doch wieder mit _Wordpress_ beschäftigen, da Katrin als Einstieg [ihren Blog](https://alifetimeofmoments.de) auch mit _Wordpress_ betreibt. Zusätzlich benutzt sie noch das Theme [Divi](https://www.elegantthemes.com/gallery/divi/), welches einen zugegeben imposanten, visuellen Editor mitbringt. Leider wird der unerfahrene Blogger von der Firma dahinter meiner Meinung nach trotz Bezahlung sträflichst vernachlässigt, wenn es um Websitegeschwindigkeit und vor allem Bilder geht.

## Das Problem

Folgendes Problem ergibt sich für einen Anfänger: Es werden fleißig Bilder von unserer Weltreise in die Artikel geladen. Diese Bilder kommen teilweise direkt von der Kamera und sind entsprechend groß. Bei einem bildlastigen Blog kommen so ganz schnell 10 bis 20 wunderbare Bilder in voller Auflösung zusammen. Das Ergebnis: der Leser öffnet die Seite mit dem Telefon, Tablet oder Rechner und muss beim Laden sagenhafte **80 MB Daten** übertragen! Echt verrückt!

_Divi_ selbst bietet einen [Ultimative Guide](https://www.elegantthemes.com/blog/divi-resources/the-ultimate-guide-to-using-images-within-divi), der Anfänger definitiv überfordert und nicht nur meiner Meinung nach elementare _Wordpress_-Funktionen ignoriert. _Wordpress_ selbst erzeugt selbst sogenannte _responsive image sizes_, das heißt beim Upload eines Bildes werden automatisch vier andere Bildgrößen zusätzlich zum Original gespeichert: thumbnail, medium, medium_large und large. _Divi_ selbst registriert sieben (7!) weitere Bildgrößen, die alle zusätzlich generiert und gespeichert werden. Der Witz an der Sache ist: an keiner Stelle beim Bearbeiten eines Beitrags wird irgendeine diese Größen benutzt (zumindest konnte ich nichts finden). Eine Information von Seiten des Herstellers habe ich nicht finden können, nur den Unmut anderer Nutzer, dass _Divi_ im Jahr 2019 noch immer keine _responsive images_ unterstützt.

{{< screenshot "divi_speedup_sizes.png" >}}

Die Lösung von _Divi_ sieht so aus, dass der Author jedes Bild in der für den Einsatzzweck passenden Auflösung hochladen muss und dies bei mehrfachem Einsatz auch mehrfach in unterschiedlichen Auflösungen wiederholen muss. Was für ein Durcheinander das in der Mediathek gibt!

## Die Lösung

Nach einigem Experimentieren habe ich eine performante und auch praktible Lösung gefunden, die es dem Author auch noch erlaubt, weiterhin die großen Bilder hochzuladen und somit nichts an seinem Workflow zu ändern. Es wird immer wieder geraten, die Bilder vor der Benutzung zu Hause am Rechner für den Webeinsatz vorzubereiten. Davon halte ich aber nichts, schließlich benutzen wir ja _Wordpress_ und das soll ja auch was zu tun haben, wenn es schon, wie eingangs erwähnt, so einiges an Pflege braucht.

### Plugin: EWWW Image Optimizer

Das erste Plugin ist eine Art eierlegende Wollmichsau und kann Bilder optimieren, ohne sie, wie manch andere Plugins, an einen Drittdienst weiterzureichen. Nach der Installation von [EWWW Image Optimizer](https://de.wordpress.org/plugins/ewww-image-optimizer/) geht es an die Konfiguration. Die sieht eigentlich ganz einfach aus. Man wechselt auf den Reiter "ExactDN" und deaktiviert alle Optionen bis auf "Lazy Load" und speichert das dann. 

{{< screenshot "divi_speedup_lazyload.png" >}}

Weiter auf dem Reiter "Skalieren". Hier wählen wir auch alles ab, bis auf "Skaliere bestehende Bilder" und tragen bei "Ändere Größe von Bildern" eine Breite von "2880" und Höhe von "0" ein. Dies entspricht der größten von _Divi_ Bildbreite.

{{< screenshot "divi_speedup_scale.png" >}}

Zum Schluss wechselt man in der Seitenleiste in Medien / Massenoptimierung und wendet die Optimierung auf alle bestehenden Bilder an.

Das Plugin haben wir nun so konfiguriert, dass nun bei jedem Bildupload das Bild auf eine Größe von maximal 2880 in der Breite skaliert wird. Nebenbei wird durch eine effiziente Komprimierung noch einiges an Datenmenge eingespart, die Bilder werden somit vollautomatisch für das Web optimiert.

Als Bonus inkludiert das Plugin beim Anzeigen einer Seite ein bekanntes Skript, was meiner Meinung nach ein De-Facto-Standard im Web ist: [lazysizes](https://github.com/aFarkas/lazysizes/). Dieses Skript sorgt dafür, dass dem Browser mehrere Bildgrößen zum Download angeboten werden. Der Browser kann nun je nach Bildschirmgröße (Mobil, Tablet, Rechner, Hochkant, Quer) entscheiden, welches Bild gerade optimal passt und somit lädt er meist ein wesentlich kleineres Bild, als das volle Originalbild. Zusätzlich lädt das Skript Bilder nur, wenn der Nutzer auch wirklich dies in den Sichtbereich scrollt bzw. kurz vorher.

### Plugin: Responsify Wordpress

Leider reicht das erste Plugin noch nicht aus, da _Divi_ irgendeinen eigenen Zauber benutzt, um Bilder in eine Seite zu bringen. Das "Lazy Load" funktioniert nur bei normalen Seiten aus dem _Wordpress_-Editor, nicht beim _Divi-Builder_. Das Plugin [Responsify Wordpress](https://de.wordpress.org/plugins/responsify-wp/) sorgt nun dafür, alle solchen Bilder zu erkennen und diese so aufzubereiten, dass die Geheimwaffe "Lazy Load" auch zünden kann.

Nach der Installation des Plugins wechselt man in die zugehörigen Einstellungen und scrollt bis zu "Bildgröße". Hier wählt man nun nur die Bildgrößen aus, die dem Browser zur Wahl gestellt werden sollen. Meine Empfehlung dazu lautet: thumbnail, medium, medium_large und et-pb-portfolio-image-single. Damit haben wir vier Größen bis einschließlich 1080 in der Breite. Zusätzlich inkludiert das Plugin immer noch die volle Auflösung (haben wir oben auf maximal 3000 skaliert), um gegebenenfalls auch Retina-Displays mit abzudecken. Speichern nicht vergessen!

{{< screenshot "divi_speedup_rwp.png" >}}

Leider geht's jetzt ans Eingemachte! Damit "Lazy Load" funktioniert müssen an den Bildern bestimmte HTML-Attribute gesetzt werden. Dafür gehen wir nun in Plugins / Plugin Editor und wählen dort "Responsify WP" und dann rechts im Dateibaum auf "includes / img.php". Die vollständige Datei kann bei der Plugin-Version 1.9.11 ersetzt werden:

{{< gist holygrolli ba1ca4e315a6e66ff5af23758a2f94bc >}}

Nach dem Speichern sind wir grundsätzlich fertig mit unseren Änderungen. Mit der Anpassung an dem Plugin haben wir allerdings eine kleine Hürde für zukünftige Updates vom Plugin _Responsify WP_ geschaffen. Sollte das Plugin aktualisiert werden, braucht es eine erneute Anpassung. Da das Plugin aber schon seit über einem Jahr nicht mehr aktualisiert wurde, hoffe ich einfach, dass das nicht so häufig vorkommt.

### Browser Cache Einstellungen

Damit Bilder vom Browser nicht bei jedem Besuch wieder heruntergeladen werden ist es noch sehr empfehlenswert, das Caching von statischen Resourcen (Bilder, CSS usw.) zu konfigurieren. Das geht in den meisten Fällen über eine Anpassung der Datei `.htaccess` im Hauptverzeichnis der _Wordpress_-Installation. Am Ende fügen wir folgendes ein:

```
# One month for most static assets
<filesMatch ".(css|jpg|jpeg|png|gif|js|ico|ttf)$">
Header set Cache-Control "max-age=2678400, public"
</filesMatch>
```

### Umstellung von PHP5 auf PHP7

Wenn der Hoster es erlaubt, dann sollte die PHP-Version auf die neueste Version 7.x umgestellt werden. Die Geschwindigkeit mit PHP7 ist laut [Messungen](https://www.cloudways.com/blog/wordpress-performance-on-php-versions/) einfach besser.

## Fazit

Die hier beschriebenen Schritte sind nur eine Möglichkeit das Nutzererlebnis und nachweislich das Google-Ranking zu verbessern. Grundsätzlich hätte ich mir gewünscht, dass _Divi_ selbst hier mehr Möglichkeiten bietet. Die letzten beiden Schritte meiner Lösung sind aber unabhängig von _Divi_ und sollten überall durchgeführt werden. Freunde werden _Divi_ und ich aber wohl trotzdem nicht.
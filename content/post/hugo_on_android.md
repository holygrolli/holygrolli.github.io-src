+++
date = "2017-12-29T13:18:51+05:30"
categories = ["tech"]
tags = ["hugo"]
title = "Hugo auf einem Android Tablet"
comments = true
description = "Challenge: den Blog auf Reisen aktualisieren - nur mit einem Android-Device"
image = "/img/home-bg.jpg"

+++

Gerade beginnt Woche 3 in Sri Lanka und während wir auf unseren Fahrer warten habe ich 2 Stunden Zeit zum Basteln. 
Durch Zufall bin ich gestern auf die Android-App _termux_ gestoßen. Damit bekommt man eine minimale Linuxinstallation auf sein Gerät 
und kann Pakete mittels _apt_ nachinstallieren.

Zuerst installiert man mit `apt install wget` das vollständige wget-Paket (default ist nur eine abgespeckte Busybox-Version), dann lädt
man sich das Linux ARM Paket von [Hugo][hugo].

Nach dem Entpacken steht einem nun die Hugo Binary zur Verfügung und kann genauso wie auf jeder anderen Plattform genutzt werden. 
Überraschend ist auch die funktionierende Möglichkeit, die Live-Ansicht mit `hugo server` im Browser unter `http://localhost:1313` aufrufen zu können.

Das ganze ermöglicht dann doch eine recht mobile Variante des Bloggens, wie dieses Bild beweist:
<img src="/img/IMG_20171229_130724_HDR.jpg" class="img-responsive" >

[hugo]: https://github.com/gohugoio/hugo/releases

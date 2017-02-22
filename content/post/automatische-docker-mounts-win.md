+++
date = "2017-02-22T09:22:51+01:00"
categories = ["tech"]
tags = ["docker","devops","virtualbox"]
title = "Automatische Docker-Mounts in Windows"
comments = true
description = "Docker mit VirtualBox unter Windows macht es einem nicht sehr leicht, andere Verzeichnisse als das Benutzer-Verzeichnis als Volume bereitzustellen."
image = "/img/home-bg.jpg"

+++

Standardmäßig wird bei der Installation der _Docker Toolbox_ die freie Virtualisierungssoftware _VirtualBox_ installiert. Um nun im Docker-Container auf Dateien des Windows-Hosts zuzugreifen, wird standardmäßig der Pfad `/c/Users` im Gastsystem gemountet. Dies ist aber nicht optimal, da man als Windows-Nutzer oft mit Leerzeichen in Pfaden geplagt ist und auch sonst eher z.B. mit einem anderen Arbeitsverzeichnis z.B. `c:\dev` arbeitet.

Damit dies nun bei jedem Start der Docker-Machine verfügbar ist, müssen ein paar manuelle Handgriffe getätigt werden. Da ich unter Windows primär mit der _GitBash_ arbeite, hier nun die einzelnen Schritte. (Vorraussetzung die Maschine _default_ ist gestoppt)

1. Prüfung der aktuellen SharedFolder-Einstellungen
```
VBoxManage showvminfo default
```
Dies sollte folgende Standardausgabe weit am Ende liefern:
```
Shared folders:
Name: 'c/Users', Host path: '\\?\c:\Users' (machine mapping), writable
```

1. Hinzufügen eines neuen SharedFolder
```
VBoxManage sharedfolder add default --name /c/dev --hostpath "C:\\dev" --automount
```

1. Starten der Docker-Machine mit `docker-machine start default`

1. Per ssh mit der Docker-Machine verbinden `docker-machine ssh default`

1. eine neue Datei für den "Autostart" erzeugen und editieren
```
sudo vi /mnt/sda1/var/lib/boot2docker/bootlocal.sh
```

1. Der folgende Dateiinhalt erzeugt den Mount-Pfad und hängt das SharedFolder ein
```
mkdir -p /c/dev
mount -t vboxsf -o defaults,uid=`id -u docker`,gid=`id -g docker` c/dev /c/dev
```

1. Nach dem Verlassen der VM zurück in der GitBash verhilft ein schnelles `docker-machine restart default` zum Neustart der VM.

1. Verbindet man sich nun erneut mit der VM mittels `docker-machine ssh default` sollte ein `ls /c/dev` den Inhalt des Host-Verzeichnisses anzeigen.

### Zusatzinfo

Da ich nicht nur mit der GitBash sondern auch mit [Babun][babun] arbeite ist es auch noch interessant, wenn man die Cygwin-typischen Pfade mountet. Das bedeutet man bindet das Verzeichnis `c:\dev` zusätzlich als `/cygdrive/c/dev` ein und man kann dann ebenso aus der Cygwin-Shell heraus Pfade einbinden.

[babun]: https://babun.github.io
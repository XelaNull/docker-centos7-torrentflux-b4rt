# Dockerfile for CentOS 7.6 + Apache 2.4 + PHP 7.2 + Torrentflux-b4rt 1.0_beta2

Torrentflux-b4rt appears to be a dead project, with the original website no longer online. After scouring the Internet for all forks of torrentflux, I've concluded that torrentflux-b4rt is still the best option with the most features. The newest code of torrentflux-b4rt that I could find was years old and had parse errors in multiple PHP files. Lastly, I found that the version of transmission-cli available in YUM is no longer compatible with Torrentflux-b4rt. I did find it is possible to patch and compile a somewhat recent version of transmission, so that it is compatible with Torrentflux-b4rt once again. Fortunately, everything needed to fix these issues was available on github.com: torrentflux-b4rt source code, transmission source code, and the transmission patch. I forked each of these to ensure their survival as it relates to this project.

**As best as I know, this project represents the newest working version of Torrentflux-b4rt, as a Dockerfile as of January 2019.**

If you just want standalone Torrentflux-b4rt package, please see: <https://github.com/XelaNull/torrentflux-b4rt-php7>

This Dockerfile provides a single container image that provides an entire instance of Torrentflux-b4rt, already pre-configured with what I think are optimal settings for use on a seedbox. There is only a single pre-requisite for using this: **docker**

The goal of this project is to provide a single Dockerfile that will create a Docker container that is comprised of:

- CentOS 7
- Supervisor
- Syslog-NG
- Cron
- Apache 2.4 HTTP
- PHP 7.2
- MariaDB 5.5
- Torrentflux-b4rt 1.0_beta2

**Packages Installed**

- transmission 2.73
- rSync
- wget
- unzip
- bzip2
- rar/unrar
- uudeview
- cksfv

**To Build:**

```
docker build -t centos7/b4rt .
```

**To Run:**

```
docker run -d --name=CENTOS7-b4rt -p 8080:80 centos7/b4rt
```

**To Access:**

```
http://YOURIP:8080
```

The first username and password you provide is created as your administrative account.

**To Enter:**

```
docker exec -it CENTOS7-b4rt bash
```

--------------------------------------------------------------------------------

Torrentflux-b4rt: (Parse Errors Fixed; Working Copy) <https://github.com/XelaNull/torrentflux-b4rt-php7>

Transmission 2.73 Patch: <https://github.com/XelaNull/torrentflux/tree/master/clients/transmission/transmission-2.73>

Transmission 2.73: <https://github.com/XelaNull/transmission-releases/blob/master/transmission-2.73.tar.bz2>

--------------------------------------------------------------------------------

Build Notes:

yum install docker git -y && systemctl enable docker && systemctl start docker

export rev=`docker ps | grep Up | awk '{print $11}' | cut -d- -f3`; docker stop CENTOS-b4rt-$rev; export rev=$((rev+1)) && export CENTOS=7 && time docker build -t centos-$CENTOS/b4rt:$rev .

docker run -d --name=CENTOS-b4rt-$rev -p 8080:80 centos-$CENTOS/b4rt:$rev; docker exec -it CENTOS-b4rt-$rev bash

<https://rudd-o.com/linux-and-free-software/how-to-automate-torrent-downloads-using-torrentflux-b4rt-cron-and-rsync>

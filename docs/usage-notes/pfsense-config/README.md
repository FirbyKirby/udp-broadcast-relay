# pfSense 2.4 usage Notes

The particular issue that was being solved here was to allow [Syncthing][] to
be discoverable between two network segments, a LAN and a WiFi network.
Whilst pfSense provides the Avahi plugin, this doesn't help with [Syncthing][].

However, the *udp-broadcast-relay-redux* tool allows arbitrary relaying of UDP
packets between interfaces, and this helps to solve the problem.

You'll need to be fairly comfortable with the command line to be able to do the
following.  In particularly, if the word `ssh` means nothing to you then you'll
need to do some reading about how to access the command line on pfSense and
FreeBSD.

## Syncthing discovery

[Syncthing][] discovery uses UDP port `21027` to announce a Syncthing instance
to the world around it.  In order to make it work between subnets, the
broadcast packet must be relayed.

## Configuring *udp-broadcast-relay-redux* for pfSense 2.4

**Note. This is written from the perspective of a Linux user.  If you're
already a BSD user then you'll already know much of this.  Skip to the
"Configuring the router section".**

Although make is installed on [pfSense][], very sensibly, gcc is not.  And you
shouldn't even think of installing gcc on your router!  So a build machine is
needed to actually build a compatible binary for the pfSense router.  pfSense
2.4.2-p1 is based on
[FreeBSD 11.1-RELEASE-p6](https://www.freebsd.org/releases/11.1R/).
So the first thing to do is to create a FreeBSD build machine and build the
*udp-broadcast-relay-redux* tool.

### Build the udp-broadcast-relay-redux tool

* Grab a [copy](https://download.freebsd.org/ftp/releases/amd64/amd64/ISO-IMAGES/11.1/FreeBSD-11.1-RELEASE-amd64-disc1.iso) of the FreeBSD disk.
* Choose your favourite virtual machine manager, and install FreeBSD.
* Log in to your build machine.
* Install required files to actually do the build:

```shell
$ pkg search tmux  # useful to get pkg installed!
$ pkg install tmux
$ # and because tmux lets you have multiple windows
$ tmux
$ pkg install gcc
$ pkg install git
$ git clone https://github.com/udp-redux/udp-broadcast-relay-redux.git
$ # or the version that you are going to use.
```

* Build the tool:

```shell
$ make
```

And that's it for the build.  Now copy the `udp-broadcast-relay-redux` file
from the builder to your router at `/usr/local/bin/udp-broadcast-relay-redux`.

### Configuring the router

So now we want the tool on the router to autostart with the correct command
when the router is rebooted.

This is done with the init and configuration scripts in this directory.

1. The init script: [/usr/local/etc/rc.d/udp-broadcast-relay.sh](udp-broadcast-relay.sh)
2. The configuration file: [/usr/local/etc/udp-broadcast-relay-redux.conf](udp-broadcast-relay-redux.conf)
3. And a modification to `/etc/rc.conf.local`.

So place the `udp-broadcast-relay.sh` script into `/etc/local/etc/rc.d/`.

Modify the configuration file:

```shell
udp_vars="--id 1 --port <port-to-reflect> --dev igb1 [--dev igb2 --dev igb2.5 ...]"
```

e.g. for Syncthing, this can be used:

```shell
# reflect syncthing discovery between to subnets
udp_vars="--id 1 --port 21027 --dev igb1 --dev igb2"
```

Make a change to `/etc/rc.conf.local` to add:

```shell
# udp_broadcast_relay_enable=YES
```

(without this, or set to `NO`, the `udp-broadcast-relay-redux` instance won't be started.)

And then start the service using:

```shell
# service udp-broadcast-relay.sh start
```

To stop the service, use:

```shell
# service udp-broadcast-relay.sh stop
```

And to disable the service completely, either delete the
`udp-broadcast-relay.sh` file, or with the `YES` to a `NO` in the
`/etc/rc.conf.local` file.

## Multiple instances

It's possible to also configure multiple instances of
`udp-broadcast-relay-redux` by duplicating the files of the single
instance above to create a new instance.  e.g. to create a second
instance:

```shell
# cd /usr/local/etc/rc.d
# cp udp-broadcast-relay.sh udp-broadcast-relay2.sh
```

Then rename your second instance variables:

```shell
# nano udp-broadcast-relay.sh
# name="udp-broadcast-relay2"
# rcvar="udp_broadcast_relay2_enable"
...
conf_file="/usr/local/etc/udp-broadcast-relay-redux2.conf"
```

Next do the same with the config file:

```shell
# cd /usr/local/etc/
# cp udp-broadcast-relay-redux.conf udp-broadcast-relay-redux2.conf
# nano udp-broadcast-relay-redux2.conf
```

And change to: `--id 2` and whatever other ports and settings you need in
your new instance.

Finally add the service:

```shell
# nano /etc/rc.conf.local
```

And add a new line:

`udp_broadcast_relay2_enable=YES`

Rinse and repeat as needed.


[Syncthing]: https://syncthing.net/
[pfSense]: https://www.pfsense.org/

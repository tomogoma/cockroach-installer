# Cockroach DB Installer #

An auto-installer of cockroach DB Beta as a service in linux systems


## Install ##

Currently only systemd is supported

First download the cockroachdb tarball from https://binaries.cockroachdb.com or search for it in the website: https://www.cockroachlabs.com

```
$ git clone https://github.com/tomogoma/cockroach-installer
$ cd roach-installer
$ ./systemdInstaller.sh /path/to/downloaded/cockroach-tarbal.tz
```


## Install outcome ##


Start

`$ systemctl start cockroach.service`

Stop

`$ systemctl stop cockroach.service`

Check status

`$ systemctl status cockroach.service`


Install Directories

The cockroach db binary is installed into
`/usr/local/cockroachdb`

The db certs are located at
`/usr/local/cockroachdb/certs`

The data dir is located at
`/var/data/cockroachdb`

A systemd service unit file is created at
`/etc/systemd/system/cockroach.service`

## Uninstall ##

`$ cd /path/to/roach-installer`

`$ ./systemdUninstaller.sh`


## Configure a dependent systemd service ##

If your service depends on cockroach db, in the service’s unit file add the following lines:


```
[Unit]

...

After=cockroach.service

Requires=cockroach.service

...
```


## Get your app’s postgresql driver url ##

1. Start the cockroachdb service as described in Install Outcome
1. Check the status of the service as described in Install Outcome
1. Copy the url you see under the sql flag: e.g:

    `sql:       postgresql://root@ROACHs-MBP:26257?sslcert=%2FUsers%2F…`

    Will yield the url:

    `postgresql://root@ROACHs-MBP:26257?sslcert=%2FUsers%2F…`

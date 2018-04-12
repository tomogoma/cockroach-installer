# Cockroach DB Installer #

An auto-installer of cockroach DB Beta as a service in linux systems


## Install ##

Currently only systemd is supported.

***Note***

If upgrading from `v < 2.0` make sure you
[log in to the SQL](https://www.cockroachlabs.com/docs/stable/secure-a-cluster.html#step-4-test-the-cluster)
console

```bash
cockroach sql --certs-dir=/etc/cockroachdb/certs
```

...and run the below command as documented
[here](https://www.cockroachlabs.com/docs/v1.1/upgrade-cockroach-version.html#finalize-the-upgrade):

```sql
SET CLUSTER SETTING version = '1.1';
```

***Install***

First download the cockroachdb tarball from https://binaries.cockroachdb.com or search for it
in the website: https://www.cockroachlabs.com

Then run the following commands.

```bash
git clone https://github.com/tomogoma/cockroach-installer
cd cockroach-installer
./systemdInstaller.sh /path/to/downloaded/cockroach-tarbal.tz [username]
```

`username` is optional.
Providing it allows `@username` to quickly access the SQL console using the `cconnect`
utility command:

```bash
cconnect
```

which is equivalent to:
```bash
cockroach sql --certs-dir=/etc/cockroachdb/certs
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

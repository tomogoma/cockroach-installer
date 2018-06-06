# Cockroach DB Installer #

An auto-installer of cockroachDB binary and nodes as SystemD
services in linux systems.


## Install ##

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

### Get the installer

First download the cockroachdb tarball from https://www.cockroachlabs.com

Then run the following commands.

```bash
git clone https://github.com/tomogoma/cockroach-installer
cd cockroach-installer
```

Options can be found by running:

```bash
./systemdInstaller --help
```

### Set Up A Cluster

There are two approaches for setting up a cluster:

1. [Set up all nodes in one host](#set-up-all-nodes-in-one-host)
1. [Set up each node in its own host (Recommended approach)](#set-up-each-node-in-own-host)

#### Set up all nodes in one host

Assume your username in the linux server is `bart`
and the binary has been saved at `~/Downloads/cockroach.linux-amd64.tgz`
(change these values appropriately)

1. Install cockroachDB and the unit file for the root node:
    
    ```bash
    sudo ./systemdInstaller.sh -u bart ~/Downloads/cockroach-v2.0.2.linux-amd64.tgz
    sudo systemctl start cockroach.root.service
    ```
    
    You now have a fully functional CockroachDB listening at `localhost:26257`
    
1. Install a unit file for the second node:
    
    ```bash
    sudo ./systemdInstaller.sh --name node2 --store /var/data/cockroach/node2 --port 26258 --http-port 7006 --join localhost:26257
    ```
    
    1. We specify the `name` of the node so that
    the unit file has a separate namespace from
    `root`.
    1. We instruct `cockroach` to listen on a
    different `port`, `http-port` and to use
    a different `store` dir since two nodes are
    sharing a server (we would use defaults if
    we were on different servers).
    1. We use the `join` config to make cockroach
    join the `root` node's cluster.
    
    Start the second node:
    
    ```bash
    sudo systemctl start cockroach.node2.service
    ```
    
    notice `node2` in `cockroach.node2.service` similar to what
    we passed under `--name` config before.
    
1. Repeat the step above for subsequent nodes using different
values for `name`, `store`, `port` and `http-port`.
        
#### Set up each node in own host

Assume the root node is to be hosted at `my.server.url`,
your username in the linux server is `bart`
and the CockroachDB binary is saved at `~/Downloads/cockroach.linux-amd64.tgz`
(change these values appropriately):

1. Install the root node at `my.server.url`
    
    1. Log in to `my.server.url`
    
    1. Install cockroach db and create a SystemD service for the
    root node using this command:
    
        ```bash
        sudo ./systemdInstaller.sh --user bart --host my.server.url ~/Downloads/cockroach.linux-amd64.tgz
        ```
    
    1. Run the following command to start the node:
        
        ```bash
        sudo systemctl start cockroach.root.service
        ```
    
    You now have a fully functional CockroachDB listening at `my.server.url:26257`
    
1. Join other nodes to the cluster
    
    1. Log in to the second server
     
    1. Copy the certificates dir in my.server.url into server2
    (This step is still manual unfortunately)
        
        ```bash
        sudo su
        mkdir -p /etc/cockroachdb
        cd /etc/cockroachdb
        sftp bart@my.server.url
        get -R /etc/cockroachdb/certs
        exit # from sftp
        exit # from sudo
        ```
    
    1. Install CockroachDB and a Systemd service for the node
    by running this:
    
        ```bash
        sudo ./systemdInstaller.sh --name node2 --join my.server.url:26257 ~/Downloads/cockroach.linux-amd64.tgz
        ```
        
        Note the following:
        
        `--name node2` - this forms the unit name `cockroach.node2.service`
        
        `--join my.server.url:26257` - letting cockroach know which cluster to
         join. All other `cockroach start` configurations can
         be appended in a similar manner.
    
    1. Start the node by running this:
    
        ```bash
        sudo systemctl start cockroach.node2.service
        ```
    
1. Repeat the step above for every subsequent node.

## Uninstalling

The script below stops all nodes in the current server,
uninstalls all cockroach SystemD unit files
and uninstalls the cockroach binary.

`store` directories and `certs` directories are left untouched.
These have to be deleted manually.

```bash
sudo ./systemdUninstall
```
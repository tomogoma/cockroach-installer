#!/usr/bin/env bash

#
# 1. Define defaults
#

UNIT_NAME=""
UNIT_FILE_PATH=""
CMD_QUIT=""
CMD_START=""
USER=""
NAME="root"
HELP=false
INSTALLER_DIR=""

START_CMD_CERTS_DIR="/etc/cockroachdb/certs"
START_CMD_STORE="/var/data/cockroachdb/"
START_CMD_HOST="localhost"
START_CMD_PORT="26257"
START_CMD_HTTP_HOST="localhost"
START_CMD_HTTP_PORT="7005"
START_CMD_LOG_TO_STD_ERR="ERROR"
START_CMD_INSECURE="false"
START_CMD_ARGS=""

INSTALL_DIR="/usr/local/bin"
BIN_PATH="$INSTALL_DIR/cockroach"
SYSTEMD_DIR="/etc/systemd/system"

function usage {
	printf "CockroachDB Installer
    Usage: $1 [options] [/path/to/cockroachdb.tgz]

    download cockroachdb tgz file from https://www.cockroachlabs.com

[/path/to/cockroachdb.tgz]
Provide this to install or upgrade cockroachdb in the system.
This can be left blank if cockroach is already installed using
the installer or manually at $BIN_PATH.

[options]
Valid options are any valid start commands to be passed to CockroachDB
and the following commands for the unit file:

-u|--user   The unix username to be given usage rights to 'cconnect'.
-n|--name   The name to give to the unit file
            (without the .service extension), default is $NAME.

Valid start commands for CockroachDB can be found here:
https://www.cockroachlabs.com/docs/stable/start-a-node.html#flags-changed-in-v2-0.

Among the valid start commands, the script will behave as follows:

--certs-dir     Defaults to $START_CMD_CERTS_DIR,
                certificates will be generated if the directory provided by
                --certs-dir is empty or none-existent
-s|--store      Defaults to $START_CMD_STORE
-p|--host       Defaults to $START_CMD_HOST
-p|--port       Defaults to $START_CMD_PORT
--http-host     Defaults to $START_CMD_HTTP_HOST
--http-port     Defaults to $START_CMD_HTTP_PORT
--logtostderr   Defaults to $START_CMD_LOG_TO_STD_ERR
--insecure      Defaults to $START_CMD_INSECURE

"
}

# extractRoach tarball
# extracts the CockroachDB tarball providing the extracted
# dir's path as INSTALLER_DIR.
function extractRoach {
    local tarball="$1"
	tar -xzf "$tarball" || exit 1
	local filename="$(basename "$tarball")"
	INSTALLER_DIR="${filename%.*}"
}

# installRoach installerDir installLoc storageLoc
# moves the cockroach binary in installerDir into
# installLocation (/path/to/binary_file), creating
# the storageLoc dir in the process.
function installRoach {
    local installerDir="$1"
    local installLoc="$2"
    local storageLoc="$3"
    local installDir="$(dirname "$installLoc")"
	mkdir -p "$installDir" || exit 1
	mkdir -p "$storageLoc" || exit 1
	mv -f "$installerDir/cockroach" "$installLoc" || exit 1
}

# installCerts cockroachBinary certsDir
# uses cockroachBinary to install certificates
# at certsDir provided certsDir is empty or non-existent.
# It prints an error and returns immediately if certDir is not empty.
function installCerts {
    local cockroachBinary="$1"
    local certsDir="$2"
    local privateCertsDir="$certsDir/private"
    if [ -e "$certsDir" ]; then
        if [ ! -d "$certsDir" ] || [ ! -z "$(ls -A /path/to/dir)" ]; then
           printf "skip creating certs, certs dir ($certsDir) exists and is not empty.\n"
           return
        fi
    fi
    mkdir -p "$certsDir" || exit 1
    mkdir -p "$privateCertsDir" || exit 1
	"$cockroachBinary" cert create-ca --certs-dir="$certsDir" --ca-key="$privateCertsDir/ca.key" || exit 1
	"$cockroachBinary" cert create-client root --certs-dir="$certsDir" --ca-key="$privateCertsDir/ca.key" || exit 1
	"$cockroachBinary" cert create-node localhost $(hostname) --certs-dir="$certsDir" --ca-key="$privateCertsDir/ca.key" || exit 1
}

# createCConnect certsDir [user]
# creates cconnect script for easier access to the CockroachDB sql console.
# Providing user allows them access to the util without need for sudo.
function installCConnect {
    local certsDir="$1"
    local user="$2"
    touch "/usr/local/bin/cconnect"
    echo "cockroach sql --certs-dir=$certsDir" > "/usr/local/bin/cconnect"
    chmod +x "/usr/local/bin/cconnect"
    # allow user to run cconnect without need for sudo.
    if [ ! -z "$user" ]; then
        chown -R "$user":"$user" "$certsDir"
    fi
}

# installService systemdDir unitName execStart execStop
# creates, installs and enables a Systemd unit file based on
# a cockroach db node template.
# execStart and execStop must be full fledged unix commands.
function installService {
    local systemdDir="$1"
    local unitName="$2"
    local execStart="$3"
    local execStop="$4"
    local unitFilePath="$systemdDir/$unitName"

	mkdir -p "$systemdDir" || exit 1

    printf "[Unit]
Description=CockroachDB node [$unitName] auto starter

[Install]
WantedBy=multi-user.target

[Service]
ExecStart=$execStart
ExecStop=$execStop
SyslogIdentifier=$unitName
Restart=always
LimitNOFILE=35000" > "$unitFilePath"

	systemctl enable "$unitName" || exit 1
}

#
#
# Begin script execution.
#
#

#
# 2.a. Parse parameters replacing defaults on conflict
#

POSITIONAL=()

while [[ $# -gt 0 ]]
do
    key="$1"

    case "$key" in
        -u|--user)
        USER="$2"
        shift # past argument
        shift # past value
        ;;
        -n|--name)
        NAME="$2"
        shift # past argument
        shift # past value
        ;;
        --certs-dir)
        START_CMD_CERTS_DIR="$2"
        shift # past argument
        shift # past value
        ;;
        -s|--store)
        START_CMD_STORE="$2"
        shift # past argument
        shift # past value
        ;;
        -p|--port)
        START_CMD_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --http-port)
        START_CMD_HTTP_PORT="$2"
        shift # past argument
        shift # past value
        ;;
        --logtostderr)
        START_CMD_LOG_TO_STD_ERR="$2"
        shift # past argument
        shift # past value
        ;;
        --insecure)
        START_CMD_INSECURE="$2"
        shift # past argument
        shift # past value
        ;;
        --host)
        START_CMD_HOST="$2"
        shift # past argument
        shift # past value
        ;;
        --http-host)
        START_CMD_HTTP_HOST="$2"
        shift # past argument
        shift # past value
        ;;
        --advertise-host)
        START_CMD_ARGS="$START_CMD_ARGS --advertise-host=$2"
        shift # past argument
        shift # past value
        ;;
        --attrs)
        START_CMD_ARGS="$START_CMD_ARGS --attrs=$2"
        shift # past argument
        shift # past value
        ;;
        --background)
        START_CMD_ARGS="$START_CMD_ARGS --background=$2"
        shift # past argument
        shift # past value
        ;;
        --cache)
        START_CMD_ARGS="$START_CMD_ARGS --cache=$2"
        shift # past argument
        shift # past value
        ;;
        --external-io-dir)
        START_CMD_ARGS="$START_CMD_ARGS --external-io-dir=$2"
        shift # past argument
        shift # past value
        ;;
        -j|--join)
        START_CMD_ARGS="$START_CMD_ARGS --join=$2"
        shift # past argument
        shift # past value
        ;;
        --listening-url-file)
        START_CMD_ARGS="$START_CMD_ARGS --listening-url-file=$2"
        shift # past argument
        shift # past value
        ;;
        --locality)
        START_CMD_ARGS="$START_CMD_ARGS --locality=$2"
        shift # past argument
        shift # past value
        ;;
        --max-disk-temp-storage)
        START_CMD_ARGS="$START_CMD_ARGS --max-disk-temp-storage=$2"
        shift # past argument
        shift # past value
        ;;
        --max-offset)
        START_CMD_ARGS="$START_CMD_ARGS --max-offset=$2"
        shift # past argument
        shift # past value
        ;;
        --max-sql-memory)
        START_CMD_ARGS="$START_CMD_ARGS --max-sql-memory=$2"
        shift # past argument
        shift # past value
        ;;
        --pid-file)
        START_CMD_ARGS="$START_CMD_ARGS --pid-file=$2"
        shift # past argument
        shift # past value
        ;;
        --temp-dir)
        START_CMD_ARGS="$START_CMD_ARGS --temp-dir=$2"
        shift # past argument
        shift # past value
        ;;
        --log-dir)
        START_CMD_ARGS="$START_CMD_ARGS --log-dir=$2"
        shift # past argument
        shift # past value
        ;;
        --log-dir-max-size)
        START_CMD_ARGS="$START_CMD_ARGS --log-dir-max-size=$2"
        shift # past argument
        shift # past value
        ;;
        --log-file-max-size)
        START_CMD_ARGS="$START_CMD_ARGS --log-file-max-size=$2"
        shift # past argument
        shift # past value
        ;;
        --log-file-verbosity)
        START_CMD_ARGS="$START_CMD_ARGS --log-file-verbosity=$2"
        shift # past argument
        shift # past value
        ;;
        --no-color)
        START_CMD_ARGS="$START_CMD_ARGS --no-color=$2"
        shift # past argument
        shift # past value
        ;;
        --sql-audit-dir)
        START_CMD_ARGS="$START_CMD_ARGS --sql-audit-dir=$2"
        shift # past argument
        shift # past value
        ;;
        -h|--help)
        HELP=true
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#
# 2.b. Construct start command args from parameters parsed and defaults
#

START_CMD_ARGS="$START_CMD_ARGS --certs-dir=$START_CMD_CERTS_DIR --store=$START_CMD_STORE --host=$START_CMD_HOST --port=$START_CMD_PORT --http-host=$START_CMD_HTTP_HOST --http-port=$START_CMD_HTTP_PORT --logtostderr=$START_CMD_LOG_TO_STD_ERR --insecure=$START_CMD_INSECURE"
QUIT_CMD_ARGS="--certs-dir=$START_CMD_CERTS_DIR --insecure=$START_CMD_INSECURE --host=$START_CMD_HOST --port=$START_CMD_PORT"
UNIT_NAME="cockroach.$NAME.service"
UNIT_FILE_PATH="$SYSTEMD_DIR/$UNIT_NAME"
CMD_START="$BIN_PATH start $START_CMD_ARGS"
CMD_QUIT="$BIN_PATH quit $QUIT_CMD_ARGS"

#
# 3.a. Show help and break on request
#
if [ "$HELP" == true ]; then
    usage "$0"
    exit 0
fi

#
# 3.b. Show help If more arguments than expected.
#
if [ "$#" -gt "1" ]; then
    usage "$0"
    printf "Too many arguments\n"
    exit 1
fi

#
# 4. Determine if installation is needed and
# whether installer archive is provided.
#
if [ ! -z "$1" ]; then
    INSTALLER_ARCHIVE=$1

    cockroachInstallInfo="
Cockroach binary will be extracted from:
    '$INSTALLER_ARCHIVE'
and installed into
    '$BIN_PATH'

The following user will have access to cconnect
(quick access command to Cockroach SQL interface)
    '$USER'
"

elif [ ! -f "$BIN_PATH" ]; then
    usage "$0"
    printf "could not find a pre-installed version of cockroach
Provide an installer archive to proceed\n"
    exit
fi

printf "$cockroachInstallInfo
The certificates dir will be located at:
    '$START_CMD_CERTS_DIR'

The Systemd Unit file for this node will be saved at:
    '$UNIT_FILE_PATH'

The full command executed when starting this node
(by the SystemD service) will be:
    '$CMD_START'

...and for quitting:
    '$CMD_QUIT'

Do you wish to proceed this configuration? y/n
"

read proceedDecision

if [ "$proceedDecision" != "y" ] && [ "$proceedDecision" != "Y" ]; then
    printf "abort\n"
    exit 1
fi

if [ ! -z "$INSTALLER_ARCHIVE" ]; then
    printf "Installing CockroachDB...\n"
    extractRoach "$INSTALLER_ARCHIVE"
    installRoach "$INSTALLER_DIR" "$BIN_PATH" "$START_CMD_STORE"
    rm -rf "$INSTALLER_DIR"
    installCerts "$BIN_PATH" "$START_CMD_CERTS_DIR"
    installCConnect "$START_CMD_CERTS_DIR" "$USER"
    printf "CockroachDB installed at $BIN_PATH\n"
fi

printf "Installing node...\n"
installService "$SYSTEMD_DIR" "$UNIT_NAME" "$CMD_START" "$CMD_QUIT"
printf "Node installed.\n"

printf "Done. Run 'systemctl start $UNIT_NAME' to start the node\n"
exit 0

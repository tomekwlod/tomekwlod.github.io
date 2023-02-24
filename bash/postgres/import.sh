
function help {

cat << EOF

  /bin/bash $0 [source SQL] [target env]
    - source SQL should be a relative path to the file, eg: bash/postgres/backups/backup.sql

EOF
}

# set -e          # Exit script immediately if any command returns a non-zero exit status.
# set -x          # Expand and print each command before executing
set -o pipefail # more: https://buildkite.com/docs/pipelines/writing-build-scripts#configuring-bash

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
mkdir -p "$_DIR/backups"

if [ ! -f "$1" ]; then
    echo "FILE \$1: '$1' doesn't exist";
    help
    exit 1;
fi

if [ ! -f "$2" ]; then
    echo "FILE \$2: '$2' doesn't exist";
    help
    exit 1;
fi

FORCE="0"
if [ "$3" != "" ]; then
    if [ "$3" = "--force" ]; then
        FORCE="1"
    fi
fi

PB="$(basename "$1")"
echo "
  source:
    $1
"

PB="$(basename "$2")"
source $2;

set +x

THOST="${DATABASE_HOST}"
TUSER="${DATABASE_USERNAME}"
TPORT="${DATABASE_PORT}"
TPASS="${DATABASE_PASSWORD}"
TDB="${DATABASE_NAME}"
TSSL="${DATABASE_SSL}"
TOWNDB="${DATABASE_OWNER_NAME}"
TOWNUSER="${DATABASE_OWNER_USERNAME}"
TOWNPASS="${DATABASE_OWNER_PASSWORD}"

if [ "$THOST" = "localhost" ] || [ "$THOST" = "127.0.0.1" ] || [ "$THOST" = "0.0.0.0" ]; then
  # docker locally?
  THOST="host.docker.internal"
fi

echo "
  target:
    THOST:    $THOST
    TUSER:    $TUSER
    TPORT:    $TPORT
    TPASS:    $TPASS
    TDB:      $TDB
    TSSL:     $TSSL
    TOWNDB:   $TOWNDB
    TOWNUSER: $TOWNUSER
    TOWNPASS: $TOWNPASS
";

if [ "$TDB" = "" ]; then
    echo "$0 error: Environment variable DATABASE_NAME is empty or not defined in $2";
    help
    exit 1;
fi

if [ "$FORCE" = "0" ]; then
    echo "--> add --force if you want to proceed with the above settings"
    help
    exit 1;
fi

docker compose -f $_DIR/docker-compose.yaml up -d --build

echo "let's sleep for a little bit..."
sleep 2;

WITHSSL=""
if [ "${TSSL}" != "false" ] && [ "${TSSL}" != "disable" ]; then
  WITHSSL="PGSSLMODE=verify-ca"
fi

echo -e "\ndroping target database..."
docker exec -i postgresbackup /bin/bash -c "${WITHSSL} PGPASSWORD=${TOWNPASS} dropdb --if-exists -h ${THOST} -p ${TPORT} -U ${TOWNUSER} --maintenance-db=${TOWNDB} -e -f ${TDB}" > /dev/null 2>&1
CODE="$?"
if [ "$CODE" != "0" ]; then
  echo " > error: target database couldn't be dropped";
  exit 1;
fi
echo " > done"

echo -e "\ncreating target database..."
docker exec -i postgresbackup /bin/bash -c "${WITHSSL} PGPASSWORD=${TOWNPASS} psql -q -h ${THOST} -p ${TPORT} -U ${TOWNUSER} -d ${TOWNDB} -c \"CREATE DATABASE ${TDB}\"" > /dev/null 2>&1
CODE="$?"
if [ "$CODE" != "0" ]; then
  echo " > error: target empty database couldn't be created";
  exit 1;
fi
echo " > done"

BACKUPFILENAME="backups/_tmp.sql"
function cleanup {
  echo -e "\n\ncleanup...\n\n";
  unlink "${_DIR}/$BACKUPFILENAME" || true
}
# this trap basically is making a cleanup after the script exists (regardless of the status code)
# https://www.linuxjournal.com/content/bash-trap-command
# trap CMD SIGNAL
trap cleanup EXIT

echo -e "\ncopy backup file to docker volume location"
set -e
cp $1 "$_DIR/$BACKUPFILENAME"
set +e
echo " > done"

echo -e "\nrestoring database"
docker exec -i postgresbackup /bin/bash -c "${WITHSSL} PGPASSWORD=${TOWNPASS} psql -q -h ${THOST} -p ${TPORT} -U ${TOWNUSER} -f /${BACKUPFILENAME} ${TDB}" > /dev/null 2>&1
CODE="$?"
if [ "$CODE" != "0" ]; then
  echo " > error: database couldn't be restored";
  exit 1;
fi
echo -e " > done\n"
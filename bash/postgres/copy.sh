# https://www.postgresql.org/docs/current/backup-dump.html#BACKUP-DUMP-RESTORE
# https://docs.digitalocean.com/products/databases/postgresql/how-to/import-databases/
# https://stackoverflow.com/questions/22287914/pg-dump-and-pg-restore-drop-if-exists

# arr=( Ooo oOo ooO )
# # https://youtu.be/93i8txD0H3Q?t=530
# loader(){
#   while [ 1 ]
#   do
#     for i in "${arr[@]}"
#     do
#       echo -ne "\r$i"
#       sleep 0.2
#     done 
#   done
# }
# loader
# exit 0;

function help {

cat << EOF

  DRY-RUN : /bin/bash $0 [source env] [target env]
  FOR-REAL: /bin/bash $0 [source env] [target env] --force

EOF
}

# set -e          # Exit script immediately if any command returns a non-zero exit status.
# set -x          # Expand and print each command before executing
set -o pipefail # more: https://buildkite.com/docs/pipelines/writing-build-scripts#configuring-bash


_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"

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

if [ "$(basename "$1")" = "$(basename "$2")" ]; then
    echo "$0 error: source and target env files is the same file";
    help
    exit 1;
fi

PB="$(basename "$1")"
source $1;

SHOST="${DATABASE_HOST}"
SUSER="${DATABASE_USERNAME}"
SPORT="${DATABASE_PORT}"
SPASS="${DATABASE_PASSWORD}"
SDB="${DATABASE_NAME}"

if [ "$SHOST" = "localhost" ] || [ "$SHOST" = "127.0.0.1" ] || [ "$SHOST" = "0.0.0.0" ]; then
  # docker locally?
  # TODO: temporary only!
  SHOST="host.docker.internal"
fi

echo "
  source:
    SHOST:  $SHOST
    SUSER:  $SUSER
    SPORT:  $SPORT
    SPASS:  $SPASS
    SDB:    $SDB
";

if [ "$SDB" = "" ]; then
    echo "$0 error: Environment variable PROTECTED_MYSQL_DB is empty or not defined in $1";
    help
    exit 1;
fi

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

# DOCKERIMAGES=$(docker images -q postgres)
# SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
# IFS=$'\n'      # Change IFS to newline char
# images=($DOCKERIMAGES) # split the `names` string into an array by the same name
# IFS=$SAVEIFS   # Restore original IFS

# echo "-->${images[1]}"
# exit 0;
# if [[ "$(docker images -q myimage:mytag 2> /dev/null)" == "" ]]; then
#   # do something
# fi

docker compose -f $_DIR/docker-compose.yaml up -d --build

echo "let's sleep for a little bit..."
sleep 2;

BACKUPFILENAME="backups/source.sql"

function cleanup {
  echo -e "\n\ncleanup...\n\n";

  unlink "${_DIR}/$BACKUPFILENAME" || true
}
# this trap basically is making a cleanup after the script exists (regardless of the status code)
# https://www.linuxjournal.com/content/bash-trap-command
# trap CMD SIGNAL
trap cleanup EXIT

echo -e "\ndumping database..."

docker exec -i postgresbackup /bin/bash -c "PGPASSWORD=${SPASS} pg_dump -h ${SHOST} -p ${SPORT} -U ${SUSER} ${SDB} -f /${BACKUPFILENAME}" > /dev/null 2>&1
CODE="$?"
if [ "$CODE" != "0" ]; then
  echo " > error: database couldn't be copied";
  exit 1;
fi

if [ ! -f "${_DIR}/$BACKUPFILENAME" ]; then
    echo " > error: file \$BACKUPFILENAME: '${_DIR}/$BACKUPFILENAME' doesn't exist";
    help
    exit 1;
fi
echo " > dump file created: ${_DIR}/${BACKUPFILENAME}"

# ssl verif
# https://dba.stackexchange.com/questions/270706/why-would-i-download-ca-certificate-when-starting-a-managed-postgres-cluster-on

WITHSSL=""
if [ "${TSSL}" != "false" ] && [ "${TSSL}" != "disable" ]; then
  WITHSSL="PGSSLMODE=verify-ca"
fi

echo -e "\ndroping target database..."
# drop target db
docker exec -i postgresbackup /bin/bash -c "${WITHSSL} PGPASSWORD=${TOWNPASS} dropdb --if-exists -h ${THOST} -p ${TPORT} -U ${TOWNUSER} --maintenance-db=${TOWNDB} -e -f ${TDB}" > /dev/null 2>&1
CODE="$?"
if [ "$CODE" != "0" ]; then
  echo " > error: target database couldn't be dropped";
  exit 1;
fi
echo " > done"

echo -e "\ncreating target database..."
# create target db
# https://www.postgresql.org/docs/current/backup-dump.html#BACKUP-DUMP-LARGE
docker exec -i postgresbackup /bin/bash -c "${WITHSSL} PGPASSWORD=${TOWNPASS} psql -q -h ${THOST} -p ${TPORT} -U ${TOWNUSER} -d ${TOWNDB} -c \"CREATE DATABASE ${TDB}\"" > /dev/null 2>&1
CODE="$?"
if [ "$CODE" != "0" ]; then
  echo " > error: target empty database couldn't be created";
  exit 1;
fi
echo " > done"

echo -e "\nrestoring database"
# https://www.postgresql.org/docs/8.0/app-pgrestore.html
docker exec -i postgresbackup /bin/bash -c "${WITHSSL} PGPASSWORD=${TOWNPASS} psql -q -h ${THOST} -p ${TPORT} -U ${TOWNUSER} -f /${BACKUPFILENAME} ${TDB}" > /dev/null 2>&1
CODE="$?"
if [ "$CODE" != "0" ]; then
  echo " > error: database couldn't be restored";
  exit 1;
fi
echo -e " > done\n"
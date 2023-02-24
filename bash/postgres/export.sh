
function help {

cat << EOF

  /bin/bash $0 [source env]

EOF
}

# set -e          # Exit script immediately if any command returns a non-zero exit status.
# set -x          # Expand and print each command before executing
set -o pipefail # more: https://buildkite.com/docs/pipelines/writing-build-scripts#configuring-bash

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
mkdir -p "$_DIR/backups"

if [ ! -f "$1" ]; then
    echo "ENV FILE \$1: '$1' doesn't exist";
    help
    exit 1;
fi
# if [ "$2" == "" ]; then
#     echo "you need to provide exactly two arguments";
#     help
#     exit 1;
# fi

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

docker compose -f $_DIR/docker-compose.yaml up -d --build

echo "let's sleep for a little bit..."
sleep 2;

BACKUPFILENAME="backups/${SDB}_$(date '+%Y-%m-%d-%H%M%S').sql"

echo -e "\ndumping database onto: $BACKUPFILENAME"

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

echo -e " > done\n"

if [ "$1" = "--getenvparam" ]; then
  printf "PROTECTED_KUB_CRONJOB_TIME_POSTGRES_SP";
  exit 0;
fi

set -e
set -x

cat /usr/src/go-do/.env > /root/.env

source .env

set +e
set +x

if [ "$PROJECT_NAME" = "" ]; then
  echo "$0 error: PROJECT_NAME is not defined"
  exit 1
fi


set -e
set -x

function cleanup {
  sleep 600
}

trap cleanup EXIT

TARGETFILE="psql-$(date +"%H_%M_%S").sql"

PGPASSWORD=${DATABASE_PASSWORD} pg_dump -h ${DATABASE_HOST} -U ${DATABASE_USERNAME} -p ${DATABASE_PORT} ${DATABASE_NAME} -f ${TARGETFILE}

./go-do $TARGETFILE backup/$PROJECT_NAME/$(date +"%Y-%m-%d")

rm -rf "$TARGETFILE";

trap - EXIT

echo "PROTECTED_KUB_CRONJOB_WATCHDOG_POSTGRES=>>$PROTECTED_KUB_CRONJOB_WATCHDOG_POSTGRES<<"

if [ "$PROTECTED_KUB_CRONJOB_WATCHDOG_POSTGRES" != "" ]; then
  set +e
  set +x
  curl "$PROTECTED_KUB_CRONJOB_WATCHDOG_POSTGRES"
fi

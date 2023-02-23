
if [ "$1" = "--getenvparam" ]; then
  printf "PROTECTED_KUB_CRONJOB_TIME_MYSQL_SP";
  exit 0;
fi

set -e
set -x

ls -alh && pwd -LP

cat /usr/src/go-do/.env > /root/.env

source .env

set +e
set +x

if [ "$PROJECT_NAME_SHORT" = "" ]; then
  echo "$0 error: PROJECT_NAME_SHORT is not defined"
  exit 1
fi

set -e
set -x

function cleanup {
    sleep 600
}

trap cleanup EXIT

TARGETFILE="mysql-$(date +"%H_%M_%S").sql.gz"

mysqldump -C -h ${PROTECTED_MYSQL_HOST} -u ${PROTECTED_MYSQL_USER} -p${PROTECTED_MYSQL_PASS} -P${PROTECTED_MYSQL_PORT} ${PROTECTED_MYSQL_DB} | gzip -9 > "$TARGETFILE"

./go-do $TARGETFILE backup/hubs/$PROJECT_NAME_SHORT/$(date +"%Y-%m-%d")

rm -rf "$TARGETFILE";

trap - EXIT

echo "PROTECTED_KUB_CRONJOB_WATCHDOG_MYSQL=>>$PROTECTED_KUB_CRONJOB_WATCHDOG_MYSQL<<"

if [ "$PROTECTED_KUB_CRONJOB_WATCHDOG_MYSQL" != "" ]; then
  set +e
  set +x

  curl "$PROTECTED_KUB_CRONJOB_WATCHDOG_MYSQL"
fi

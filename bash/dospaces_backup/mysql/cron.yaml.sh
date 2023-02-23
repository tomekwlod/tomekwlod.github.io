_DIR_CURR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
_DIR_ROOT="$(pwd -P)";
_DIR_MAIN="$(cd $_DIR_CURR/.. && pwd -P)";

echo "root: $_DIR_ROOT"
echo "curr: $_DIR_CURR"
echo "main: $_DIR_MAIN"

if [ "$1" = "" ]; then
  (cd "$_DIR_ROOT" && find . -type f -maxdepth 1 | grep ".env.kub.")
  echo -e "\nYou need to provide exactly one parameter, like:\n\n/bin/bash $0 .env\n"
  exit 1;
fi

ENVFILE="$_DIR_ROOT/$1";
if [ ! -f "$ENVFILE" ]; then
    echo "$0 error: file: '$ENVFILE' doesn't exist"
    exit 1;
fi

SCRIPT="$_DIR_CURR/backup.sh";
if [ ! -f "$SCRIPT" ]; then
  echo "$0 error: file: '$SCRIPT' doesn't exist"
  exit 1;
fi

set -e
set -x
source "$ENVFILE"
source "$_DIR_MAIN/.env"

if [ "$PROJECT_NAME" = "" ]; then
    echo "$0 error: environment variable missing 'PROJECT_NAME'";
    exit 1;
fi
PROJECT_NAME="${PROJECT_NAME}-backup"

if [ "$DOCKER_REGISTRY" = "" ]; then
    echo "$0 error: environment variable missing 'DOCKER_REGISTRY'";
    exit 1;
fi
if [ "$TAG" = "" ]; then
    echo "$0 error: environment variable missing 'TAG'";
    exit 1;
fi
if [ "$K8S_CLUSTER" = "" ]; then
    echo "$0 error: environment variable missing 'K8S_CLUSTER'";
    exit 1;
fi
if [ "$NAMESPACE" = "" ]; then
    echo "$0 error: environment variable missing 'NAMESPACE'";
    exit 1;
fi

TMPDOCKERDIR="$_DIR_CURR/tmpdockerdir"
if ! [ -d "$TMPDOCKERDIR" ]; then
  mkdir -p "$TMPDOCKERDIR"
fi

cd ..

echo ""
cp -v "$_DIR_CURR/Dockerfile"      "$TMPDOCKERDIR/"
echo ""
(cd "$_DIR_CURR" && cp -v *.sh     "$TMPDOCKERDIR/")
echo ""
cp -v "$_DIR_MAIN/.dockerignore"  "$TMPDOCKERDIR/"
echo ""

(cd "$TMPDOCKERDIR" && docker build . --platform linux/amd64 -t "$PROJECT_NAME:$TAG")
docker tag $PROJECT_NAME:$TAG $DOCKER_REGISTRY/$PROJECT_NAME:$TAG
docker push $DOCKER_REGISTRY/$PROJECT_NAME:$TAG

set +x
echo "Visit:";
echo -e "\n\t- https://$DOCKER_REGISTRY/v2/_catalog\n\t- https://$DOCKER_REGISTRY/v2/$PROJECT_NAME/tags/list";
set -x

/bin/bash "$_DIR_ROOT/bash/kuber/switch-cluster.sh" "$K8S_CLUSTER"

cd "$_DIR_CURR";

TMPFILE="$(/bin/bash "$_DIR_ROOT/bash/cptmp.sh" "$ENVFILE" -c -g "cron-tmp")"

cp "$ENVFILE" "$TMPFILE"

# PB=backupsql.sh
PB="$(basename "$SCRIPT")"
# # FILENAME=backupsql
# FILENAME="${PB%.*}"
# if [ "$FILENAME" = "" ]; then
#   FILENAME="$PB"
# fi
# FILENAME="$(echo "$FILENAME" | sed -E 's:[^a-z0-9A-Z]+::g')"
# if [ "$FILENAME" = "" ]; then
#   echo "$0 error: FILENAME is empty"
#   exit 1
# fi

YAMLNAMEPART="$(echo "backup" | sed -E "s/[^a-z0-9]//g")"
if [ "$YAMLNAMEPART" = "" ]; then
  echo "$0 error: YAMLNAMEPART is empty"
  exit 1
fi

# this returns an env variable name only!!
CRONTIMEVARIABLE="$(/bin/bash "$SCRIPT" --getenvparam)";

TEST="^[a-zA-Z_0-9]+$"
if ! [[ $CRONTIMEVARIABLE =~ $TEST ]]; then
  echo -e "Script '/bin/bash \"$SCRIPT\" --getenvparam' should return variable name that match '${TEST}' but it has returned '$CRONTIMEVARIABLE'";
  exit 1;
fi

# displays the names and values of shell variables ( a long list )
set

CMD="echo \"\$$CRONTIMEVARIABLE\""

CRONTIME="$(eval $CMD)"

if [ "$CRONTIME" = "" ]; then
  echo "$0 error: CRONTIME is empty"
  exit 1
fi

printf "\nCOMMAND_TO_RUN=\"$PB\"\n" >> "$TMPFILE"

printf "\nPROTECTED_KUB_CRONJOB_TIME=\"$CRONTIME\"\n" >> "$TMPFILE"

# keep it this way as PROJECT_NAME will be overwritten by the .env.kub.xxx file
PROJECT_NAME_GENERATED="$PROJECT_NAME"
printf "\nPROJECT_NAME_GENERATED=\"$PROJECT_NAME_GENERATED\"\n" >> "$TMPFILE"

SECRET_NAME="${PROJECT_NAME_GENERATED}-env"
printf "\nSECRET_NAME=\"$SECRET_NAME\"\n" >> "$TMPFILE"

echo "" >> "$TMPFILE"

cat "$_DIR_MAIN/.env" >> "$TMPFILE"

# let's check if the namespace exists
set +e
# >/dev/null      - turns off stdout
# 2>/dev/null     - turns off stderr
# >/dev/null 2>&1 - turns off both
# 2>&1            - sends stderr to the same place as stdout
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1
if [ "$?" != "0" ]; then
  kubectl create namespace "${NAMESPACE}"
  kubectl get secret regcred --namespace=default -oyaml | grep -v '^\s*namespace:\s' | kubectl apply --namespace="${NAMESPACE}" -f - || true
fi
# Exit script immediately if any command returns a non-zero exit status.
set -e

/bin/bash "$_DIR_ROOT/bash/kuber/create-secret-with-files-inside.sh" -n "${NAMESPACE}" "${SECRET_NAME}" "${TMPFILE}" .env
kubectl get secrets -n "${NAMESPACE}"
kubectl describe secret "${SECRET_NAME}" -n "${NAMESPACE}"

DOCTMP="$(/bin/bash "$_DIR_ROOT/bash/envrender.sh" "$TMPFILE" "$_DIR_MAIN/cron.yaml" --clear --rmfirst -g "$YAMLNAMEPART-cron-tmp")"

kubectl apply -f "$DOCTMP";

set +x
set +e

printf "\n\n    all good\n"

printf "\n\nrun now:\n\n    kubectl get CronJob\n\n"

kubectl get CronJob -n "$NAMESPACE"

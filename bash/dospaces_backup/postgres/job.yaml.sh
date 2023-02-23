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

# PB=backup.sh
PB="$(basename "$SCRIPT")"
# # FILENAME=backup
# FILENAME="${PB%.*}"
# if [ "$FILENAME" = "" ]; then
#   FILENAME="$PB"
# fi
# FILENAME="$(echo "$FILENAME" | sed -E 's:[^a-z0-9A-Z]+::g')"
# if [ "$FILENAME" = "" ]; then
#   echo "$0 error: FILENAME is empty"
#   exit 1
# fi

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

RAND="$(openssl rand -hex 2)"
printf "\nRAND=\"$RAND\"\n" >> "$TMPFILE"

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
DOCTMP="$(/bin/bash "$_DIR_ROOT/bash/envrender.sh" "$TMPFILE" "$_DIR_MAIN/job.yaml" --clear --rmfirst -g "job-tmp")"

JOB_NAME="${PROJECT_NAME_GENERATED}-testjob"

function cleanup {
  if [ "$1" != "" ]; then
    echo -e "\n\ncleanup...\n\n";
  fi

  kubectl delete job "$JOB_NAME" -n "$NAMESPACE" || true

  if [ "$1" != "" ]; then
    sleep 3
  fi
}

cleanup first

trap cleanup EXIT

kubectl apply -f "$DOCTMP";

LIST=""
POD=""

# set +x
# while true
# do
#     # TODO: change it based on the go-sso!
#     echo "attempt to extract list of pods of the job '$JOB_NAME'"
#     LIST="$(/bin/bash "$_DIR_ROOT/bash/kuber/get-name-of-n-pod-of-the-deployment.sh" "$JOB_NAME")"
#     if [ "$LIST" = "" ]; then
#         sleep 1;
#     else
#       POD="$(echo "$LIST" | head -n 1)"
#       break;
#     fi
# done
set +x 
# TODO: export as a script maybe
# the loop tries to retrieve the pod name based on the job
while true
do
  echo "attempt to extract list of pods of the job '${JOB_NAME}'"

  LIST="$(kubectl get pods --selector=job-name="${JOB_NAME}" -n "${NAMESPACE}" | awk 'NR!=1 {print}' | awk '{print $1}')"
  # LIST="$(/bin/bash "${DIR}/scripts/get-name-of-n-pod-of-the-deployment.sh" "$JOB_NAME")"

  if [ "$LIST" = "" ]; then
      sleep 1;
  else
    POD="$(echo "$LIST" | head -n 1)"
    break;
  fi
done


echo -e "\n\nFOUND POD '$POD'\n\n"
sleep 1

# while true
# do
#     # TODO: change it based on the go-sso!
#     echo "attempt to attach to stdout of pod '$POD' last status: '$STATUS'"
#     STATUS="$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath="{.status.phase}")"
#     if [ "$STATUS" = "Running" ] || [ "$STATUS" = "Succeeded" ] || [ "$STATUS" = "Failed" ]; then
#       break;
#     fi
#     sleep 2
# done
# TODO: export as a script maybe
# this loop checks the status of the pod and if the pod is completed/exited/succeeded it will break, otherwise it will keep checking
while true
do
  PREV_STATUS="$STATUS"
  STATUS="$(kubectl get pod "$POD" -n "${NAMESPACE}" -o jsonpath="{.status.phase}")"

  if [ "$PREV_STATUS" != "$STATUS" ]; then
    echo "checking pod '$POD' status; last status: '$STATUS'"
  fi

  if [ "$STATUS" = "Succeeded" ] || [ "$STATUS" = "Completed" ] ; then
    CODE="0";
    break;
  elif [ "$STATUS" = "Error" ] || [ "$STATUS" = "Failed" ]; then
    CODE="1";
    break;
  fi

  sleep 2
done

echo -e "\n\nSTATUS '$STATUS'\n\n"

kubectl logs -n "$NAMESPACE" --follow "$POD"

set -x

if [ "$CODE" = "1" ]; then
  exit 1;
fi
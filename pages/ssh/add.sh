#!/bin/bash

set -e          # Exit script immediately if any command returns a non-zero exit status.
set -o pipefail # more: https://buildkite.com/docs/pipelines/writing-build-scripts#configuring-bash
set -a          # The option allexport (same as set -a) allows for automatic export of new and changed variables!
set -x          # Expand and print each command before executing
set +x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
ROOT="${DIR}/.."

ENV="${DIR}/.env"
if [ ! -e "$ENV" ]; then
  echo "\`${ENV}\` does not exist" 1>&2
  exit 1
fi

source $ENV

if [ "${GIT_CONFIG_NAME}" = "" ]; then
  echo "GIT_CONFIG_NAME is not defined" 1>&2
  exit 1
fi

REPO="$1"
if [ -z "$REPO" ]; then
  echo "! 1st argument seems empty, expecting a repository url" 1>&2
  exit 1;
fi

# let's replace github.com with our config name
REPO=${REPO/github.com/$GIT_CONFIG_NAME}

TARGET="$2"
if [ -z "$TARGET" ]; then
  # split the string by the /
  arr=(${REPO//\// })
  # take the last array element, then find .git string and replace it with an empty string
  REPO_DIRECTORY=${arr[${#arr[@]} - 1]/%.git/} # https://riptutorial.com/bash/example/7580/replace-pattern-in-string#:~:text=%24%20echo%20%22%24%7Ba/-,%25,-g/N%7D%22%0AI
else
#   # split the string by the /
#   arr=(${TARGET//\// })
#   # take the last array element
#   REPO_DIRECTORY=${arr[${#arr[@]} - 1]}
  REPO_DIRECTORY=$TARGET
fi

echo "REPO_DIRECTORY: $REPO_DIRECTORY"

set +a

echo -e "\nClonning the repo \"$REPO\" into \"$TARGET\"\n"

set +e
# >/dev/null      - turns off stdout
# 2>/dev/null     - turns off stderr
# >/dev/null 2>&1 - turns off both
# 2>&1            - sends stderr to the same place as stdout
RE=$(git clone $REPO $TARGET 2>&1 >/dev/null)
if [ "$?" != "0" ]; then
  echo -e "Something went wrong with cloning the repo. Here what seems to be the problem:"
  echo -e "\`$RE\`\n"
  exit 1;
fi

# Exit script immediately if any command returns a non-zero exit status.
set -e

SHORTCUTS_PATH="$HOME/shortcuts"
YESNO="n"

while true; do
    read -p "Do you want to add this project to the vscode shortcuts located in ${SHORTCUTS_PATH}? " yn
    case $yn in
        [Yy]* ) YESNO=y; break;;
        [Nn]* ) YESNO=n; break;;
        * ) echo "Please answer yes or no";;
    esac
done

if [ "$YESNO" = "y" ]; then
  SHORTCUT_NAME=${REPO_DIRECTORY//./_}

  mkdir -p $SHORTCUTS_PATH

  PWD=$(cd $REPO_DIRECTORY && pwd -LP)

  $(cat <<EOF > $SHORTCUTS_PATH/$SHORTCUT_NAME
#!/bin/sh
cd $PWD && code .
EOF)

  chmod +x $SHORTCUTS_PATH/$SHORTCUT_NAME

  echo "Shortcut '$SHORTCUT_NAME' added"
fi


echo -e "\nDone."
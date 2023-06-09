
# all tags :/
#git tag --sort=-creatordate | cat

# from: https://stackoverflow.com/a/29497919
#git log --tags --simplify-by-decoration --pretty="format:%ci %d" | grep "tag:"

#git log --no-color  --decorate=short | grep "^commit " | grep "tag: " | cut -d ' ' -f4 | sed "s/[\),]$//"

REMOTE="${1}"

if [ "${REMOTE}" = "" ]; then

  REMOTE="origin"
fi

git ls-remote --tags "${REMOTE}" | grep -v "{}" | sed -En "s/^.+\/([^\/]+).*$/\1/p"
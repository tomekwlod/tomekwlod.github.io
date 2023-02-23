
echo "standard exit 1 script"

if [ "$1" = "" ]; then

  echo "no waiting time"
else

  echo "wait $1 sec"

  sleep $1
fi

exit 1
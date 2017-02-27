#!/bin/sh
"$@"
pid=$!
while read line ; do
  :
done
echo "Watched process died"
kill -KILL $pid

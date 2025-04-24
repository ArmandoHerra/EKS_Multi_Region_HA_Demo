#!/bin/bash

URL="http://a4a9bd4d8ab794cfd83fbcdf531cee20-1593250717.us-west-2.elb.amazonaws.com/"
times=()
for i in {1..10}; do
  t=$(curl -o /dev/null -s -w "%{time_total}\n" "$URL")
  echo "Request $i: ${t}s"
  times+=("$t")
done

# Compute average
sum=0
for t in "${times[@]}"; do
  sum=$(awk "BEGIN {print $sum + $t}")
done
avg=$(awk "BEGIN {print $sum / ${#times[@]}}")
echo "Average response time: ${avg}s"

#!/bin/bash

# Process arguments
ACCOUNT=$1
REGION=$2
INSTANCE=$3

# Declare globals, in this case bash associative arrays.
declare -A RESERVES
declare -A INSTANCES

# Count active purchased reservations.
aws --profile $ACCOUNT --region $REGION \
  ec2 describe-reserved-instances \
  --filters "Name=instance-type,Values=${INSTANCE}" "Name=state,Values=active" \
  --query "ReservedInstances[].[AvailabilityZone, InstanceCount]" \
  --output text | \
  while read R C ; do
    RESERVES[${R}]=${C}
  done

# Count existing instance by region.
aws --profile $ACCOUNT --region $REGION \
  ec2 describe-instances \
  --filters "Name=instance-type,Values=${INSTANCE}" \
  --query "Reservations[].Instances[].Placement[].AvailabilityZone[]" \
  --output text | \
    xargs -n 1 | sort | uniq -c | \
    while read C R ; do 
      INSTANCES[${R}]=${C}
    done

# Compare reserves to instances.
for R in ${RESERVES[@]} ; do
  if [ ${INSTANCES[${R}]} -le ${RESERVES[${R}]} ] ; then
    FREEAZS="$FREEAZS ${R}"
  fi
done

# Output
if [ -z "$FREEAZS" ] ; then
  echo Nothing free.
  exit 1
else
  echo $FREEAZS
  exit 0
fi

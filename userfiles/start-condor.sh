#!/bin/bash
if [ -z "$CONDORMANAGER_SERVICE_HOST" ]; then
   # No manager so we must be it.
   echo Configuring as manager
   condor_configure --prefix=/usr --type=manager,submit,execute --central-manager=$HOSTNAME
else
   # There is a manager so we'll be an execute node for it.
   echo Configuring as worker
   condor_configure --type=execute --prefix=/usr \
      --central-manager=${CONDORMANAGER_SERVICE_HOST}:$CONDORMANAGER_SERVICE_PORT
fi

# Start up Condor (calling condor_master).
./condor-service.sh start
CONDOR_RESULT=$?

echo condor-service.sh result is $CONDOR_RESULT

trap "{ echo 'SIGTERM received' ; ./condor-service.sh stop ; }" SIGTERM

trap "{ echo 'SIGHUP received' ; ./condor-service.sh reload ; }" SIGHUP

# bash --login --init-file /usr/condor.sh -i &

# We don't exit the container until the Condor master daemon exits.
while [ $CONDOR_RESULT -eq 0 ]; do
	sleep 5
	./condor-service.sh status
	CONDOR_RESULT=$?
done

echo Condor service done. The result is $CONDOR_RESULT

exit $CONDOR_RESULT

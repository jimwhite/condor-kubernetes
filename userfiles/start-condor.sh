#!/bin/bash
if [ -z "$CONDORMANAGER_SERVICE_HOST" ]; then
   # No manager so we must be it.
   echo Configuring as manager on $HOSTNAME | tee info.txt
   condor_configure --prefix=/usr --type=manager,submit,execute --central-manager=$HOSTNAME
else
   # There is a manager so we'll be an execute node for it.
   echo Configuring as worker on $HOSTNAME for manager ${CONDORMANAGER_SERVICE_HOST}:$CONDORMANAGER_SERVICE_PORT \
      | tee info.txt
   condor_configure --type=execute --prefix=/usr \
      --central-manager=${CONDORMANAGER_SERVICE_HOST}:$CONDORMANAGER_SERVICE_PORT
fi

# Start up Condor (calling condor_master).
./condor-service.sh start
CONDOR_RESULT=$?

echo condor-service.sh result is $CONDOR_RESULT

# condor-service stop is currently doing a "quick" shutdown.
# Should we be doing graceful here?
trap "{ echo 'SIGTERM received' ; ./condor-service.sh stop ; }"   SIGTERM

trap "{ echo 'SIGHUP received'  ; ./condor-service.sh reload ; }" SIGHUP

# bash --login --init-file /usr/condor.sh -i &

# We don't exit the container until the Condor master daemon exits.
while [ $CONDOR_RESULT -eq 0 ]; do
	# Docker only waits 10 seconds (by default) when stopping a container
	# before coming in with SIGKILL.
	sleep 4
	./condor-service.sh status >/dev/null
	CONDOR_RESULT=$?
done

echo Condor service done. The result is $CONDOR_RESULT

exit $CONDOR_RESULT

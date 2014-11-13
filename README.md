# Condor in a Container: Running HTCondor with Kubernetes on GCE

## Prerequisites
Getting all this stuff set up belies the ease-of-use I have in mind which is that it will eventually be no more involved than installing Docker and signing up for a Google Cloud account, but such is life on the bleeding edge.

- Install Docker.  Works for Mac OS X, Windows, and Linux (easy click-to-install for the first two).  Instructions [here](https://docs.docker.com/installation/).
- Install the Google Cloud SDK.  Instructions [here](https://cloud.google.com/sdk/). If you haven't used GCE before then you should go through the [Quickstart](https://cloud.google.com/compute/docs/quickstart) to get your credentials set up and installation checked out.  Be sure to set your default project id  with `gcloud config set project <your-project-id>`.
 - Create a project on Google Cloud using the Developer Console.  You'll need to have an account with billing enabled.  There are free credit deals for new users.  Enable the cloud and compute engine APIs (a few of these aren't strictly needed but do no harm here):
   - Google Cloud Datastore API		
   - Google Cloud Deployment Manager API		
   - Google Cloud DNS API 		
   - Google Cloud Monitoring API		
   - Google Cloud Storage
   - Google Cloud Storage JSON API
   - Google Compute Engine
     - I've had trouble with the quota setting for this.  You should get 24 CPUs per region by default, but apparently enabling some other API can change that to 8 or 2.  The solution I found is to disable GCE then reenable it.  The most repeatable results seem to come from enabling the other APIs then enable GCE by clicking on the "VM instances" item in the Compute Engine menu (which may require a browser page reload).
   - Google Compute Engine Autoscaler API
   - Google Compute Engine Instance Group Manager API
   - Google Compute Engine Instance Groups API
   - Google Container Engine API
- Install Kubernetes from source.  I recommend against using a binary distribution since the one I used recently didn't work properly.  Instructions [here](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/build).  The script you want is `build/release.sh`.  Set an environment variable `KUBE_HOME` to the directory where you've installed Kubernetes for use in the next steps.

## Git the Condor-Kubernetes Files
The Dockerfile and Kubernetes configuration files are on GitHub at [https://github.com/jimwhite/condor-kubernetes](https://github.com/jimwhite/condor-kubernetes).  
```
$ git clone https://github.com/jimwhite/condor-kubernetes.git
$ cd condor-kubernetes
```
## Turn up the Condor-Kubernetes Cluster
There is a script `start-condor-kubernetes.sh` that does all these steps at once, but I recommend doing them one-at-a-time so you can see whether they succeed or not.  I've seen occassions where the cAdvisor monitoring service doesn't start properly, but you can ignore that if you don't need to use it (and it can be loaded separately from the instruction in `$KUBE_HOME/examples/monitoring`).  The default settings in `$KUBE_HOME/cluster/gce/config-default.sh` are for `NUM_MINIONS=4` + 1 master `n1-standard-1` size instances in zone `us-central1-b`.
```
$ $KUBE_HOME/cluster/kube-up.sh
```
There is a trusted build for the Dockerfile I use for HTCondor in the Docker Hub Registry at [https://registry.hub.docker.com/u/jimwhite/condor-kubernetes/](https://registry.hub.docker.com/u/jimwhite/condor-kubernetes/).  To use a different repository you would need to modify the `image` setting in the `condor-manager.json` and `condor-executor-controller.json` files.

Spin up the Condor manager pod.  It is currently configured by the `userfiles/start-condor.sh` script to be a manager, execute, and submit host.  The execute option is pretty much just for testing though.  The way the script determines whether it is master or not is by looking for the `CONDORMANAGER_SERVICE_HOST` variable configured by Kubernetes.  Using the Docker-style variables would be the way to go if this container scheme for Condor were used with Docker container linking too.
```
$ $KUBE_HOME/cluster/kubecfg.sh -c condor-manager.json create pods
```

Start the Condor manager service.  The executor pods will be routed to the manager via this service by using the `CONDORMANAGER_SERVICE_HOST` (and `..._PORT`) environment variables.
```
$ $KUBE_HOME/cluster/kubecfg.sh -c condor-manager-service.json create services
```
Start the executor pod replica controller.  The executors currently have submit enabled too, but for applications that don't need that capability it can be omitted to save on network connections (whose open file description space on the collector can be a problem for larger clusters).
```
$ $KUBE_HOME/cluster/kubecfg.sh -c condor-executor-controller.json create replicationControllers
```

You should see 3 pods for Condor (one manager and two executors), initially in 'Pending' state and then 'Running' after a few minutes.
```
$ $KUBE_HOME/cluster/kubecfg.sh list pods
```
## SSH to a Minion
Find the id of a minion that is running Condor from the list of pods.  You can then `ssh` to it thusly:
```
$ gcloud compute ssh --zone us-central1-b root@kubernetes-minion-2
```
Then use `docker ps` to find the id of the container that is running Condor and use `docker exec` to run a shell in it:
```
root@kubernetes-minion-2:~# docker exec -it fb91ab213aa7 /bin/bash
```
And `condor_status` should show nodes for the manager and the two executor pods:
```
[root@24601939-6a55-11e4-b56c-42010af02f49 root]# condor_status
Name               OpSys      Arch   State     Activity LoadAv Mem   ActvtyTime

24601939-6a55-11e4 LINUX      X86_64 Unclaimed Idle      0.010 3711  0+00:04:36
2460f5e3-6a55-11e4 LINUX      X86_64 Unclaimed Idle      0.040 3711  0+00:04:35
condor-manager-1   LINUX      X86_64 Unclaimed Idle      0.020 3711  0+00:04:35
                     Total Owner Claimed Unclaimed Matched Preempting Backfill

        X86_64/LINUX     3     0       0         3       0          0        0

               Total     3     0       0         3       0          0        0
```
## Changing the Executor Replica Count
The Condor Executor pod replica count is currently set to 2 and can be changed using the `resize` command (see also the `$KUBE_HOME/examples/update-demo` to see another example of updating the replica count).
```
$ $KUBE_HOME/cluster/kubecfg.sh resize condorExecutorController 6
```
If you list the pods then you'll see some executors are '&lt;unsassigned>' because the number of minions is too low.  Auto-scaling for Kubernetes on Google Cloud is currently in the works and is key to making this a generally useful appliance.
## Shut Down the Cluster
Be sure to turn the lights off when you're done...
```
$ $KUBE_HOME/cluster/kube-down.sh
```
## Next Steps
There remain several things to do to make this a truly easy-to-use and seamless research tool.  A key reason for using Docker here besides leveraging cloud services is being able to containerize the application being run.  While Docker images as Condor job executables is a natural progression (as is Docker volume-based data management), the model we have here is just as good for many purposes since we just bundle Condor and the application together in a single image.  The way I plan to use that is to add a submit-only pod which submits the workflow and deals with data management.  Of course for bigger data workflows a distributed data management tool such as GlusterFS or HDFS would be used (both of which have already have been Dockerized).

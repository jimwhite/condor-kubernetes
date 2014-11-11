## Prerequisites
- Install Docker.  Works for Mac OS X, Windows, and Linux (easy click-to-install for the first two).  Instructions [here](https://docs.docker.com/installation/).
- Install the Google Cloud SDK.  Instructions [here](https://cloud.google.com/sdk/). If you haven't used GCE before then you should go through the [Quickstart](https://cloud.google.com/compute/docs/quickstart) to get your credentials set up and installation checked out.
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
- Install Kubernetes from source.  I recommend against using a binary distribution since the one I used recently didn't work properly.  Instructions [here](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/build).  The script you want is `build/release.sh`.

## Git the Condor-Kubernetes Files

## Turn up the Kubernetes Cluster

## SSH to a Minion

## Check Out the Monitoring



 
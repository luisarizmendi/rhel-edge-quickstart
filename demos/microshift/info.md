
## Microshift

In this demo you can show how to deploy a RHEL for Edge image including [Microshift](https://github.com/redhat-et/microshift).

### Preparing the demo

The steps to prepare this demo are:

1) If you want to include [Microshift](https://github.com/redhat-et/microshift) in the deployment you will need to add some additional repositories in the image-builder, so I created the script `add-microshift-repos.sh` under `demos/microshift` directory that you will need to execute right **before** creating the image with script `1-create-image.sh`.

> NOTE: As result of runnning this script you will include files under `/etc/osbuild-composer/repositories/` which it's a good idea to remove right after you created the microshift image in order to not impacting other image builds.

```
cd demos/microshift
./add-microshift-repos.sh
```

2)  Prepare the blueprint using the `blueprint-microshift.toml.example` as reference

Make a copy of the blueprint example file (ie, `cp blueprint-microshift.toml.example ../../blueprint.toml`) and include the SSH key and the password hash.


3) Create the RHEL for Edge image using that blueprint and deploy it into the edge device


### Running the demo

Once the edge device is deployed, you can use Microshift by doing this:

1) Find the edge device IP address and ssh to it (using the `admin` user if you used the blueprint example)

2) Modify the local `kubeconfig` file with the edge device "public" IP

```
sudo sed 's/server:*.*/server: https:\/\/<SERVER IP>:6443/' /var/lib/microshift/resources/kubeadmin/kubeconfig > kubeconfig-microshift
```

> Example: `sudo sed 's/server:*.*/server: https:\/\/192.168.122.117:6443/' /var/lib/microshift/resources/kubeadmin/kubeconfig > kubeconfig-microshift`

3) Download and use the new kubeconfig created (`kubeconfig-microshift`) to access the Microshift API

```
oc --kubeconfig kubeconfig-microshift get namespace
```

> NOTE: It could take some time to Microshift to start, if you get a "connection refused" error message wait a little bit longer and try again


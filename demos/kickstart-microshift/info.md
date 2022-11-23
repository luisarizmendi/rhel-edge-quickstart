
## Microshift

In this demo you can show how to deploy a RHEL for Edge image including [Microshift](https://github.com/redhat-et/microshift).

> NOTE: At this moment, there are no repos for RHEL 9, so if you use it, RHEL 8 OCP repositories will be used

### Preparing the demo

The steps to prepare this demo are:

0) Run the Image Builder pre-requisites if you have not done it yet: `./0-pre-requisites-osbuild.sh`


1) If you want to include [Microshift](https://github.com/redhat-et/microshift) in the deployment you will need to add some additional repositories in the image-builder, so I created the script `microshift-repo/add-microshift-repos.sh` that you will need to execute **as a privileged user** right **before** creating the image with script `1-create-image.sh`.

> NOTE: This script will build the required Microshift RPMs so it will take some time

```
cd demos/microshift
./add-microshift-repos.sh
cd ..
```

2) Create a new blueprint file using the `blueprint-microshift.toml.example` as reference

Make a copy of the blueprint example file and include the SSH key and the password hash.

```
cp blueprint-microshift.toml.example ../../blueprint-microshift.toml

cd ../..

vi blueprint-microshift.toml
```


3) Create a new kickstart file using the `microshift.ks.example` as reference. You need to setup in the `ostreesetup` line the right IP of the HTTP server where the OSTree repo is located (you image builder if you didn't changed it) along with the right RHEL release and arch. For example, if you are using a RHEL 8 on x86 image hosted in 192.168.122.208:8090

`ostreesetup --nogpg  --osname=rhel --remote=edge --url=http://192.168.122.208:8090/repo/ --ref=rhel/8/x86_64/edge`

Also look for the line `< PULL SECRET >` and include there your Pull Secret ([you can download it from here](https://console.redhat.com/openshift/downloads#tool-pull-secret))


4) Create the RHEL for Edge image using that blueprint and deploy it using the kickstart into the edge device following one of the methods shown in [rhel-edge-quickstart README](https://github.com/luisarizmendi/rhel-edge-quickstart), for example:

```
./1-create-image.sh -b blueprint-microshift.toml

./2-publish-image.sh -i xxxxxx -k kickstart.ks
```


### Running the demo

Once the edge device is deployed, you can use Microshift by doing this:

1) Find the edge device IP address and ssh to it (using the `admin` user if you used the blueprint example)

2) Modify the local `kubeconfig` file with the edge device "public" IP

```
sudo sed 's/server:*.*/server: https:\/\/<SERVER IP>:6443/' /var/lib/microshift/resources/kubeadmin/kubeconfig > kubeconfig-microshift
```

> Example: `sudo sed 's/server:*.*/server: https:\/\/192.168.122.117:6443/' /var/lib/microshift/resources/kubeadmin/kubeconfig > kubeconfig-microshift`

3) Download (the example RHEL for Edge image does not have `kubectl` or `oc` clients installed) and use the new kubeconfig created (`kubeconfig-microshift`) to access the Microshift API


```
scp <USER>@<SERVER IP>:/var/home/admin/kubeconfig-microshift .

oc --kubeconfig kubeconfig-microshift get namespace
```

> NOTE: It could take some time to Microshift to start, if you get a "connection refused" error message wait a little bit longer and try again


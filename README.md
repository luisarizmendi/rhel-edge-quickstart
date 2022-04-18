# Description


These scripts help to quickly create and publish RHEL for Edge images


# Usage

You just need t:

0) Run the `0-pre-requisites-osbuild.sh` script to deploy image-builder

1) Create your RHEL for edge image based on a blueprint with `1-create-image.sh`. You can find a blueprint example in `blueprint.toml.example`

2) Publish the image with `2-publish-image.sh` 

3) (optional) Create an ISO or RAW image for offline deployments with `3-create-offline-deployment.sh`


NOTE: You can get help and examples by typing  `<script> --help`


# RHEL for Edge deployment types



There are two main groups of RHEL for Edge deployment types:

* Deploying using directly a repository published on the network (network based deployment)

* Creating an ISO/image with the repository embedd to deploy without the need of accessing to the repository using the network (non-network based deployment)


## Network based deployment

There are three options while deploying RHEL for Edge following the network based approach:

### Option 1) Online repo using standard RHEL ISO 

With this option you will run a container with nginx serving the OSTree depository along with a kickstart.ks file. 

In order to deploy the image you just need to use the defalt RHEL boot ISO and introduce (pressing `TAB` during the GRUB meny) the required kernel arg (`inst.ks`) pointing to the kickstart file published in the server, something like this: 

```
<other kernel args> inst.ks=http://192.168.122.129:8080/kickstart.ks
```

If you want to use this approach by publishing the repository using the server IP and port 8080 (defaults), you need to:

1) Create the RHEL for Edge image with `1-create-image.sh` script (copy the image id)

```
./2-publish-image.sh -i 
``` 


### Option 2) Online repo using custom RHEL ISO

### Option 3) UEFI HTTP Boot







## Non-network based deployment


### Option 1) Offline ISO fully automated

### Option 2) Offline ISO partially automated

### Option 3) RAW/QCOW2 image

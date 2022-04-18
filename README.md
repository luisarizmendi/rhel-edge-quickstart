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


### Option 1) Online repo using standard RHEL ISO 

### Option 2) Online repo using custom RHEL ISO

### Option 3) UEFI HTTP Boot







## Non-network based deployment


### Option 1) Offline ISO fully automated

### Option 2) Offline ISO partially automated

### Option 3) RAW/QCOW2 image

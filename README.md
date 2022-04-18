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


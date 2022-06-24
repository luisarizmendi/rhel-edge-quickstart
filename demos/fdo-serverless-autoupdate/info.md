## Serverless service with podman image auto-update using FDO

This demo.based on a [Red Hat Summit 2021 demo](https://github.com/RedHatGov/RFESummit2021), shows how you can create a Serverless service using  [Podman](https://podman.io/) automating the installation using [FIDO Device Onboard](https://fidoalliance.org/intro-to-fido-device-onboard/) file. You will be also able to play with the [Podman auto-update feature](https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html).

### Preparing the demo

The steps to prepare this demo are:

1) Create the container image for the Serverless service

If you want to create an image with a simple HTTP server (you could potentially use another image that you already have) you can use the `Dockerfile` in the `service` directory to create a new image and then push that image to a registry:

```
cd demos/fdo-serverless-autoupdate
cd service
buildah build .
podman tag <image id> <registry/user/image:tag>
podman push <registry/user/image:tag>
cd ..
```

> NOTE: Use the image id that buildah build will output to add a tag to it (ie. in my case `podman tag d5a11c5eb67 quay.io/luisarizmendi/simple-http:prod`)



3) Prepare the blueprint using the `blueprint-serverless.toml.example` as reference

Make a copy of the blueprint example file (ie, `cp blueprint-serverless.toml.example ../../blueprint.toml`) and include the SSH key and the password hash.


3) Include your public SSH key and the right disk drive (`disk_label` parameter) in the `serviceinfo_api_server.yml.example` file. Also check the port for your fdo-serviceinfo (default with these scripts is 8093)

> NOTE: There are other parameters such as `service_info_auth_token` and `admin_auth_token` that will be completed by the `prepare-fdo-server.sh` during next step.


4) Run the `prepare-fdo-server.sh` script to prepare the required files on the fdo server.


5) Use the [Non-Network based deployment methods](https://github.com/luisarizmendi/rhel-edge-quickstart#non-network-based-deployment) but including the FDO serve (`-f`) during the last step.

Example using default values:

```
./3-create-offline-deployment.sh -f -d vda
```


### Running the demo

Once the edge device is deployed, you can check your **Serverless** service by doing this:

1) Find the edge device IP address and ssh to it (using the `admin` user if you used the blueprint example)

2) Check that the container image has been auto-pulled for the `core` user (it could take some time depending on your connection): `sudo runuser -l core -c "podman image list"`

```
[admin@edge-node ~]$ sudo runuser -l core -c "podman image list"

[sudo] password for admin:

REPOSITORY                         TAG         IMAGE ID      CREATED      SIZE
quay.io/luisarizmendi/simple-http  prod      d5a11c5eb672  3 hours ago  435 MB

```

3) Continuously check that the containers running on the system (at this point you should find an empty list): `sudo runuser -l core -c "watch podman ps"`

4) Access the service published on port 8080 on the edge device (`http://<edge-device-ip>:8080`)

At this point you will see how a new container will start as soon as the request is made (Serverless)


If you want to check the podman **image auto-update** feature you can:

1) Access the service published on port 8080 on the edge device (`http://<edge-device-ip>:8080`) and check the message

2) Change the message in the `index.html` file, create a new container image and push it to the registry using the same tag that you used

```
cd demos/fdo-serverless-autoupdate
cd service
echo "NEW MESSAGE IN v2" > index.html
buildah build .
podman tag <image id> <registry/user/image:tag>
podman push <registry/user/image:tag>
cd ..
```

3) Wait some seconds and try to access again the service on the edge device (the new message should appear)

4) Stop requests to the servics and wait 30 seconds, the container should be stopped (stop time will depend on the service)

## Serverless service with podman image auto-update

This demo.based on a [Red Hat Summit 2021 demo](https://github.com/RedHatGov/RFESummit2021), shows how you can create a Serverless service using  [Podman](https://podman.io/) automating the installation using the `kickstart.ks` file. You will be also able to play with the [Podman auto-update feature](https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html).

### Preparing the demo

The steps to prepare this demo are:

1) Create the container image for the Serverless service

If you want to create an image with a simple HTTP server (you could potentially use another image that you already have) you can use the `Dockerfile` in the `service` directory to create a new image and then push that image to a registry:

```
cd demos/serverless-autoupdate
cd service
buildah build .
podman tag <image id> <registry/user/image:tag>
podman push <registry/user/image:tag>
cd ..
```

> NOTE: Use the image id that buildah build will output to add a tag to it (ie. in my case `podman tag d5a11c5eb67 quay.io/luisarizmendi/simple-http:prod`)


2) Prepare the kickstart.ks for the automated configuration using `kickstart-serverless.toml.example` as reference

You will need to point to the right repository IP in the kickstart and also to the service image (on the registry) that you will use, so make a copy of the kickstart example file (ie, `cp kickstart-serverless.ks.example ../../kickstart.ks`) and change the required values.

You should look for the string `192.168.122.157:8080` (1 occurrence) and substitute it by your repo server and `quay.io/luisarizmendi/simple-http:prod` (2 occurrences) by the URL that points to your image in the registry.



3) Prepare the blueprint using the `blueprint-serverless.toml.example` as reference

Make a copy of the blueprint example file (ie, `cp blueprint-serverless.toml.example ../../blueprint.toml`) and include the SSH key and the password hash.


4) Run any of the [Network based deployment methods](https://github.com/luisarizmendi/rhel-edge-quickstart#network-based-deployment) to create the Rhel for Edge repository (you don't have a kickstart file when using the off-line approaches)


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
cd demos/serverless-autoupdate
cd service
echo "NEW MESSAGE IN v2" > index.html
buildah build .
podman tag <image id> <registry/user/image:tag>
podman push <registry/user/image:tag>
cd ..
```

3) Wait some seconds and try to access again the service on the edge device (the new message should appear)


> NOTE: Scale down of the service when there are no more request is a feature that will bring RHEL 9

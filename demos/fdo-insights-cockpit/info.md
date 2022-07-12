## RHEL and Insights using FDO

This demo shows the deployment of a RHEL for Edge system registered in Red Hat Console using [FIDO Device Onboard](https://fidoalliance.org/intro-to-fido-device-onboard/), so you won't need to include any sensitive information (such as Red Hat console credentials) into the ISO image that you will need to deliver to deploy the system.

### Preparing the demo

The steps to prepare this demo are:

1) 2) Prepare the blueprint using the `blueprint-insights.toml.example` as reference including the ssh key and user information.

Make a copy of the blueprint example file (ie, `cp blueprint-insights.toml.example ../../blueprint-insights.toml`) and include the SSH key and the password hash.


3) In the FDO `serviceinfo_api_server.yml.example` file. include
* Your public SSH key
* The right disk drive (`disk_label` parameter) 
* Your Red Hat console credentials. You will need to include the[activation key and the organization ID](https://access.redhat.com/articles/3047431) in the `<MY ORGID>` and `<MY ACTIVATIONKEY>` placeholders.

> NOTE: There are other parameters such as `service_info_auth_token` and `admin_auth_token` that will be filled in by the `prepare-fdo-server.sh` during next step.


4) Run the `prepare-fdo-server.sh` script to prepare the required files on the fdo server, which completes the information contained by `serviceinfo_api_server.yml.example` and make it affective in the FDO service running on the server. 


5) Back to the root folder (`../../`) and use the blueprint-insights.toml with any of the [Non-Network based deployment methods](https://github.com/luisarizmendi/rhel-edge-quickstart#non-network-based-deployment) including the FDO serve (`-f`) during the last step.

Example using default values and vda as disk where to install the OS:

```
./1-create-image.sh -b blueprint-insights.toml.toml

./2-publish-image.sh -i 5676ff58-a6c7-4c49-a402-b70467602224

./3-create-offline-deployment.sh -f -d vda
```

> NOTE: Remember to use UEFI loader in your system



### Running the demo


> NOTE: After the deployment it could take some time until the fdo-client runs and configures everything. You can double check if that happened taking a look at the Journal (`journalctl | grep "Performing TO2 protocol"`) or forcing it with `systemctl restart fdo-client-linuxapp.service`.


Once the edge device is deployed, you can check your **Serverless** service by doing this:

1) Find the edge device IP address and ssh to it (using the `admin` user if you used the blueprint example)

2) Check that the container image has been auto-pulled for the `admin` user (it could take some time depending on your connection): `sudo runuser -l admin -c "podman image list"`

```
[admin@edge-node ~]$ sudo runuser -l admin -c "podman image list"

[sudo] password for admin:

REPOSITORY                         TAG         IMAGE ID      CREATED      SIZE
quay.io/luisarizmendi/simple-http  prod      d5a11c5eb672  3 hours ago  435 MB

```

3) Continuously check that the containers running on the system (at this point you should find an empty list): `sudo watch 'runuser -l admin -c "podman ps"'`

4) Access the service published on port 8080 on the edge device (`http://<edge-device-ip>:8080`)

At this point you will see how a new container will start as soon as the request is made (Serverless)


If you want to test the scale-down , just stop the requests to the servics and wait 10 seconds, the container should start the shutdown (stop time will depend on the service).


If you want to check the podman **image auto-update** feature you can:

> NOTE: Podman auto-update works if the container is running. If you scaled-down to zero the new version won't ge pulled.

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

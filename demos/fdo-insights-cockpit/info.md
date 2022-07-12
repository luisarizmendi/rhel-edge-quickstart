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


5) Back to the root folder (`cd ../../`) and use the blueprint-insights.toml with any of the [Non-Network based deployment methods](https://github.com/luisarizmendi/rhel-edge-quickstart#non-network-based-deployment) including the FDO serve (`-f`) during the last step.

Example using default values and vda as disk where to install the OS:

```
./1-create-image.sh -b blueprint-insights.toml

./2-publish-image.sh -i 5676ff58-a6c7-4c49-a402-b70467602224

./3-create-offline-deployment.sh -f -d vda
```

> NOTE: Remember to use UEFI boot loader in your system



### Running the demo

The demo will focus first on managing and get some information directly from the device (using a GUI) and then move to [Red Hat console](https://console.redhat.com) and show some of its features. 

> NOTE: After the deployment it could take some time until the fdo-client runs and configures everything. You can double check if that happened taking a look at the Journal (`journalctl | grep "Performing TO2 protocol"`) or forcing it with `systemctl restart fdo-client-linuxapp.service`.


Once the edge device is deployed, you can find the IP of the device in the console screen (if any) since you will see a message like this one:

`Web console: https://localhost:9090/ or https://<device ip>:9090/ `

1) The blueprint used to deploy the device includes `Cockpit` GUI to manage directly the node, so try to log into it in `https://<device ip>:9090/` using the user and password configured in the blueprint. You should see something like this:

> NOTE: Probably you won't be using root user, so in order to get all the Cockpit functions you should "Turn on administrative access" (sudo) by clicking on the blue button on top of the page.

<p align="center">  <img src="../../doc/demos/fdo-insights-cockpit/cockpit-overview.png" alt="Cockpit GUI"/></p>

> NOTE: Available updates failed becase they are based in RHEL based on RPM packages, not OSTree

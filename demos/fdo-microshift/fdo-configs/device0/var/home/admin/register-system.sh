#!/bin/bash
RHC_ORGID=$1
RHC_ACTIVATION_KEY=$2



subscription-manager status | grep Unknown

if [ $(echo $?) = 0 ]
then
		# Register with RHSM
[[ -v RHC_ORGID ]] \
	&& subscription-manager register --org $RHC_ORGID --activationkey $RHC_ACTIVATION_KEY --force \
	|| subscription-manager register --username $RHC_USER --password $RHC_PASS --auto-attach --force

# Register with Insights
insights-client --register --group=edge-factory
insights-client --enable-schedule 

# Enable and start RHCD service
systemctl enable rhcd.service
systemctl restart rhcd.service

# Register with RHC
[[ -v RHC_ORGID ]] \
&& rhc connect --organization $RHC_ORGID --activation-key $RHC_ACTIVATION_KEY \
|| rhc connect --username $RHC_USER --password $RHC_PASS

#		systemctl status rhcd
fi

insights-client --compliance

exit 0
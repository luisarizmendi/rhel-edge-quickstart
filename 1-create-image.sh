#!/bin/bash

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This Script creates a Blueprint and edge-commit image"
   echo
   echo "Syntax: $0 [-b|-u]"
   echo ""
   echo "options:"
   echo "b     Blueprint file (required)."
   echo "u     Update from this OSTree commit id. If selected it will use the last commit id on the existing repo as parent for the new ostree commit."
   echo
   echo "Example: $0 -b blueprint-demo.toml -u 65a4da4295a2936820cf2eb82ac687989bb9d332d947cb8bdfa39d15d745001f"
   echo ""
}



############################################################
############################################################
# Main program                                             #
############################################################
############################################################
blueprint_file=""
blueprint_name=""
update=false
parent_id=""



############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":b:u:" option; do
   case $option in
      b)
         blueprint_file=$OPTARG;;
      u)
         update=true
         parent_id=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         echo ""
         Help
         exit -1;;
   esac
done

if [ -z "$blueprint_file" ]
then
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "You must define the Blueprint file with option -b"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo ""
        echo ""
        Help
        exit -1

fi


# I assume that the name is the first entry in the file
blueprint_name=$(head -n1 ${blueprint_file} | awk -F '"' '{print $2}')


############################################################
# Create Blueprint and image.                              #
############################################################

echo ""
echo "Pushing Blueprint..."

composer-cli blueprints push ${blueprint_file}


# $(!!) Not working in shell script so I use tmp file
echo ""
echo "Creating image..."



if [ $update = true ]
then
    composer-cli compose start-ostree --parent $parent_id $blueprint_name edge-commit  > .tmp

else
    composer-cli compose start-ostree ${blueprint_name} edge-commit > .tmp
fi


image_commit=$(cat .tmp | awk '{print $2}')

# Wait until image is created
RESOURCE="$image_commit"
command="composer-cli compose status"
echo_finish="FINISHED"
echo_failed="FAILED"
while [[ $($command | grep "$RESOURCE" | grep $echo_finish > /dev/null ; echo $?) != "0" ]]
do 
    if [[ $($command | grep "$RESOURCE" | grep $echo_failed > /dev/null ; echo $?) != "1" ]]
    then
        echo ""
        echo "!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "Error creating the image"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!"
        echo ""
        exit -1
    fi
    echo "Waiting for $RESOURCE" && sleep 60
done






echo ""
echo ""
echo "*********************************************************************************************"
echo "Blueprint ${blueprint_name} and edge-commit image created"
echo "*********************************************************************************************"
echo ""
echo ""














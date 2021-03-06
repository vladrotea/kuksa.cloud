#
# ******************************************************************************
# Copyright (c) 2019 Bosch Software Innovations GmbH.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v2.0
# which accompanies this distribution, and is available at
# https://www.eclipse.org/org/documents/epl-2.0/index.php
#
# *****************************************************************************
#
#!/bin/bash

# Make the script fail if a command fails
set -e

SCRIPTPATH=$(dirname "$(readlink -f "$0")")
NAMESPACE=hawkbit

. $SCRIPTPATH/../utils/allIncludes.inc

echo
echo "##########################################################"
echo "##########################################################"
echo "############### Eclipse hawkBit deployment ###############"
echo "##########################################################"
echo "##########################################################"

echo
echo "########## Initialization ##########"

cd $SCRIPTPATH

echo 
echo "##### Check out repository #####"

git clone https://github.com/eclipse/hawkbit.git

echo
echo "########## Script conversion ##########"

cd $SCRIPTPATH/hawkbit/hawkbit-runtime/docker

echo
echo "##### Convert docker compose file to kubernetes resource files #####"

# Note that the following command requires the installation of the command line tool kompose.
# Installation instructions can be found at http://kompose.io/
kompose convert

echo
echo "##### Replace relevant parts in kubernetes resource files #####"

sed -i 's/spec:/spec:\n  type: LoadBalancer/' hawkbit-service.yaml

echo 
echo "##### Configure static IP addresses ######"
IP_ADDRESSES_FILE=`getIpAddressesFile`
if [[ -f $IP_ADDRESSES_FILE ]]; then
	echo "Loading IP addresses from $IP_ADDRESSES_FILE ..."
	. $IP_ADDRESSES_FILE
	configureStaticIpAddress "hawkbit-service.yaml" "hawkbit"	
else
	echo "No static IP addresses will be configured because file is missing: $IP_ADDRESSES_FILE"
fi

echo
echo "########## Deployment ##########"

echo
echo "##### Create namespace #####"
kubectl create namespace $NAMESPACE

echo
echo "##### Deploy kubernetes resources #####"
kubectl apply -f hawkbit-deployment.yaml -n $NAMESPACE
kubectl apply -f hawkbit-service.yaml -n $NAMESPACE
kubectl apply -f mysql-deployment.yaml -n $NAMESPACE
kubectl apply -f mysql-service.yaml -n $NAMESPACE
kubectl apply -f rabbitmq-deployment.yaml -n $NAMESPACE
kubectl apply -f rabbitmq-service.yaml -n $NAMESPACE

echo
echo  "########## Final cleanup ##########"

cd $SCRIPTPATH
ls -lah

echo
echo "##### Delete hawkbit folder #####"

rm -rf hawkbit
ls -lah


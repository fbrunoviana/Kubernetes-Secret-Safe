#!/bin/bash

export hostip=$(hostname  -I | cut -f1 -d' ' | sed 's/[.]/-/g')
sed "s/IPADDR/$hostip/g" < ./nginx.yaml  > /tmp/nginx.yaml
kubectl create -f /tmp/nginx.yaml
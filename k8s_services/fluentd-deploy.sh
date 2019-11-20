#!/bin/env bash

clustername=fsi405-eks
region=us-east-2
fluentd=cwagent-fluentd.yaml
cloudwatchlogsfull=arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
cloudwatchfull=arn:aws:iam::aws:policy/CloudWatchFullAccess
rolename=$(aws iam list-roles --output text | grep EksStack-fsi405eksDefaultCapacityInstanceRole | awk -F: '{print $6}' | awk '{print $1}' | awk -F/ '{print $2}')

echo "Attaching CloudWatchFull and CloudWatchLogFullAccess policies to EKS worker node role"
aws iam attach-role-policy --role-name ${rolename} --policy-arn ${cloudwatchlogsfull}
aws iam attach-role-policy --role-name ${rolename} --policy-arn ${cloudwatchfull}

echo "Deploying fluentd to EKS"
sed 's/{{cluster_name}}/fsi405-eks/;s/{{region_name}}/us-east-2/' ./fluentd/${fluentd} | kubectl apply -f -
# kubectl logs -n amazon-cloudwatch $(kubectl get po -n amazon-cloudwatch | egrep -o "fluentd-cloudwatch[a-zA-Z0-9-]+") -f

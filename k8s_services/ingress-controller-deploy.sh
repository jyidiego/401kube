#!/bin/env bash

REGION=us-east-2
INGRESS_POLICY=/home/ec2-user/environment/401kube/k8s_services/ingress_controller/iam-policy.json


echo "Tagging public subnets"
for i in 1 2;do
  subnetId=$(aws ec2 describe-subnets --filters Name=tag:Name,Values="EksStack/VPC/Public-LBs-NATsSubnet${i}" --region ${REGION} | grep SubnetId | awk -F\" '{print $4}')
  aws ec2 create-tags --resources ${subnetId} --tags Key='kubernetes.io/cluster/fsi405-eks',Value=shared Key='kubernetes.io/role/elb',Value=1  --region ${REGION}
done

echo "Creating IAM policy for ALB Ingress Controller"
policyarn=$(aws iam create-policy --policy-name ALBIngressControllerIAMPolicy --policy-document file://${INGRESS_POLICY} | grep Arn | awk -F\" '{print $4}')

if [[ -z ${policyarn} ]];then
  exit 1
fi

echo "Attaching policy to EKS worker node role"
rolename=$(aws iam list-roles --output text | grep EksStack-fsi405eksDefaultCapacityInstanceRole | awk -F: '{print $6}' | awk '{print $1}' | awk -F/ '{print $2}')
aws iam attach-role-policy --role-name ${rolename} --policy-arn ${policyarn}

echo "Create Service Account, Cluster Role, and Cluster Role Binding"
kubectl apply -f ./ingress_controller/rbac-role.yaml

echo "Deploy Ingress Controller"
sed 's/# - --cluster-name=devCluster/- --cluster-name=fsi405-eks/' ./ingress_controller/alb-ingress-controller.yaml | kubectl apply -f -

echo "Checking logs.....CTRL C when you see that it is working"
kubectl logs -n kube-system $(kubectl get po -n kube-system | egrep -o "alb-ingress[a-zA-Z0-9-]+") -f


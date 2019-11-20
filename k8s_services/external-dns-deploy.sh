#!/bin/env bash

route53fullaccess=arn:aws:iam::aws:policy/AmazonRoute53ResolverFullAccess
rolename=$(aws iam list-roles --output text | grep EksStack-fsi405eksDefaultCapacityInstanceRole | awk -F: '{print $6}' | awk '{print $1}' | awk -F/ '{print $2}')

echo "Route53FullAccess policy attachment to EKS Worker Node"
aws iam attach-role-policy --role-name ${rolename} --policy-arn ${route53fullaccess}

echo "Deploy external DNS Service"
dns_domain=$(aws route53 list-hosted-zones | egrep -o ".*builder[0-9]+.fsi405.jyidiego.net" | awk -F \" '{print $4}')
sed 's@external-dns-test.my-org.com@'"$dns_domain"'@' external_dns/external-dns.yaml | kubectl apply -f -

echo "Checking logs.....CTRL C when you see that it is working"
kubectl logs -n kube-system $(kubectl get po -n kube-system | egrep -o "external-dns[a-zA-Z0-9-]+") -f 

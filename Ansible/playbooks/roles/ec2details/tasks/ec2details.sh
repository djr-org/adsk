#!/bin/bash

for server in $2
do
 credentials=`aws sts assume-role --role-arn "arn:aws:iam::$server:role/isg-ansible" --role-session-name "ISGAnsible" --output json`
 export AWS_ACCESS_KEY_ID=$(echo $credentials|jq -r .Credentials.AccessKeyId)
 export AWS_SECRET_ACCESS_KEY=$(echo $credentials|jq -r .Credentials.SecretAccessKey)
 export AWS_SESSION_TOKEN=$(echo $credentials|jq -r .Credentials.SessionToken)
 /usr/local/bin/aws ec2 describe-instances --filters Name=instance-state-name,Values=running --region $1 --output json | jq -r .Reservations[].Instances[].Tags
 unset AWS_ACCESS_KEY_ID
 unset AWS_SECRET_ACCESS_KEY
 unset AWS_SESSION_TOKEN
done


#!/bin/bash

stopec2() {


    setcredentials $3

    for server in `/usr/local/bin/aws ec2 describe-instances --filters Name=tag:SilenceTime,Values=$1 Name=instance-state-name,Values=running --region $2 --output json | jq -r .Reservations[].Instances[].InstanceId`
    do
        `/usr/local/bin/aws ec2 stop-instances --instance-ids $server --region $2`
         echo "Server - $server is Stopped"
    done

    unsetcredentials

}

startec2() {

    setcredentials $3

    for server in `/usr/local/bin/aws ec2 describe-instances --filters Name=tag:SilenceTime,Values=$1 Name=instance-state-name,Values=stopped --region $2 --output json | jq -r .Reservations[].Instances[].InstanceId`
    do
        `/usr/local/bin/aws ec2 start-instances --instance-ids $server --region $2`
         echo "Server - $server is Started"
    done

    unsetcredentials

}

setcredentials() {

  credentials=`aws sts assume-role --role-arn "arn:aws:iam::$1:role/isg-ansible" --role-session-name "ISGAnsible" --output json`
  export AWS_ACCESS_KEY_ID=$(echo $credentials|jq -r .Credentials.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo $credentials|jq -r .Credentials.SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo $credentials|jq -r .Credentials.SessionToken)

}

unsetcredentials() {

  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

}

echo " $1 -- $2 -- $3 -- $4"

if [ "$3" = "start" ]
then
    startec2 $1 $2 $4
elif [ "$3" = "stop" ]
then
    stopec2 $1 $2 $4
else
    echo "Wrong arguments"
fi


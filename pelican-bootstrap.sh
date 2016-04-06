#!/bin/bash

umask 0022

# Variable Decalration

ENV=$1
APP=$2
LOG_File=/tmp/pelicanInstall.log
JDK_TAR_FILE=jdk-7u76-linux-x64.tar.gz
JDK_FILE=jdk1.7.0_76
JBOSS_TAR_FILE=jboss-as-7.1.3.Final.tar.gz
JBOSS_FILE=jboss-as-7.1.3.Final
ANT_TAR_FILE=apache-ant-1.9.4-bin.tar.gz
ANT_FILE=apache-ant-1.9.4
CERT=Autodesk-CA.cer
ENV_OLD=$ENV
if [ "$ENV" == "QA" ]
then
	ENV="DEV"
fi

case $APP in
	"Platform") 
		cfg=("application.xml" "gateway_env.properties" "psp.handler.config.properties");;
	"TriggersWorkers")
		cfg=("application.xml" "triggers.properties" "aes.key");;
	"Loggers")
		cfg=("application.xml");;
	"Reports")
		cfg=("application.xml" "gateway_env.properties" "psp.handler.config.properties");;
	*)
		exit 1;;
esac

#Adding to /etc/hosts
echo "10.35.74.28 ldap-west.autodesk.com" >> /etc/hosts
#Installing dos2unix
yum -y install dos2unix
#Installing mysql client
yum -y install mysql

#Integrating LDAP Authentication
#/usr/bin/wget --no-check-certificate https://s3-us-west-1.amazonaws.com/adsk-eis-datavirt-nonprd-security/ad-auth/datavirt-nonprd/bootstrap.sh -O /root/bootstrap.sh ; bash /root/bootstrap.sh $ENV
/usr/bin/wget --no-check-certificate https://s3.amazonaws.com/adsk-eis-e2e-security/ad-auth/E2E/bootstrap.sh -O /root/bootstrap.sh ; bash /root/bootstrap.sh $ENV

# Ant installation for db scripts
cd /opt
mkdir -p ant
cd ant
#http://mirror.reverse.net/pub/apache//ant/binaries/apache-ant-1.9.4-bin.tar.gz
#/usr/bin/wget --no-check-certificate http://mirror.reverse.net/pub/apache//ant/binaries/apache-ant-1.9.4-bin.tar.gz
/usr/bin/wget --no-check-certificate https://s3-us-west-1.amazonaws.com/pelican-kickstart/Packages/ant/apache-ant-1.9.4-bin.tar.gz
tar -zxvf ${ANT_TAR_FILE}
ln -s ${ANT_FILE} current
rm -rf ${ANT_TAR_FILE}
cd /opt
chown -R ec2-user:ec2-user ant


# Install Oracle Java JDK 1.7.0_76
cd /opt
mkdir -p java
cd java
#https://s3-us-west-1.amazonaws.com/pelican-kickstart/Packages/java/jdk-7u76-linux-x64.gz
/usr/bin/wget --no-check-certificate https://s3-us-west-1.amazonaws.com/pelican-kickstart/Packages/java/${JDK_TAR_FILE}
tar -zxvf ${JDK_TAR_FILE}
ln -s ${JDK_FILE} current
rm -rf ${JDK_TAR_FILE}
cd /opt
chown -R ec2-user:ec2-user java


#Adding environment variables to ec2-user
echo "export JAVA_HOME=/opt/java/current" >> /home/ec2-user/.bashrc
echo "export ANT_HOME=/opt/ant/current" >> /home/ec2-user/.bashrc
echo "export PATH=\$JAVA_HOME/jre/bin:\$ANT_HOME/bin:\$PATH" >> /home/ec2-user/.bashrc

cd /opt
/usr/bin/wget --no-check-certificate https://s3-us-west-1.amazonaws.com/pelican-kickstart/Packages/java/$CERT
yes | keytool -import -trustcacerts -alias AutodeskCA -file $CERT -keystore /opt/java/current/jre/lib/security/cacerts -storepass changeit

rm -rf $CERT

#Install Jboss
cd /opt
mkdir -p jboss
cd jboss
#http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.tar.gz
/usr/bin/wget --no-check-certificate https://s3-us-west-1.amazonaws.com/pelican-kickstart/Packages/jboss/${JBOSS_TAR_FILE}
tar -zxvf ${JBOSS_TAR_FILE}
ln -s ${JBOSS_FILE} current
rm -rf ${JBOSS_TAR_FILE}
mkdir tmp
cd tmp

for prop in "${cfg[@]}"
do
	if [ "$ENV_OLD" != "QA" ]
	then
		/usr/bin/wget --no-check-certificate https://s3-us-west-1.amazonaws.com/pelican-kickstart/Packages/jboss/Config-$ENV/$APP/$prop
		dos2unix $prop
	else
		/usr/bin/wget --no-check-certificate https://s3-us-west-1.amazonaws.com/pelican-kickstart/Packages/jboss/Config-QA/$APP/$prop
		dos2unix $prop
	fi
done

cp -rf * /opt/jboss/current/standalone/configuration/.
cd ..

rm -rf tmp

cd /opt
chown -R ec2-user:ec2-user jboss

#Setting jboss as run as service
cp /opt/jboss/current/bin/init.d/jboss-as-standalone.sh /etc/init.d/.
chmod +x /etc/init.d/jboss-as-standalone.sh

#Jboss Configuration
mkdir -p /etc/jboss-as
echo "JBOSS_HOME=/opt/jboss/current" >> /etc/jboss-as/jboss-as.conf
echo "JBOSS_CONFIG=\"application.xml -b=0.0.0.0\"" >> /etc/jboss-as/jboss-as.conf
echo "JBOSS_USER=ec2-user" >> /etc/jboss-as/jboss-as.conf
echo "STARTUP_WAIT=60" >> /etc/jboss-as/jboss-as.conf
echo "SHUTDOWN_WAIT=60" >> /etc/jboss-as/jboss-as.conf
echo "JBOSS_CONSOLE_LOG=/var/log/jboss-as/console.log" >> /etc/jboss-as/jboss-as.conf
echo "RUN_CONF=\$JBOSS_HOME/bin/standalone-elements.conf" >> /etc/jboss-as/jboss-as.conf
echo "export RUN_CONF" >> /etc/jboss-as/jboss-as.conf



chkconfig jboss-as-standalone.sh on
/etc/init.d/jboss-as-standalone.sh start

#Add Jenkins Agent
/usr/bin/wget --no-check-certificate https://s3-us-west-1.amazonaws.com/pelican-kickstart/JenkinsAgent.zip
mv JenkinsAgent.zip /home/ec2-user/.
cd /home/ec2-user
unzip JenkinsAgent.zip
chown -R ec2-user:ec2-user JenkinsAgent


exit 0

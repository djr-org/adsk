
# Install Ansible
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get update && sudo apt-get install ansible -y

# Install pyhton pip and python-dev
apt-get install python-pip python-dev build-essential  -y
pip install --upgrade pip 

# Install awscli
pip install awscli

#Install jq
apt-get install jq

#Updates in the Ansible configuration file
sed -i 's/gathering = implicit/gathering = explicit/g' /etc/ansible/ansible.cfg
sed -i 's/#log_path = \/var\/log\/ansible.log/log_path = \/var\/log\/ansible.log/g' /etc/ansible/ansible.cfg

#Updates in the Ansible hosts
sed -i 's/^/#/g' /etc/ansible/hosts
echo "[local]" >> /etc/ansible/hosts
echo "127.0.0.1" >> /etc/ansible/hosts

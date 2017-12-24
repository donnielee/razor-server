#!/bin/sh
#sed -i 's/\:razor_prd/\:\/\/razorserver_razordb_1\/razor_prd/' /etc/razor/config.yaml
sed -i 's/\:razor_prd/\:\/\/postgresql\/razor_prd/' /etc/razor/config.yaml
sed -i 's/user=razor/user=postgres/' /etc/razor/config.yaml
curl -SL http://links.puppetlabs.com/razor-microkernel-latest.tar | tar -xC /var/lib/razor/repo-store/ 
razor-admin -e production migrate-database

source /etc/razor/razor-torquebox.sh
chmod +x /etc/razor/razor-torquebox.sh
/etc/razor/razor-torquebox.sh

#echo "JBOSS_HOME=/opt/razor-torquebox/jruby" >> /root/.bash_profile
#echo "export JBOSS_HOME" >> /root/.bash_profile

#source /root/.bash_profile
mkdir -p /opt/razor-torquebox/jruby/standalone/deployments

cp /var/lib/razor-torquebox/deployments/razor-knob.yml /opt/razor-torquebox/jruby/standalone/deployments/razor-knob.yml

chmod 755 /opt/razor-torquebox/jruby/standalone/deployments/razor-knob.yml
/opt/razor-torquebox/jruby/bin/torquebox deploy /opt/razor --env=production

yum -y install net-tools

nohup /opt/razor-torquebox/jruby/bin/torquebox run --bind-address 0.0.0.0 > /var/log/torquebox.log

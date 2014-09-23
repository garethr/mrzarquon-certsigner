#!/bin/bash

# this script assumes a preloaded AMI with the ec2 utils 
# and puppet already on it. 

export JAVA_HOME=/usr
export EC2_HOME=/usr/local/bin/ec2-api-tools
export EC2_AMITOOL_HOME=/usr/local/bin/ec2-ami-tools

PATH=$PATH:$HOME/bin:$EC2_HOME/bin:$EC2_AMITOOL_HOME/bin
export PATH

MASTER='ip-172-31-22-96.us-west-2.compute.internal'

# adapted from http://stackoverflow.com/a/25721953
# assuming you tag your instances with a tag named 'role' that describes how you want them classified
REGION=$(curl -s http://instance-data/latest/meta-data/placement/availability-zone | sed 's/.$//')
INSTANCE_ID=$(curl -s http://instance-data/latest/meta-data/instance-id)
AMI_ID=$(curl -s http://169.254.169.254/latest/meta-data/ami-id) 
ROLE=$(ec2-describe-tags --region $REGION --filter "resource-id=$INSTANCE_ID,resource-type=instance" | awk '{print $5}')

[ ! -d /etc/puppet ] && mkdir -p /etc/puppet

# using the numeric oid under 1.1.5 until 'role' is formally supported, PUP-3314
cat > /etc/puppet/csr_attributes.yaml <<END
extension_requests:
  pp_instance_id: $INSTANCE_ID
  pp_image_name: $AMI_ID
  1.3.6.1.4.1.34380.1.1.5: $ROLE
custom_attributes:
  pp_preshared_key: BEC02265-DF93-4E8A-B22A-8C24354E9409
END

/usr/bin/puppet config set server $MASTER --section agent
/usr/bin/puppet config set certname $INSTANCE_ID --section agent

/usr/bin/puppet resource service puppet ensure=running enable=true

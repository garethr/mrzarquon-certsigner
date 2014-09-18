This is a first pass at a cloud seeding module.

Adding "certsigner::aws" will install the autosign broker for AWS on your CA.

Edit the /etc/puppetlabs/puppet/autosignfog.yaml file to include your aws credentials and 
region per the documentation: http://docs.puppetlabs.com/pe/latest/cloudprovisioner_configuring.html#configuring

There's a mapping of EC2 regions to their identifiers here: 
http://docs.aws.amazon.com/general/latest/gr/rande.html#ec2_region

See the example el6.aws.bash script for a possible User Data script to used when deploying in cloud formations or through other AWS means.

Originally inspired by jbouse's [https://github.com/jbouse] gist [https://gist.github.com/jbouse/8763661] released under the Apache 2.0 license.

                                                                                     
```                                                                                      
+----------------------------+                                                 
|                            |      Before you start:                          
|  Amazon EC2 API            | <--+ Configure your images with a               
|                            |      user-data script
+----------------------------+                                                 
                                                                                      
                                                                                      
                                                                                      
+--------------------------------------+                                              
                                                                                      
                                                                                      
+----------------------------+                                                 
|                            |                                                 
|  Amazon EC2 API            |                                                 
|                            |                                                 
+------^---------------------+                                                 
       |                                                                       
       |                                                                       
       |                                                                       
+------+------+                                                                
|             |            Your provisioning node requests           
| Provisioner | <-------+  some new instances using that             
|             |            image                                     
+-------------+                                                                
                                                                                      
                                                                                      
+--------------------------------------------+                                        
                                                                                      
                                                                                      
      +---------------------------------+                                             
      |                                 |                                             
      |  Amazon EC2 + using your image  |                                             
      |                                 |    EC2 builds your instances,               
      +----+-----------+-----------+----+    running the user-data script             
           |           |           |         which drops instance-specific            
           |           |           |         metadata into csr_attributes.yaml        
       +---v---+   +---v---+   +---v---+                  +                           
       |       |   |       |   |       |                  |                           
       | node1 |   | node2 |   | node3 | <----------------+                           
       +-------+   +-------+   +-------+                                              
                                                                                      
                                                                                      
+--------------------------------------------+                                        
                                                                                      
       +-------------------------------+                                              
       |                               |    Each node generates a CSR which           
       |        Amazon EC2 API         |    embeds the metadata as requested          
       +---------------------^---------+    attributes and submits it to the          
                             |              puppetmaster, which the embedded          
                             |              instance+ID against EC2 to verify         
       +-------+      +------+---------+    it came from a valid instance.            
       |       |      |                |                                              
       | node1 +------>  puppetmaster  |                                              
       +-------+      +----------------+                                              
                                                                                      
                                                                                      
+---------------------------------------------+                                       
                                                                                      
                                                                                      
       +-------------------------------+                                              
       |                               |    If the API returns OK, the puppetmaster   
       |        Amazon EC2 API         |    signs the certificate request, moving the 
       +---------------------+---------+    instance-id and any other metadata in     
                             |              whitelisted extension requests            
                             |              inside the signed certificate. The        
       +-------+      +------v---------+    signed cert is retrieved by the node      
       |       |      |                |    and normal Puppet runs can begin.         
       | node1 <------+  puppetmaster  |                                              
       +-------+      +----------------+                                              
                                                                                      
                                                                                      
+----------------------------------------------+                                      
                                                                                      
                                                                                      
       +-------+      +----------------+     When the node checks in, the extensions  
       |       |      |                |     will be available under the '$trusted'   
       | node1 +------>  puppetmaster  |     top+scope hash for use in classification,
       +-------+      +----------------+     manifests, etc.                          
                                                                                      
 if $trusted['extensions']['pp_image_name'] =~ /db/ { ...                             

```

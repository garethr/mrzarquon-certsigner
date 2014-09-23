This is a first pass at a cloud seeding module.

Adding "certsigner::aws" will install the autosign broker for AWS on your CA.

Edit the /etc/puppetlabs/puppet/autosignfog.yaml file to include your aws credentials and 
region per the documentation: http://docs.puppetlabs.com/pe/latest/cloudprovisioner_configuring.html#configuring

There's a mapping of EC2 regions to their identifiers here: 
http://docs.aws.amazon.com/general/latest/gr/rande.html#ec2_region

See the example el6.aws.bash script for a possible User Data script to used when deploying in cloud formations or through other AWS means.

Originally inspired by jbouse's [https://github.com/jbouse] gist [https://gist.github.com/jbouse/8763661] released under the Apache 2.0 license.


```
+----------------------------+      Prerequisites:
|                            |      - Puppetmaster w/ fog credentials
|  Amazon EC2 API            | <--+   and autosign policy configured
|                            |      - AMI with user-data install or
+----------------------------+        preloaded agent+ec2-utils, IAM to
                                      query tags
```

Unfortunately there's no way to get tags through the user-data
http interface; you need to go through the API. To avoid putting
credentials on all your launched instances, you can make a little
IAM policy which permits an instance to query tags:

```
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Stmt1411031868000",
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeTags"
          ],
          "Resource": [
            "*"
          ]
        }
      ]
    }
```

I haven't had luck thus far making a corresponding IAM policy on the
master which allows instances with the role=puppetmaster tag able to
query the instance list without credentials, so you still need to load
those up.  This is the `autosignfog.yaml` installed by the module

--------------------------------------

```
+----------------------------+
|                            |
|  Amazon EC2 API            |
|                            |
+------^---------------------+
       |
+------+------+
|             |            Your provisioning node requests
| Provisioner | <-------+  some new instances using that image,
|             |            tagging them w/ role: 'webserver'
+-------------+

```
--------------------------------------------

```
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
```

--------------------------------------------

```
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
```

So there are a couple of layers of protection here:
the PSK check which happens locally, plus the verification
against the API.

---------------------------------------------

```
+-------------------------------+
|                               |  If the API returns OK, the puppetmaster
|        Amazon EC2 API         |  signs the certificate request, moving the
+---------------------+---------+  instance-id and any other metadata in
                      |            whitelisted extension requests
                      |            inside the signed certificate. The
+-------+      +------v---------+  signed cert is retrieved by the node
|       |      |                |  and normal Puppet runs can begin.
| node1 <------+  puppetmaster  |
+-------+      +----------------+
```

You can examine the certificate using the openssl command-line tool
to verify that the extensions made it in:

```
openssl x509 -noout -text -in /var/lib/puppet/ssl/ca/signed/i-f3cef5fe.pem
[ ... tons of crap trimmed ... ]
       X509v3 extensions:
            Netscape Comment:
                Puppet Ruby/OpenSSL Internal Certificate
            1.3.6.1.4.1.34380.1.1.5:
                webserver
            1.3.6.1.4.1.34380.1.1.3:
                ami-37713107
            1.3.6.1.4.1.34380.1.1.2:
                i-f3cef5fe
```

----------------------------------------------


```
+-------+      +----------------+     When the node checks in, the extensions
|       |      |                |     will be available under the '$trusted'
| node1 +------>  puppetmaster  |     top+scope hash for use in classification,
+-------+      +----------------+     manifests, etc.
```

The puppetmaster needs some additional flags turned on
in order to make the trusted data show up correctly;
these will be on by default in Puppet 4 and up but need
toggling currently:

```
    # Stores trusted node data in a hash called $trusted.
    # When true also prevents $trusted from being overridden in any scope.
    trusted_node_data = true

    # When true, also prevents $trusted and $facts from being overridden in any scope
    # The default value is '$trusted_node_data'.
    immutable_node_data = true
```

Then in a manifest, you can use this `$trusted` hash, which has some interesting
properties:

```
node default {
   notify { "trusted_data":
     message => inline_template("<%= scope.lookupvar('trusted').inspect %>")
   }
}
```

Produces the output (pretty-printed the hash):

```
Notice: /Stage[main]/Main/Node[default]/Notify[trusted_data]/message: defined 'message' as '
  {"certname"=>"i-f3cef5fe",
   "authenticated"=>"remote",
   "extensions"=>{
     "pp_instance_id"=>"i-f3cef5fe",
     "pp_image_name"=>"ami-37713107",
     "1.3.6.1.4.1.34380.1.1.5"=>"webserver"
  }
}'
```

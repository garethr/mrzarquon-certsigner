#!/usr/bin/env ruby

# DO NOT USE THIS. It's purely for testing purposes and
# does no verification of the certificate request itself

require 'etc'

ENV['HOME'] = Etc.getpwuid(Process.uid).dir
ENV['FOG_RC'] = '/etc/puppet/autosignfog.yaml'

require 'fog'

instance_id = ARGV.pop

retcode = 0

ec2 = Fog::Compute.new(:provider => :aws)
server = ec2.servers.find { |s| s.id == instance_id }

if not server
  retcode = 2
elsif server.state != 'running'
  retcode = 3
end

exit retcode

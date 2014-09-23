#!/usr/bin/env ruby

require 'etc'

ENV['HOME'] = Etc.getpwuid(Process.uid).dir
ENV['FOG_RC'] = '/etc/puppetlabs/puppet/autosignfog.yaml'

my_psk = 'BEC02265-DF93-4E8A-B22A-8C24354E9409'

require 'fog'
require 'puppet'
require 'puppet/ssl/certificate_request'

clientcert = ARGV.pop

csr = Puppet::SSL::CertificateRequest.from_s(STDIN.read)
pp_instance_id = csr.request_extensions.find { |a| a['oid'] == 'pp_instance_id' }
instance_id = pp_instance_id['value']

retcode = 0

pp_preshared_key = csr.request_extensions.find{ |a| a['oid'] == 'pp_preshared_key' } 

# first some local checks that don't require a hitting the API at all
if pp_preshared_key.nil? or pp_preshared_key != my_psk
  retcode = 4
  exit retcode
elsif csr.name != clientcert
  retcode = 1
end

ec2 = Fog::Compute.new( :provider => :aws)
server = ec2.servers.find { |s| s.id == instance_id }

if not server
  retcode = 2
elsif server.state != 'running'
  retcode = 3
end

exit retcode

#!/usr/bin/env ruby

require 'etc'

ENV['HOME'] = Etc.getpwuid(Process.uid).dir
ENV['FOG_RC'] = '/etc/puppet/autosignfog.yaml'

require 'fog'
require 'puppet'
require 'puppet/ssl/certificate_request'
require 'securerandom'

uuid = SecureRandom.uuid

log = Logger.new("/tmp/#certsigner-{uuid}.log")

clientcert = ARGV.pop

log.info(clientcert)

csr = Puppet::SSL::CertificateRequest.from_s(STDIN.read)
pp_instance_id = csr.request_extensions.find { |a| a['oid'] == 'pp_instance_id' }
instance_id = pp_instance_id['value']

log.info(STDIN.read)
log.info(pp_instance_id)
log.info(instance_id)

retcode = 0

ec2 = Fog::Compute.new( :provider => :aws)
server = ec2.servers.find { |s| s.id == instance_id }

log.info(server.id)

#if csr.name != clientcert
#  retcode = 1
#els

if not server
  retcode = 2
elsif server.state != 'running'
  retcode = 3
end

log.info(retcode)

exit retcode

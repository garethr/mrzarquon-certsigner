class certsigner::awsfacts {
  file { '/etc/facter':
    ensure => directory,
  }
  file { '/etc/facter/facts.d':
    ensure => directory,
  }
  file { '/etc/facter/facts.d/ec2_public.sh':
    ensure => file,
    mode   => '0755',
    owner  => 'puppet',
    group  => 'puppet',
    source => 'puppet:///modules/certsigner/ec2_public.sh',
  }
}

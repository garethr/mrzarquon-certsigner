class certsigner::aws {

  file { '/usr/local/bin/puppet-aws-autosign.rb':
    ensure  => file,
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
    source  => 'puppet:///modules/certsigner/puppet-aws-autosign.rb',
  }

  ini_setting { 'autosign':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'master',
    setting => 'autosign',
    value   => '/usr/local/bin/puppet-aws-autosign.rb',
    require => File['/usr/local/bin/puppet-aws-autosign.rb'],
  }

}

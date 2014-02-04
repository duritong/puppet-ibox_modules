# include puppetlabs repo
class ib_apt::puppetlabs {
  file{
    '/etc/apt/trusted.gpg.d/puppetlabs-keyring.gpg':
      source  => 'puppet:///modules/ib_apt/sources/puppetlabs-keyring.gpg',
      owner   => root,
      group   => 0,
      mode    => '0644',
      notify  => Exec['import_puppetlabs_key'];
  }

  exec{'import_puppetlabs_key':
    command     => 'apt-key add "/etc/apt/trusted.gpg.d/puppetlabs-keyring.gpg"',
    refreshonly => true,
  }

  apt::sources_list{
    'puppetlabs.list':
      content => "
# Puppetlabs products
deb http://apt.puppetlabs.com ${::lsbdistcodename} main
deb-src http://apt.puppetlabs.com ${::lsbdistcodename} main

# Puppetlabs dependencies
deb http://apt.puppetlabs.com ${::lsbdistcodename} dependencies
deb-src http://apt.puppetlabs.com ${::lsbdistcodename} dependencies
",
      require => Exec['import_puppetlabs_key'];
  }
}

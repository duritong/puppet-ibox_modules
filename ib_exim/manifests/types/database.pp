# all the things that are needed to
# access the database for exim
class ib_exim::types::database(
  $config,
) {

  exim::config_snippet {
    'database':
      content => template('ib_exim/snippets/database.erb');
  }

  include ::cdb
  if versioncmp($::operatingsystemmajrelease,'5') > 0 {
    ensure_packages(['rubygem-pg'])
  } else {
    ensure_packages(['ruby-postgres'])
  }

  file{
    '/etc/exim/sql':
      source   => 'puppet:///modules/ib_exim/sql',
      recurse  => true,
      purge    => true,
      force    => true,
      require  =>[ Package['exim'], Package['cdb'] ],
      owner    => mail,
      group    => exim,
      mode     => '0640';
    '/etc/exim/sql/stage':
      ensure   => directory,
      checksum => none,
      owner    => mail,
      group    => exim,
      mode     => '0600';
    '/etc/exim/sql/getFromDB.config.rb':
      content  => template('ib_exim/sql_config/getFromDB.config.rb.erb'),
      require  => File['/etc/exim/sql'],
      owner    => mail,
      group    => 0,
      mode     => '0400';
    [ '/etc/exim/sql/local.cdb',
      '/etc/exim/sql/local.txt',
      '/etc/exim/sql/blocked.cdb',
      '/etc/exim/sql/blocked.txt',
      '/etc/exim/sql/relayto.txt',
      '/etc/exim/sql/relayto.cdb' ]:
      ensure   => file,
      replace  => false,
      require  => File['/etc/exim/sql'],
      owner    => mail,
      group    => mail,
      mode     => '0644';
    '/etc/cron.d/gendomaincdb':
      content  => "*/5 * * * * mail sh /etc/exim/sql/gendomaincdb > /dev/null\n",
      require  => File['/etc/exim/sql/getFromDB.config.rb'],
      owner    => root,
      group    => 0,
      mode     => '0644';
  }

  exec{
    'init_domains_cdb':
      command => 'sh /etc/exim/sql/gendomaincdb',
      creates => '/etc/exim/sql/local.txt',
      user    => 'mail',
      before  => Service['exim'],
      require => File['/etc/cron.d/gendomaincdb'],
  }

  if str2bool($::selinux) and ($::operatingsystemmajrelease != '5') {
    selboolean{
      'exim_can_connect_db':
        value      => 'on',
        persistent => true,
    }
  }
}

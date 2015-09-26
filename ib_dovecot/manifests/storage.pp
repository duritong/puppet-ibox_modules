# a dovecot proxy
class ib_dovecot::storage(
  $sql_config,
) {
  class{
    '::ib_dovecot':
      type               => 'storage',
      nagios_checks      => false,
      config_group       => mail,
      sql_config_content => '# dummy placeholder as I will not talk to any db directly',
  }
  dovecot::confd{
    [ '10-mail',
      '15-lda',
      '90-plugin',
      '90-quota',
      '90-sieve',
    ]:;
  }
  include ::dovecot::sieve
  include ::dovecot::quota

  $hour = fqdn_rand(7)
  $minute = fqdn_rand(59)
  # make the config local
  file{
    '/etc/dovecot/dovecot-expire.conf.ext':
      content => template('ib_dovecot/sql/storage/dovecot-expire.conf.ext.erb'),
      owner   => root,
      group   => 'dovecot',
      mode    => '0640',
      require => Package['dovecot'],
      notify  => Service['dovecot'];
    '/etc/cron.d/dovecot-expire':
      content => "${minute} ${hour} * * * root bash -c \
'for i in Trash Papierkorb spam Spam Junk; \
do doveadm expunge -A mailbox \$i savedbefore 14d; done'\n",
      owner => root,
      group => 0,
      mode  => '0640';
  }

  include ::dovecot_iauth
  file{
    '/usr/libexec/dovecot/checkpassword-bcrypt/checkpassword-bcrypt.conf.rb':
      content => template('ib_dovecot/checkpassword/checkpassword-bcrypt.conf.rb.erb'),
      require => Package['dovecot'],
      before  => Service['dovecot'],
      owner   => root,
      group   => 'dovecot',
      mode    => '0640';
    '/usr/libexec/dovecot/checkpassword-bcrypt/checkpassword-bcrypt.sql.conf.rb':
      source  => 'puppet:///modules/ib_dovecot/checkpassword/checkpassword-bcrypt.sql.conf.rb',
      require => Package['dovecot'],
      before  => Service['dovecot'],
      group   => 'dovecot',
      mode    => '0640';
  }
}

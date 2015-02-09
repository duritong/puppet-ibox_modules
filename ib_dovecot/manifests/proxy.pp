# a dovecot proxy
class ib_dovecot::proxy(
  $sql_config    = {},
  $nagios_checks = {
    'imap-hostname'  => $::fqdn,
    'pop3-hostname'  => $::fqdn,
    'sieve-hostname' => $::fqdn,
  },
){
  $nc = $ibox::use_nagios ? {
    true    => $nagios_checks,
    default => false,
  }

  if $::operatingsystemmajrelease > 6 {
    selinux::policy{
      'ibox-dovecot':
        te_source => 'puppet:///modules/ib_dovecot/selinux/ibox-dovecot.te',
        require   => Package['dovecot'],
        before    => Service['dovecot'];
    }
    file{
      '/etc/systemd/system/dovecot.service.d':
        ensure  => directory,
        require => Package['dovecot'],
        owner   => root,
        group   => 0,
        mode    => '0644';
      '/etc/systemd/system/dovecot.service.d/limits.conf':
        content => "[Service]
LimitNOFILE=3092",
        owner   => root,
        group   => 0,
        mode    => '0644',
        notify  => Service['dovecot'],
    }
  }


  class{'ib_dovecot':
    type          => 'proxy',
    nagios_checks => $nc,
    sql_config    => $sql_config,
  }
}

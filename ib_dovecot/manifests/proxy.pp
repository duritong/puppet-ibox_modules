# a dovecot proxy
class ib_dovecot::proxy(
  $sql_config,
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

  class{'ib_dovecot':
    type               => 'proxy',
    nagios_checks      => $nc,
    sql_config_content => template("ib_dovecot/sql/proxy/sql.conf.${::operatingsystem}.${::operatingsystemmajrelease}.erb")
  }
}

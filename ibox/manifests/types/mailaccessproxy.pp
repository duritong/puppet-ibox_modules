# a dovecot proxy
class ibox::types::mailaccessproxy(
  $sql_config    = hiera('ib_dovecot::proxy::sql_config'),
  $nagios_checks = hiera('ib_dovecot::proxy::nagios_checks', {
    'imap-hostname'  => $::fqdn,
    'pop3-hostname'  => $::fqdn,
    'sieve-hostname' => $::fqdn,
  }),
) {
  class{'::ib_dovecot::proxy':
    sql_config    => $sql_config,
    nagios_checks => $nagios_checks,
  }
}

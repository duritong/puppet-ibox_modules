# manage dovecot
class ib_dovecot(
  $type,
  $nagios_checks  = false,
  $sqlite         = false,
  $sql_config     = {},
  $ssl_cert       = '/etc/pki/dovecot/certs/dovecot.pem',
  $ssl_key        = '/etc/pki/dovecot/private/dovecot.pem',
) {

  # only the proxy needs direct pgsql access
  if $type == 'proxy' {
    $require_sql        = true
    $sql_config_content = template("ib_dovecot/sql/${type}/sql.conf.\
${::operatingsystem}.${::operatingsystemmajrelease}.erb")
  } else {
    $require_sql        = false
    $sql_config_content = false
  }

  if $type == 'storage' {
    $config_group = mail
  } else {
    $config_group = 0
  }

  class{
    'dovecot':
      type               => $type,
      config_group       => $config_group,
      pgsql              => $require_sql,
      sql_config_content => $sql_config_content,
      nagios_checks      => $nagios_checks,
      sqlite             => $sqlite,
      site_source        => 'ib_dovecot',
      munin_checks       => $ibox::use_munin;
      manage_shorewall   => $ibox::use_shorewall;
    'dovecot::managesieve':
      type               => $type,
      legacy_port        => true, # until we migrated
      nagios_checks      => $nagios_checks;
  }

  $ssl_cipher_list = $certs::ssl_config::ciphers
  $ssl_protocols = '!SSLv2 !SSLv3'
  dovecot::confd{
    [ '10-auth',
      '10-master',
      '20-imap',
      '20-pop3',
      '20-managesieve', ]:;
    '10-ssl':
      content => template('ib_dovecot/confd/10-ssl.conf.erb');
    'auth-custom':
      suffix => '.ext';
  }
}

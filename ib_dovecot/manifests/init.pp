# manage dovecot
class ib_dovecot(
  $type,
  $nagios_checks      = false,
  $sql_config_content = false,
  $config_group       = 0,
  $ssl_cert           = '/etc/pki/dovecot/certs/dovecot.pem',
  $ssl_key            = '/etc/pki/dovecot/private/dovecot.pem',
) {

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

  class{
    '::dovecot':
      type               => $type,
      config_group       => $config_group,
      pgsql              => true,
      sql_config_content => $sql_config_content,
      nagios_checks      => $nagios_checks,
      site_source        => 'ib_dovecot',
      munin_checks       => $ibox::use_munin,
      manage_shorewall   => $ibox::use_shorewall;
    '::dovecot::managesieve':
      type               => $type,
      nagios_checks      => $nagios_checks;
  }

  include ::certs::ssl_config
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

# setup exim our way
class ib_exim(
  $component_type,
  $site_source            = hiera('exim::site_source','ib_exim'),
  $pgsql                  = false,
  $greylist               = false,
  $localonly              = false,
  $nagios_checks          = false,
  $daemon_ports           = [ '25' ],
  $relay_from_hosts       = [ '127.0.0.1' ],
  $local_interfaces       = '127.0.0.1',
  $host_lookup            = '*',
  $remote_smtps           = unique(hiera_array('ib_exim::remote_smtps_all',["mail.${::domain}"])),
  $remote_smtp_options    = 'randomize byname',
  $whitelisted_hosts      = [ '127.0.0.2' ],
  $ignore_bl_hosts        = [ '127.0.0.2' ],
  $authenticators_content = '',
  $tls_certificate        = $::operatingsystem ? {
    'Debian' => '/etc/ssl/localcerts/localhost.crt',
    default  => '/etc/pki/tls/certs/localhost.crt',
  },
  $tls_privatekey         = $::operatingsystem ? {
    'Debian' => '/etc/ssl/localcerts/localhost.key',
    default  => '/etc/pki/tls/private/localhost.key',
  },
  $dhparams               = $::operatingsystem ? {
    'Debian' => '/etc/ssl/dhparams.pem',
    default  => '/etc/pki/tls/certs/dhparams.pem',
  },
){
  class{'::ibox::systems::mail':
    use_exim => hiera('ibox::systems::mail::use_exim',true),
  }
  class{'::exim':
    pgsql            => $pgsql,
    ports            => $daemon_ports,
    greylist         => $greylist,
    nagios_checks    => $nagios_checks,
    localonly        => $localonly,
    component_type   => $component_type,
    manage_munin     => $ibox::use_munin,
    manage_shorewall => $ibox::use_shorewall,
    default_mta      => true,
    site_source      => $site_source,
  }
  # use our auto ca
  include ::ib_certs::exim
  File[$tls_certificate] ~> Service['exim']
  File[$tls_privatekey] ~> Service['exim']

  if $::operatingsystem == 'Debian' {
    include ::exim::debian::heavy
    file{'/etc/default/exim4_ibox':
      content => "EXIM_DEBIAN = true\n",
      require => Package['exim'],
      notify  => Service['exim'],
      owner   => root,
      group   => 'Debian-exim',
      mode    => '0640';
    }
  }

  if $pgsql {
    include ::ib_exim::types::database
  }

  certs::dhparams{$dhparams:
    # Some exims do not like the 4096 we have as default
    # TODO: find out why?
    size   => 2048,
    before => Service['exim'],
  }
  $remote_smtps_str      = join(reject($remote_smtps,$::fqdn),':')
  $whitelisted_hosts_str = join($whitelisted_hosts,' : ')
  $ignore_bl_hosts_str   = join($ignore_bl_hosts,' : ')
  $relay_from_hosts_str  = join($relay_from_hosts,' : ')
  exim::config_snippet{
    'host_fields':
      content => "HOST_NAME = ${::fqdn}
LOCAL_INTERFACES = ${local_interfaces}
HOST_LOOKUP = ${host_lookup}
MAIN_DOMAIN = ${::domain}
";
    'smtp_banner_conf':
      content => "smtp_banner = mail.${::domain} mailsystem\n";
    'tls_params':
      content => "tls_certificate = ${tls_certificate}
tls_privatekey = ${tls_privatekey}
tls_dhparam = ${dhparams}\n";
    'remote_smtp':
      content => "REMOTE_SMTP_HOSTS = ${remote_smtps_str}
REMOTE_SMTP_HOST_OPTIONS = ${remote_smtp_options}
";
    'whitelisted_hosts':
      content => "WHITELISTED_HOSTS = ${whitelisted_hosts_str}
IGNORE_BL_HOSTS = ${ignore_bl_hosts_str}
";
    'daemon_ports':
      content => template('ib_exim/snippets/daemon_ports.erb');
    'relay_from_hosts':
      content => "RELAY_FROM_HOSTS = ${relay_from_hosts_str}\n";
    'ssl-ciphers':;
    'authenticators':
      content => $authenticators_content;

    [ 'routers' ,'router_send_to_gateway', 'router_default_local',
      'smtp_params', 'smtp_params_accept_reserve',
      'smtp_params_accept_queue_per_connection', 'domain_lists',
      'acl_require_sender_verify', 'auth_params', 'acl_message_id', ]:;
  }
  if ($::osfamily == 'CentOS') and versioncmp($::operatingsystemmajrelease,'6') > 0 {
    exim::config_snippet{
      'prdr_enable':
        content => "prdr_enable = true\n";
    }
  }

  include ::certs::ssl_config
  # TODO: fix that (newer debian exim are linked against gnutls)
  if ($::osfamily == 'Debian') and versioncmp($::operatingsystemmajrelease,'6') > 0{
    Exim::Config_snippet['ssl-ciphers']{
      content => "tls_require_ciphers = \${if =={\$received_port}{25}{NORMAL:%COMPAT}{SECURE256}}"
    }
  } else {
    Exim::Config_snippet['ssl-ciphers']{
      content => "tls_require_ciphers = \${if =={\$received_port}{25}{${certs::ssl_config::opportunistic_ciphers}}{${certs::ssl_config::ciphers}}}"
    }
  }

  # we do that only for EL6
  if str2bool($::selinux) and versioncmp($::operatingsystemmajrelease,'6') == 0 {
    selinux::policy{
      'ibox-munin-exim':
        te_source => 'puppet:///modules/ib_exim/selinux/ibox-munin-exim/ibox-munin-exim.te',
        require   => Package['exim'],
        before    => Service['munin-node'],
    }
  }
}

# an smtp gateway to and from the public
class ib_exim::relay(
  $nagios_check_host      = "smtp.${::domain}",
  $auth_server            = "imap.${::domain}",
  $dkim_keys_source       = "puppet:///modules/ib_exim/dkim_keys/${::fqdn}",
  $dkim_selector_prefixes = {},
  $dkim_selector          = undef,
) {
  include ::exim_imap_auth

  $authenticators_content = "plain_server:
  driver = plaintext
  public_name = PLAIN
  server_condition = \${perl{imapLogin}{${auth_server}}{\$2}{\$3}}
  server_set_id = \$2
  server_prompts = :
"

  class{'::ib_exim':
    pgsql                  => true,
    greylist               => true,
    daemon_ports           => [ '25', '587', '465' ],
    component_type         => 'relay',
    # 10025 is because of amavis anti-virus/spam scan
    local_interfaces       => '0.0.0.0 : 127.0.0.1.10025',
    nagios_checks          => {
      '25'        => 'tls',
      '465'       => 'ssl',
      '587'       => 'tls',
      'dnsbl'     => true,
      'cert_days' => '10',
      'hostname'  => $nagios_check_host,
    },
    authenticators_content => $authenticators_content,
  }

  $dkim_month = strftime('%Y%m')
  if empty($dkim_selector_prefixes) or
    ($dkim_selector_prefixes[$dkim_month] == undef) {
    $dkim_selector_prefix = 'i'
  } else {
    $dkim_selector_prefix = $dkim_selector_prefixes[$dkim_month]
  }
  if $dkim_selector {
    $real_dkim_selector = $dkim_selector
  } else {
    $real_dkim_selector = "${dkim_selector_prefix}.${dkim_month}"
  }

  exim::config_snippet{
    ['acl_blocked_address_rcpt', 'acl_blocked_address_sender',
      'acl_dns_black_and_whitelists', 'acl_csa_greylisting',
      'acl_set_greylisting', 'acl_do_greylisting',
      'external_methods',]:;
    'dkim_init':
      content => template('ib_exim/snippets/relay/dkim_init.erb');
  }
  include ::ib_exim::types::special_transports

  file{
    '/var/spool/exim/once':
      ensure  => directory,
      before  => File['/etc/exim/exim.conf'],
      require => Package['exim'],
      owner   => exim,
      group   => exim,
      mode    => '0600';
    '/etc/exim/dkim':
      ensure  => directory,
      source  => $dkim_keys_source,
      before  => Service['exim'],
      require => Package['exim'],
      recurse => true,
      force   => true,
      purge   => true,
      owner   => root,
      group   => exim,
      mode    => '0640';
  }

  # antispam
  class{'::spamassassin':
    site_config   => 'ib_spamassassin',
    use_shorewall => $ibox::use_shorewall,
  }

  include ::ib_amavisd_new
  file{'/etc/cron.d/amavis_localhosts':
    content => "1,31 * * * * root  if [ -s /etc/exim/sql/local.txt ]; then cat /etc/exim/sql/local.txt /etc/exim/sql/relayto.txt | awk '{ print \$1 }' > /etc/amavisd/local_domains; fi\n",
    require => Package['amavisd-new'],
    owner   => root,
    group   => 0,
    mode    => '0644';
  }
  exec{
    'init_local_amavis_hosts':
      command => 'cat /etc/exim/sql/local.txt /etc/exim/sql/relayto.txt | awk \'{ print $1 }\' > /etc/amavisd/local_domains',
      creates => '/etc/amavisd/local_domains',
      before  => Service['amavisd'],
      require => [ Package['amavisd-new'], Exec['init_domains_cdb'] ],
  }

  if str2bool($::selinux) and versioncmp($::operatingsystemmajrelease,'5') > 0 {
    selinux::policy{
      'ibox-exim-amavis':
        te_source => 'puppet:///modules/ib_exim/selinux/ibox-exim-amavis/ibox-exim-amavis.te',
        require => Package['amavisd-new','exim','munin-node'],
        before  => Service['exim','munin-node'];
    }
  }
  if str2bool($::selinux) and versioncmp($::operatingsystemmajrelease,'6') == 0 {
    selinux::policy{
      'ibox-munin-amavis':
        te_source => 'puppet:///modules/ib_exim/selinux/ibox-munin-amavis/ibox-munin-amavis.te',
        require => Package['amavisd-new','exim','munin-node'],
        before  => Service['exim','munin-node'];
    }
  }
}

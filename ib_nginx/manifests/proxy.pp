# use nginx as a proxy
class ib_nginx::proxy(
  $acme_token_source = undef,
  $default_cert      = '/etc/pki/tls/certs/localhost.crt',
  $default_key       = '/etc/pki/tls/private/localhost.key',
) {
  include ::ib_nginx
  include ::ib_disks::datavgs::nginx_proxy

  include ::certs::ssl_config
  nginx::confd{
    'proxy_main':
      source => 'puppet:///modules/ib_nginx/conf.d/proxy_main.conf';
    'ssl-ciphers':
      content => "ssl_ciphers ${certs::ssl_config::ciphers_http};
ssl_ecdh_curve ${certs::ssl_config::ecdh_curve};";
    'default_host_sni':
      content => "server {
  include /etc/nginx/include.d/listen_all_443.conf;
  access_log off;
  ssl_certificate     ${default_cert};
  ssl_certificate_key ${default_key};
}";
  }

  file{
    '/var/www':
      ensure => directory,
      owner  => root,
      group  => 0,
      mode   => '0644';
    '/var/www/acme':
      ensure  => directory,
      purge   => true,
      recurse => true,
      source  => $acme_token_source,
      owner   => root,
      group   => 0,
      mode    => '0644';
  } -> file_line{'add_acme_redirect':
    line    => '        location ~ "^/acme/([-a-zA-Z0-9\.]+)/\.well-known/acme-challenge/([-_a-zA-Z0-9]*)$" { default_type text/plain; alias /var/www/acme/$1/$2; }',
    path    => '/etc/nginx/nginx.conf',
    after   => '^\s+server_name\s+_;$',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }


  # First is required when httpd is being used as a forward or reverse proxy.
  # https://docs.fedoraproject.org/en-US/Fedora/13/html/Managing_Confined_Services/sect-Managing_Confined_Services-The_Apache_HTTP_Server-Booleans.html
  # Second is needed for mod_pagespeed that is part of our nginx
  selboolean{
    ['httpd_can_network_relay','httpd_execmem']:
      value       => 'on',
      persistent  => true,
      require     => Package['nginx'],
      before      => Service['nginx'];
  }
  # purge stale caches
  file{'/etc/cron.daily/purge_nginx.sh':
    content => "#!/bin/bash\nfind /var/lib/nginx/ -type f -atime +5 -delete\n",
    require => Service['nginx'],
    owner   => root,
    group   => 0,
    mode    => '0700';
  }

  if versioncmp($::operatingsystemmajrelease,'6') > 0 {
    $http_str = 'http2'
  } else {
    $http_str = 'spdy'
  }

  # we must set an ip here otherwise
  # our forwarded proto settings gets ignored.
  nginx::included{
    'listen_all_443':
      content => "listen ${::ipaddress}:443 ssl ${http_str};\n";
    'listen_all_11372':
      content => "listen ${::ipaddress}:11372 ssl;\n";
  }
}

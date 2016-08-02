# make nginx to listen only
# on the localinterface
class ib_nginx::local_only {
  file_line{'nginx_listen_http_local_only':
    path    => '/etc/nginx/nginx.conf',
    match   => '^\s+listen\s+80',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }
  if versioncmp($::operatingsystemmajrelease,'6') > 0 {
    File_line['nginx_listen_http_local_only']{
      line    => '        listen       127.0.0.1:80 default_server;',
    }
    file_line{'nginx_listen_http_local_only_ipv6':
      path    => '/etc/nginx/nginx.conf',
      line    => '        listen       [::1]:80 default_server;',
      match   => '^\s+listen\s+\[::\]:80 default_server;$',
      require => Package['nginx'],
      notify  => Service['nginx'],
    }
  } else {
    File_line['nginx_listen_http_local_only']{
      line    => '        listen       127.0.0.1:80;',
    }
  }
}

# our basic for haproxy
class ib_haproxy::base(
  $monitor_pwd = trocla("haproxy_monitor_pwd_${::fqdn}",'plain',{charset => 'alphanumeric', length => 32 })
) {
  class{'::haproxy':
    global_options   => {
      'maxconn' => 20000,
      'ca-file' => '/etc/pki/tls/certs/ca-bundle.crt', # verify certs against system CA
      'stats'   => 'socket /var/lib/haproxy/stats mode 600 level admin',
    },
    defaults_options => {
      'mode'     => 'tcp',
      'maxconn'  => 4000,
      'fullconn' => 1500,
      'timeout'  => [
        'connect 5s',
        'queue 1m',
        'check 10s',
        'client 1m',
        'server 1m',
      ],
    },
    merge_options    => true,
  }
  ::haproxy::listen{'monitor':
    bind    => {'127.0.0.1:9300' => []},
    mode    => 'http',
    options => {
      'monitor-uri' => '/status',
      'stats'       => [
        'enable',
        'uri /admin',
        'realm Haproxy\ Statistics',
        "auth root:${monitor_pwd}",
        'refresh 5s',
      ],
    },
  }

  selboolean{
    'haproxy_connect_any':
      value      => on,
      persistent => true,
      before     => Service['haproxy'],
  }
  sysctl::value{'net.ipv4.ip_nonlocal_bind':
    value  => 1,
    before => Service['haproxy'],
  }

  if $ibox::use_munin {
    munin::plugin{
      'haproxy_ng':
        config  => [
          'env.url http://127.0.0.1:9300/admin;csv;norefresh',
          'env.username root',
          "env.password ${monitor_pwd}",
        ],
        require => Service['haproxy'],
    }
  }
}

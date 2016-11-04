module Puppet::Parser::Functions
  newfunction(:gen_onion_haproxy_backend, :type => :rvalue, :doc => <<-EOS
Generates a hash that will configure all necessary resources for a particular onion service.

Our idea is that we are talking to our public services through an HAProxy that is hosted on the onion service. Like that we avoid localhost connections on the particular service itself, while we can also do nice things such as loadbalancing or failover, when we
do maintenance on a particular service without having the need to adjust the onion service.

*Examples:*

    gen_onion_haproxy_backend({
      'smtp' => {
        port => 25,
        frontend_options => ["smtpchk HELO ${hostname}.tor",],
        backends => [
          [smtp-4, '1.1.1.4'],
          [smtp-3,'1.1.1.3'],
        ]
      }
    })

Will return:

  {
    'haproxy::frontend' => {
      'smtp' => {
        'ipaddress'   => '127.0.0.1',
        'ports'       => '1049', # 1024 + port
        'mode'        => 'tcp',
        'options'     => {
          'default_backend' => 'smtp',
          'option' => ["smtpchk HELO ${hostname}.tor"],
        }
      }
    },
    'haproxy::backend' => {
      'smtp' => {
        'collect_exported' => false,
        'options'          => {
          'balance' => 'first',
        }
      }
    }
    'haproxy::balancermember' => {
      'smtp' => {
        'listening_service' => 'smtp',
        'ports'             => '25',
        'server_names'      => ['smtp-4','smtp-3'],
        'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
      },
    }
    'shorewall::rule' => {
      'me-net-haproxy-smtp-smtp-4-tcp' => {
        'source'          => '$FW',
        'destination'     => 'net:1.1.1.4',
        'proto'           => 'tcp',
        'destinationport' => '25',
        'order'           => 240,
        'action'          => 'ACCEPT'
      },
      'me-net-haproxy-smtp-smtp-3-tcp' => {
        'source'          => '$FW',
        'destination'     => 'net:1.1.1.3',
        'proto'           => 'tcp',
        'destinationport' => '25',
        'order'           => 240,
        'action'          => 'ACCEPT'
      }
    }
  EOS
  ) do |args|
    h = args.first
    raise(Puppet::ParseError, "gen_onion_haproxy_backend(): Takes a hash as an argument") unless h.is_a?(Hash)
    raise(Puppet::ParseError, "gen_onion_haproxy_backend(): Requires all values of the hash to be hashes again") unless h.values.all?{|v| v.is_a?(Hash) }
    result = {
      'haproxy::frontend' => {},
      'haproxy::backend' => {},
      'haproxy::balancermember' => {},
      'shorewall::rule' => {},
      'tor::daemon::onion_service' => {},
    }
    default_frontend = {
      'ipaddress' => '127.0.0.1',
      'mode'      => 'tcp',
    }
    default_backend = {
      'collect_exported' => false,
      'options'          => {
        'balance' => 'first',
      }
    }
    default_balancermember = {}
    default_shorewall = {
      'source' => '$FW',
      'proto'  => 'tcp',
      'order'  => 240,
      'action' => 'ACCEPT'
    }
    h.each do |service,values|
      raise(Puppet::ParseError, "gen_onion_haproxy_backend(): Service #{service} requires port and backends as minimal keys") unless ['port','backends'].all?{|e| values.keys.include?(e) }
      raise(Puppet::ParseError, "gen_onion_haproxy_backend(): Service #{service} requires backends to be an array of arrays (#{values['backends'].inspect})") unless values['backends'].is_a?(Array) && values['backends'].all?{|e| e.is_a?(Array) }

      listen_port = (values['listen_port'] || (values['port'].to_i + 1024)).to_s
      result['haproxy::frontend'][service] = default_frontend.merge({
        'ports'   => listen_port,
        'options' => {
          'default_backend' => service,
        }
      })
      if values['frontend_options']
        result['haproxy::frontend'][service]['options']['option'] = Array(values['frontend_options'])
      end
      result['haproxy::backend'][service] = default_backend.merge({})
      result['haproxy::balancermember'][service] = default_balancermember.merge({
        'listening_service' => service,
        'ports'             => values['port'].to_s,
        'server_names'      => values['backends'].collect{|b| b.first },
        'ipaddresses'       => values['backends'].collect{|b| b.last },
      })
      values['backends'].each do |b|
        name,ip = b
        result['shorewall::rule']["me-net-haproxy-#{service}-#{name}-tcp"] = default_shorewall.merge({
          'destination'     => "net:#{ip}/32",
          'destinationport' => values['port'],
        })
      end
      ths = values['onion_service'] || service
      result['tor::daemon::onion_service'][ths] ||= { 'ports' => []}
      result['tor::daemon::onion_service'][ths]['ports'] << "#{values['port']} 127.0.0.1:#{listen_port}"
    end
    result
  end
end

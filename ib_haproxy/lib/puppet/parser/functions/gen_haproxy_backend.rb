module Puppet::Parser::Functions
  newfunction(:gen_haproxy_backend, :type => :rvalue, :doc => <<-EOS
Generates a hash that will configure all necessary resources for a particular service.

*Examples:*

    gen_haproxy_backend({
      'smtp' => {
        frontend_ip      => '5.5.5.5',
        port             => 25,
        backend_options => ["smtpchk HELO haproxy.glei.ch",],
        backends => [
          [smtp-4, '1.1.1.4'],
          [smtp-3, '1.1.1.3'],
        ]
      }
    })

    options:

      * 

Will return:

  {
    'haproxy::frontend' => {
      'smtp' => {
        'ipaddress'   => '5.5.5.5',
        'ports'       => '25',
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
      'net-me-haproxy-smtp-tcp' => {
        'source'          => 'net',
        'destination'     => '$FW:5.5.5.5/32',
        'proto'           => 'tcp',
        'destinationport' => '25',
        'order'           => 240,
        'action'          => 'ACCEPT'
      },
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
    h = args.shift
    shorewall_in = args.shift || 'net'
    shorewall_out = args.shift || 'net'
    raise(Puppet::ParseError, "gen_haproxy_backend(): Takes a hash as an argument") unless h.is_a?(Hash)
    raise(Puppet::ParseError, "gen_haproxy_backend(): Requires all values of the hash to be hashes again") unless h.values.all?{|v| v.is_a?(Hash) }
    result = {
      'haproxy::frontend' => {},
      'haproxy::backend' => {},
      'haproxy::balancermember' => {},
      'shorewall::rule' => {},
    }
    default_frontend = {
      'mode'      => 'tcp',
    }
    default_backend = {
      'collect_exported' => false,
      'options'          => {
        'balance' => 'first',
      }
    }
    default_balancermember = {}
    default_shorewall_in = {
      'proto'  => 'tcp',
      'order'  => 240,
      'action' => 'ACCEPT'
    }
    default_shorewall_out = {
      'source' => '$FW',
      'proto'  => 'tcp',
      'order'  => 240,
      'action' => 'ACCEPT'
    }
    h.each do |service,values|
      raise(Puppet::ParseError, "gen_haproxy_backend(): Service #{service} requires frontend_ip, port and backends as minimal keys") unless ['frontend_ip','port','backends'].all?{|e| values.keys.include?(e) }
      raise(Puppet::ParseError, "gen_haproxy_backend(): Service #{service} requires backends to be an array of arrays (#{values['backends'].inspect})") unless values['backends'].is_a?(Array) && values['backends'].all?{|e| e.is_a?(Array) }
      dsi = default_shorewall_in.merge(
        { 'source' => (values['shorewall_in'] || shorewall_in), }
      )

      result['haproxy::frontend'][service] = default_frontend.merge({
        'ipaddress' => values['frontend_ip'],
        'ports'     => Array(values['port']).collect(&:to_s),
        'options'   => {
          'default_backend' => service,
        }
      })
      if values['frontend_options']
        result['haproxy::frontend'][service]['options']['option'] = Array(values['frontend_options'])
      end
      result['haproxy::backend'][service] = default_backend.merge({})
      if values['backend_options']
        result['haproxy::backend'][service]['options']['option'] = Array(values['backend_options'])
      end
      result['haproxy::balancermember'][service] = default_balancermember.merge({
        'listening_service' => service,
        'ports'             => Array(values['port']).collect(&:to_s),
        'server_names'      => values['backends'].collect{|b| b.first },
        'ipaddresses'       => values['backends'].collect{|b| b.last },
        'option'            => ['check','inter 5s'] | Array(values['server_options']),
      })
      si = dsi['source']
      result['shorewall::rule']["#{si}-me-haproxy-#{service}-tcp"] = dsi.merge({
        'destination'     => Array(values['frontend_ip']).collect{|i| "$FW:#{i}/32" }.join(','),
        'destinationport' => Array(values['port']).join(','),
      })
      so = values['shorewall_out'] || shorewall_out
      values['backends'].each do |b|
        name,ip = b
        result['shorewall::rule']["me-#{so}-haproxy-#{service}-#{name}-tcp"] = default_shorewall_out.merge({
          'destination'     => "#{so}:#{ip}/32",
          'destinationport' => Array(values['port']).join(','),
        })
      end
    end
    result
  end
end

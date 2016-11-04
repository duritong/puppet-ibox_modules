module Puppet::Parser::Functions
  newfunction(:gen_onion_backend, :type => :rvalue, :doc => <<-EOS
Generates a hash that will configure all necessary resources for a particular onion service.

Mainly the idea is to also create outgoing shorewall rules, based on where it needs to go.

*Examples:*

    gen_onion_backend({
      'smtp' => {
        '22' => {}
        '25' => {
          dest => '192.168.1.25',
        },
        '2525' => {
          dest => '192.168.1.26',
          port => '25',
        },
        '2222' => {
          port => '22',
        }
      }
    })

Will return:

  {
    'shorewall::rule' => {
      # for the first no rule is necessary
      'me-net-onion-smtp-2-tcp' => {
        'source'          => '$FW',
        'destination'     => 'net:192.168.1.25',
        'proto'           => 'tcp',
        'destinationport' => '25',
        'order'           => 240,
        'action'          => 'ACCEPT'
      },
      'me-net-onion-smtp-3-tcp' => {
        'source'          => '$FW',
        'destination'     => 'net:192.168.1.26',
        'proto'           => 'tcp',
        'destinationport' => '25',
        'order'           => 240,
        'action'          => 'ACCEPT'
      },
    },
    'tor::daemon::onion_service' => {
       'smtp' => {
         'ports' => [
           '22',
           '25 192.168.1.25:25',
           '2525 192.168.1.26:25',
           '2222 127.0.0.1:22',
         ]
       }
    },
  }
  EOS
  ) do |args|
    h = args.first
    raise(Puppet::ParseError, "gen_onion_backend(): Takes a hash as an argument") unless h.is_a?(Hash)
    raise(Puppet::ParseError, "gen_onion_backend(): Requires all values of the hash to be hashes again") unless h.values.all?{|v| v.is_a?(Hash) }
    raise(Puppet::ParseError, "gen_onion_backend(): Requires all values of the hash of the values to be hashes again") unless h.values.all?{|v| v.values.all?{|vv| vv.is_a?(Hash) } }
    result = {
      'shorewall::rule' => {},
      'tor::daemon::onion_service' => {},
    }
    default_shorewall = {
      'source' => '$FW',
      'proto'  => 'tcp',
      'order'  => 240,
      'action' => 'ACCEPT'
    }
    h.each do |service,values|
      result['tor::daemon::onion_service'][service] ||= { 'ports' => []}
      values.keys.sort.each_with_index do |port,index|
        v = values[port]
        p = v['port'] || port
        if v['dest'] && (v['dest'] != '127.0.0.1')
          result['shorewall::rule']["me-net-onion-#{service}-#{index}-tcp"] = default_shorewall.merge({
            'destination'     => "net:#{v['dest']}/32",
            'destinationport' => p,
          })
          fp = "#{port} #{v['dest']}:#{p}"
        else
          fp = (p != port) ? "#{port} 127.0.0.1:#{p}" : p
        end
        result['tor::daemon::onion_service'][service]['ports'] << fp
      end
    end
    result
  end
end

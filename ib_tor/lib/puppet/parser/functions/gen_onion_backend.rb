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
          nagios => 'smtp',
        },
        '2525' => {
          dest        => '192.168.1.26',
          port        => '25',
          nagios      => 'smtp_port',
          nagios_args => '2525',
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
    'nagios::service' => {
      'os_smtp_25' => {
        check_command => 'check_smtp_tor',
      },
      'os_smtp_2525' => {
        check_command => 'check_smtp_port_tor!2525',
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
    h = args[0]
    private_key_path = args[1]
    raise(Puppet::ParseError, "gen_onion_backend(): Takes a hash as an argument") unless h.is_a?(Hash)
    raise(Puppet::ParseError, "gen_onion_backend(): Requires all values of the hash to be hashes again") unless h.values.all?{|v| v.is_a?(Hash) }
    raise(Puppet::ParseError, "gen_onion_backend(): Requires all values of the hash of the values to be hashes again") unless h.values.all?{|v| v.values.all?{|vv| vv.is_a?(Hash) } }
    raise(Puppet::ParseError, "gen_onion_backend(): Requires 2 argument to be a directory if passed") if private_key_path && !File.directory?(private_key_path)
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
        if v['nagios']
          raise(Puppet::ParseError, "gen_onion_backend(): Requires a second argument to lookup the key if generating nagios checks") unless private_key_path

          oa, key = function_generate_onion_key([private_key_path,service])
          oah = "#{oa}.onion"
          check_cmd = "check_#{v['nagios']}_tor#{v['nagios_args'] ? "!#{Array(v['nagios_args']).join('!')}" : ''}"
          # we must define a check command for a host, so we use the first service check for it
          if result['@@nagios_host'].nil?
            result['@@nagios_host'] = {
              oah => {
                'parents'       => lookupvar('fqdn'),
                'address'       => oah,
                'use'           => 'generic-host',
                'alias'         => "Onion service #{service}",
                'check_command' => check_cmd,
              }
            }
          else
            result['nagios::service'] ||= {}
            result['nagios::service']["os_#{service}_#{port}"] = {
              'host_name'     => oah,
              'check_command' => check_cmd,
            }
          end
        end
        result['tor::daemon::onion_service'][service]['ports'] << fp
      end
    end
    result
  end
end

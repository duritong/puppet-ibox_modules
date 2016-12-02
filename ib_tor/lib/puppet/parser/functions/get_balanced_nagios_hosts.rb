module Puppet::Parser::Functions
  newfunction(:get_balanced_nagios_hosts, :type => :rvalue, :doc => <<-EOS
Generates a hash that will contain nagios_host resources to be balanced.

Argmuents are a path where the different onion services are stored, as well as a
hash, consisting of all the services and there nagios checks to be done.
By default it will use https check.

*Examples:*

    get_balanced_nagios_hosts('/tmp', {
      'smtp'       => { 'nagios'  => 'smtp' },
      'plain_web'  => { 'nagios' => 'http' },
      'web2'       => {},
    })

Will return:

  {
    'onionaddress_for_balanced_smtp' => {
      'address'       => 'onionaddress_for_balanced_smtp',
      'alias'         => 'Balanced onion service smtp',
      'check_command' => 'check_smtp_tor',
      'host_name'     => 'onionaddress_for_balanced_smtp',
      'parents'       => 'name_of_first_smtp_os,name_of_second_smtp_os',
      'use'           => 'generic-host',
    },
    'onionaddress_for_balanced_plain_web' => {
      'address'       => 'onionaddress_for_balanced_plain_web',
      'alias'         => 'Balanced onion service plain_web',
      'check_command' => 'check_http_tor',
      'host_name'     => 'onionaddress_for_balanced_plain_web',
      'parents'       => 'name_of_first_plain_web_os,name_of_second_plain_web_os',
      'use'           => 'generic-host',
    },
    'onionaddress_for_balanced_web2' => {
      'address'       => 'onionaddress_for_balanced_web2',
      'alias'         => 'Balanced onion service web2',
      'check_command' => 'check_https_tor',
      'host_name'     => 'onionaddress_for_balanced_web2',
      'parents'       => 'name_of_first_web2_os,name_of_second_web2_os',
      'use'           => 'generic-host',
    },
  }
  EOS
  ) do |args|
    path, ids = args
    raise(Puppet::ParseError, "get_balanced_nagios_hosts(): Takes a path and a hash of balanced onion services ") unless path && ids.is_a?(Hash)
    raise(Puppet::ParseError, "get_balanced_nagios_hosts(): Path #{path} must be a directory") unless File.directory?(path)
    result = {}
    balanced_services = function_get_services_to_balance([path,ids.keys.sort])
    balanced_services.keys.sort.each do |bos|
      sbos = "#{bos}.onion"
      id = ids.keys.find{|i| balanced_services[bos].keys.reject{|k| k == '_key_content' }.first =~ /^#{i}_/ }
      result[sbos] = {
        'address'       => sbos,
        'alias'         => "Balanced onion service #{id}",
        'check_command' => "check_#{ids[id]['nagios'] || 'https' }_tor",
        'host_name'     => sbos,
        'parents'       => balanced_services[bos].keys.sort.reject{|k| k == '_key_content' }.collect{|k| "#{balanced_services[bos][k]}.onion" }.join(','),
        'use'           => 'generic-host',
      }
    end
    result
  end
end

module Puppet::Parser::Functions
  newfunction(:get_services_to_balance, :type => :rvalue, :doc => <<-EOS
Generates a hash that will configure all necessary resources for a particular onion service.

Mainly the idea is to also create outgoing shorewall rules, based on where it needs to go.

*Examples:*

    get_services_to_balance('/tmp', ['smtp','web'])

Will return:

  {
    'onionaddress_for_balanced_smtp' => {
      'smtp_1'       => 'key_of_first_smtp_os',
      'smtp_2'       => 'key_of_second_smtp_os',
      '_key_content' => 'key_for_balanced_smtp',
    },
    'onionaddress_for_balanced_web' => {
      'web_1         => 'key_of_first_web_os',
      'web_2'        => 'key_of_second_web_os',
      '_key_content' => 'key_for_balanced_web',
    },
  }

This comes together by scanning the folder of the first argument for all files
matching /tmp/smtp_*.key and /tmp/web_*.key and then return a hash representing
balanced services configurations.
  EOS
  ) do |args|
    path, ids = args
    raise(Puppet::ParseError, "get_services_to_balance(): Takes a path and an array of identifiers ") unless path && ids.is_a?(Array)
    raise(Puppet::ParseError, "get_services_to_balance(): Path #{path} must be a directory") unless File.directory?(path)
    result = {}
    ids.each do |id|
      key_files = Dir["#{path}/#{id}_*.key"]
      unless key_files.empty?
        oa, key = function_generate_onion_key([path,id])
        result[oa] = {
          '_key_content' => key
        }
        key_files.each do |kf|
          kid = File.basename(kf,'.key')
          koa, _ = function_generate_onion_key([path,kid])
          result[oa][kid] = koa
        end
      end
    end
    result
  end
end

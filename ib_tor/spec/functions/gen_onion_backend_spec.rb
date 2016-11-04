require 'spec_helper'

describe 'gen_onion_backend' do
  describe 'signature validation' do
    it { is_expected.not_to eq(nil) }
    it { is_expected.to run.with_params().and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params([]).and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params('').and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params({ 1 => 2 }).and_raise_error(Puppet::ParseError, /Requires all values of the/) }
  end

  describe 'normal operation' do
    it { is_expected.to run.with_params({
      'smtp' => {
        '22' => {},
        '25' => {
          'dest' => '192.168.1.25',
        },
        '2525' => {
          'dest' => '192.168.1.26',
          'port' => '25',
        },
        '2222' => {
          'port' => '22',
        }
      }
    }).and_return(
  {
    'shorewall::rule' => {
      # for the first no rule is necessary
      'me-net-onion-smtp-2-tcp' => {
        'source'          => '$FW',
        'proto'           => 'tcp',
        'order'           => 240,
        'action'          => 'ACCEPT',
        'destination'     => 'net:192.168.1.25/32',
        'destinationport' => '25',
      },
      'me-net-onion-smtp-3-tcp' => {
        'source'          => '$FW',
        'proto'           => 'tcp',
        'order'           => 240,
        'action'          => 'ACCEPT',
        'destination'     => 'net:192.168.1.26/32',
        'destinationport' => '25',
      },
    },
    'tor::daemon::onion_service' => {
       'smtp' => {
         'ports' => [
           '22',
           '2222 127.0.0.1:22',
           '25 192.168.1.25:25',
           '2525 192.168.1.26:25',
         ]
       }
    },
    })}
  end
end

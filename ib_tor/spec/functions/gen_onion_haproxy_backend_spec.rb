require 'spec_helper'

describe 'gen_onion_haproxy_backend' do
  describe 'signature validation' do
    it { is_expected.not_to eq(nil) }
    it { is_expected.to run.with_params().and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params([]).and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params('').and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params({ 1 => 2 }).and_raise_error(Puppet::ParseError, /Requires all values of the/) }
    it { is_expected.to run.with_params({ 'smtp' => { 'port' => '25' }}).and_raise_error(Puppet::ParseError, /requires port and backends/) }
    it { is_expected.to run.with_params({ 'smtp' => { 'port' => '25', 'backends' => 'backend1' }}).and_raise_error(Puppet::ParseError, /requires backends to be an array of arrays/) }
  end

  describe 'normal operation' do
    it { is_expected.to run.with_params({ 'smtp' => { 'port' => 25, 'backends' => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']]}}).and_return(
      {
        'haproxy::frontend' => {
          'smtp' => {
            'ipaddress'   => '127.0.0.1',
            'ports'       => '1049', # 1024 + port
            'mode'        => 'tcp',
            'options'     => {
              'default_backend' => 'smtp',
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
        },
        'haproxy::balancermember' => {
          'smtp' => {
            'listening_service' => 'smtp',
            'ports'             => '25',
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
          },
        },
        'shorewall::rule' => {
          'me-net-haproxy-smtp-smtp-4-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => 25,
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => 25,
            'order'           => 240,
            'action'          => 'ACCEPT'
          }
        },
        'tor::daemon::onion_service' => {
          'smtp' => {
            'ports' => ['25 127.0.0.1:1049'],
          }
        }
      }
    )}
  end
  describe 'normal with two' do
    it { is_expected.to run.with_params({
      'smtp_submit' => { 'port' => 587, 'backends' => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']]},
      'smtp'        => { 'port' => 25, 'backends' => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']]}}
    ).and_return(
      {
        'haproxy::frontend' => {
          'smtp' => {
            'ipaddress'   => '127.0.0.1',
            'ports'       => '1049', # 1024 + port
            'mode'        => 'tcp',
            'options'     => {
              'default_backend' => 'smtp',
            }
          },
          'smtp_submit' => {
            'ipaddress'   => '127.0.0.1',
            'ports'       => '1611',
            'mode'        => 'tcp',
            'options'     => {
              'default_backend' => 'smtp_submit',
            }
          }
        },
        'haproxy::backend' => {
          'smtp' => {
            'collect_exported' => false,
            'options'          => {
              'balance' => 'first',
            }
          },
          'smtp_submit' => {
            'collect_exported' => false,
            'options'          => {
              'balance' => 'first',
            }
          }
        },
        'haproxy::balancermember' => {
          'smtp' => {
            'listening_service' => 'smtp',
            'ports'             => '25',
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
          },
          'smtp_submit' => {
            'listening_service' => 'smtp_submit',
            'ports'             => '587',
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
          },
        },
        'shorewall::rule' => {
          'me-net-haproxy-smtp-smtp-4-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => 25,
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => 25,
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp_submit-smtp-4-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => 587,
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp_submit-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => 587,
            'order'           => 240,
            'action'          => 'ACCEPT'
          }
        },
        'tor::daemon::onion_service' => {
          'smtp' => {
            'ports' => ['25 127.0.0.1:1049'],
          },
          'smtp_submit' => {
            'ports' => ['587 127.0.0.1:1611'],
          }
        }
      }
  )}
  end
  describe 'with frontend_option and listen_port param' do
    it { is_expected.to run.with_params({
      'smtp' => {
        'port'             => 25,
        'backends'         => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']],
        'frontend_options' => 'smtpchk HELO foo.tor',
        'listen_port'      => 2525,
        'onion_service'   => 'some_service',
      }
    }).and_return(
      {
        'haproxy::frontend' => {
          'smtp' => {
            'ipaddress'   => '127.0.0.1',
            'ports'       => '2525',
            'mode'        => 'tcp',
            'options'     => {
              'default_backend' => 'smtp',
              'option'          => ['smtpchk HELO foo.tor']
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
        },
        'haproxy::balancermember' => {
          'smtp' => {
            'listening_service' => 'smtp',
            'ports'             => '25',
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
          },
        },
        'shorewall::rule' => {
          'me-net-haproxy-smtp-smtp-4-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => 25,
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => 25,
            'order'           => 240,
            'action'          => 'ACCEPT'
          }
        },
        'tor::daemon::onion_service' => {
          'some_service' => {
            'ports' => ['25 127.0.0.1:2525'],
          }
        }
      }
  )}
  end

end

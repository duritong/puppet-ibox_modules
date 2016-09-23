require 'spec_helper'

describe 'gen_haproxy_backend' do
  describe 'signature validation' do
    it { is_expected.not_to eq(nil) }
    it { is_expected.to run.with_params().and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params([]).and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params('').and_raise_error(Puppet::ParseError, /Takes a hash as an argument/) }
    it { is_expected.to run.with_params({ 1 => 2 }).and_raise_error(Puppet::ParseError, /Requires all values of the/) }
    it { is_expected.to run.with_params({ 'smtp' => { 'port' => '25' }}).and_raise_error(Puppet::ParseError, /requires frontend_ip, port and backends/) }
    it { is_expected.to run.with_params({ 'smtp' => { 'port' => 25, 'backends' => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']]}}).and_raise_error(Puppet::ParseError, /requires frontend_ip, port and backends/)}
    it { is_expected.to run.with_params({ 'smtp' => { 'port' => '25', 'frontend_ip' => '5.5.5.5','backends' => 'backend1' }}).and_raise_error(Puppet::ParseError, /requires backends to be an array of arrays/) }
  end

  describe 'normal operation' do
    it { is_expected.to run.with_params({ 'smtp' => { 'port' => 25, 'frontend_ip' => '5.5.5.5', 'backends' => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']]}}).and_return(
      {
        'haproxy::frontend' => {
          'smtp' => {
            'ipaddress'   => '5.5.5.5',
            'ports'       => ['25'],
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
            'ports'             => ['25'],
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
            'option'            => ['check','inter 5s']
          },
        },
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
            'destination'     => 'net:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          }
        },
      }
    )}
  end
  describe 'normal with two' do
    it { is_expected.to run.with_params({
      'smtp_submit' => { 'frontend_ip' => '5.5.5.5', 'port' => 587, 'backends' => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']]},
      'smtp'        => { 'frontend_ip' => '5.5.5.5', 'port' => 25, 'backends' => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']]}}
    ).and_return(
      {
        'haproxy::frontend' => {
          'smtp' => {
            'ipaddress'   => '5.5.5.5',
            'ports'       => ['25'],
            'mode'        => 'tcp',
            'options'     => {
              'default_backend' => 'smtp',
            }
          },
          'smtp_submit' => {
            'ipaddress'   => '5.5.5.5',
            'ports'       => ['587'],
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
            'ports'             => ['25'],
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
            'option'            => ['check','inter 5s']
          },
          'smtp_submit' => {
            'listening_service' => 'smtp_submit',
            'ports'             => ['587'],
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
            'option'            => ['check','inter 5s']
          },
        },
        'shorewall::rule' => {
          'net-me-haproxy-smtp-tcp' => {
            'source'          => 'net',
            'destination'     => '$FW:5.5.5.5/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'net-me-haproxy-smtp_submit-tcp' => {
            'source'          => 'net',
            'destination'     => '$FW:5.5.5.5/32',
            'proto'           => 'tcp',
            'destinationport' => '587',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp-smtp-4-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp_submit-smtp-4-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => '587',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-net-haproxy-smtp_submit-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'net:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => '587',
            'order'           => 240,
            'action'          => 'ACCEPT'
          }
        },
      }
  )}
  end
  describe 'with frontend_option and listen_port param' do
    it { is_expected.to run.with_params({
      'smtp' => {
        'frontend_ip'      => ['5.5.5.5','5.5.5.6'],
        'port'             => 25,
        'backends'         => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']],
        'backend_options'  => 'smtpchk HELO foo.glei.ch',
        'hidden_service'   => 'some_service',
        'shorewall_in'     => 'ext',
        'shorewall_out'    => 'loc',
      }
    }).and_return(
      {
        'haproxy::frontend' => {
          'smtp' => {
            'ipaddress'   => ['5.5.5.5','5.5.5.6'],
            'ports'       => ['25'],
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
              'option'  => ['smtpchk HELO foo.glei.ch']
            }
          }
        },
        'haproxy::balancermember' => {
          'smtp' => {
            'listening_service' => 'smtp',
            'ports'             => ['25'],
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
            'option'            => ['check','inter 5s']
          },
        },
        'shorewall::rule' => {
          'ext-me-haproxy-smtp-tcp' => {
            'source'          => 'ext',
            'destination'     => '$FW:5.5.5.5/32,$FW:5.5.5.6/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-loc-haproxy-smtp-smtp-4-tcp' => {
            'source'          => '$FW',
            'destination'     => 'loc:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-loc-haproxy-smtp-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'loc:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          }
        },
      }
  )}
  end
  describe 'with frontend_option and listen_port param and global shorewall params' do
    it { is_expected.to run.with_params({
      'smtp' => {
        'frontend_ip'      => ['5.5.5.5','5.5.5.6'],
        'port'             => 25,
        'backends'         => [['smtp-4','1.1.1.4'],['smtp-3','1.1.1.3']],
        'backend_options'  => 'smtpchk HELO foo.glei.ch',
        'server_options'   => 'check-ssl',
        'hidden_service'   => 'some_service',
      }
    },
    'ext',
    'loc'
    ).and_return(
      {
        'haproxy::frontend' => {
          'smtp' => {
            'ipaddress'   => ['5.5.5.5','5.5.5.6'],
            'ports'       => ['25'],
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
              'option'  => ['smtpchk HELO foo.glei.ch']
            }
          }
        },
        'haproxy::balancermember' => {
          'smtp' => {
            'listening_service' => 'smtp',
            'ports'             => ['25'],
            'server_names'      => ['smtp-4','smtp-3'],
            'ipaddresses'       => ['1.1.1.4','1.1.1.3'],
            'option'            => ['check','inter 5s','check-ssl']
          },
        },
        'shorewall::rule' => {
          'ext-me-haproxy-smtp-tcp' => {
            'source'          => 'ext',
            'destination'     => '$FW:5.5.5.5/32,$FW:5.5.5.6/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-loc-haproxy-smtp-smtp-4-tcp' => {
            'source'          => '$FW',
            'destination'     => 'loc:1.1.1.4/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          },
          'me-loc-haproxy-smtp-smtp-3-tcp' => {
            'source'          => '$FW',
            'destination'     => 'loc:1.1.1.3/32',
            'proto'           => 'tcp',
            'destinationport' => '25',
            'order'           => 240,
            'action'          => 'ACCEPT'
          }
        },
      }
  )}
  end

end

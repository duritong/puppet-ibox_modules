# configure a tor for onion services
class ib_tor::onion(
  $services             = {
    $hostname => {
      '22' => {},
    }
  },
  $balanced_services    = {},
  $os_private_keys_path = undef,
){
  include ::tor::repo
  class{'::tor::daemon':
    use_munin => $ibox::use_munin,
  }
  if $ibox::use_shorewall {
    include ::shorewall::rules::out::tor
  }

  if $::operatingsystem == 'CentOS' {
    include ib_tor::centos
  }

  # custom local
  $gen_full_service = gen_onion_backend($services)
  if !empty($services) {
    create_resources('tor::daemon::onion_service',$gen_full_service['tor::daemon::onion_service'],{private_key_store_path => $os_private_keys_path })
    if $ibox::use_shorewall {
      create_resources('shorewall::rule',$gen_full_service['shorewall::rule'])
    }
  }
}

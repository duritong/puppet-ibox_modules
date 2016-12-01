# configure a tor for onion services
class ib_tor::onion(
  $services             = {
    "${hostname}" => {
      '22' => {},
    }
  },
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
  $gen_full_service = gen_onion_backend($services,$os_private_keys_path)
  if !empty($services) {
    create_resources('tor::daemon::onion_service',$gen_full_service['tor::daemon::onion_service'],{private_key_store_path => $os_private_keys_path })
    if $ibox::use_shorewall {
      create_resources('shorewall::rule',$gen_full_service['shorewall::rule'])
    }
    if $ibox::use_nagios and !empty($gen_full_service['nagios::service']) {
      create_resources('@@nagios_host',$gen_full_service['@@nagios_host'])
      create_resources('nagios::service',$gen_full_service['nagios::service'])
    }
  }
}

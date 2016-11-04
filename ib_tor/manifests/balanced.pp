# easily create balanced
# services
class ib_tor::balanced(
  $services               = {},
  $private_key_store_path = undef,
){
  if !empty($services) {
    if $::operatingsystem == 'CentOS' {
      include ib_tor::centos
    }
    if $private_key_store_path {
      $real_services = get_services_to_balance($private_key_store_path,$services)
    } else {
      $real_services = $real_services
    }
    class{'tor::onionbalance':
      services => $real_services,
    }
  }
}

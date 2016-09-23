# a simple haproxy
class ib_haproxy::simple(
  $services      = {},
  $shorewall_in  = 'net',
  $shorewall_out = 'net',
){
  include ::ib_haproxy::base

  if !empty($services) {
    $gen_services = gen_haproxy_backend($services,$shorewall_in, $shorewall_out)
    create_resources('haproxy::frontend',$gen_services['haproxy::frontend'])
    create_resources('haproxy::backend',$gen_services['haproxy::backend'])
    create_resources('haproxy::balancermember',$gen_services['haproxy::balancermember'])
    create_resources('shorewall::rule',$gen_services['shorewall::rule'])
  }
}

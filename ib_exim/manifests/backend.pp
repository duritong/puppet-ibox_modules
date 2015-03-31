# an exim backend
class ib_exim::backend(
  $local_interfaces,
  $component_type
) {
  class{'ib_exim':
    pgsql             => true,
    nagios_checks     => false,
    component_type    => $component_type,
    local_interfaces  => $local_interfaces
  }
}

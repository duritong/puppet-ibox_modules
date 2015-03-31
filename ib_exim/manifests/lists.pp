# a setup for lists
class ib_exim::lists {
  class{'ib_exim::backend':
    component_type   => 'lists',
    local_interfaces => '0.0.0.0',
  }
  include ::ib_exim::types::special_transports

  exim::config_snippet{
    [ 'trusted_options','acl_defer_lists' ]:
  }
}

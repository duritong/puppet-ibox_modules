# webproxy to front webhostings
class ibox::types::webproxy {
  include ::ib_varnish
  include ::ib_nginx::proxy
  include ::ib_nginx::local_only
}

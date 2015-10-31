# a dns server
# provides a forward & recursive resolver
# on 2 different ips
class ibox::types::dns {
  if versioncmp($::operatingsystemmajrelease,'7') < 0 {
    include ::ib_nsd
  } else {
    include ::ib_bind
  }
  include ::ib_unbound
}

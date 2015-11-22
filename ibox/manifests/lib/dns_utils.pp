# some dns helpers
class ibox::lib::dns_utils {
  case $::operatingsystem {
    'Debian': {
      ensure_packages(['bind9utils'])
    }
    default: {
      ensure_packages(['bind-utils'])
    }
  }

}

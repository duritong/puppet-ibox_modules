# unbound for local resolv only
class ib_unbound::local_only {
  class{'unbound':
    manage_shorewall => false,
    manage_munin     => true,
    before           => File['/etc/resolv.conf'],
  }
}

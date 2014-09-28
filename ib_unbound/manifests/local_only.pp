# unbound for local resolv only
class ib_unbound::local_only {
  class{'unbound':
    interface        => hiera('unbound::interface','127.0.0.1'),
    manage_shorewall => false,
    manage_munin     => true,
    before           => File['/etc/resolv.conf'],
  }
}

# Setups the filesystem for a varnish
class ib_disks::datavgs::varnish(
  $size_cache   = '3G',
) {
  disks::lv_mount{
    'varnish_cachelv':
      folder        => '/var/lib/varnish',
      size          => $size_cache,
      before        => Package['varnish'];
  }
}


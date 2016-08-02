# Setups the filesystem for a nginx_proxy
# we put the cache in /var/lib/nginx
class ib_disks::datavgs::nginx_proxy(
  $size_cache = '5G',
) {
  disks::lv_mount{
    'nginx_cachelv':
      folder        => '/var/lib/nginx',
      size          => $size_cache,
      before        => Package['nginx'];
  }
}


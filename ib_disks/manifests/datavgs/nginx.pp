# Setups the filesystem for logs for nginx
class ib_disks::datavgs::nginx(
  $size_log = '1G',
) {
  disks::lv_mount{
    'nginx_loglv':
      folder        => '/var/log/nginx',
      size          => $size_log,
      before        => Package['nginx'];
  }
}


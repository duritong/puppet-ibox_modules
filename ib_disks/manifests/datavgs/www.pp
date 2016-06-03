# Setups the filesystem for a webhost
class ib_disks::datavgs::www(
  $size_data   = '5G',
  $size_log    = false,
) {

  disks::lv_mount{
    'www_datalv':
      folder  => '/var/www',
      owner   => root,
      group   => 0,
      mode    => '0755',
      size    => $size_data,
  }
  # make this as early as possible
  Disks::Lv_mount['www_datalv'] -> Package<| title == 'apache' |>
  if $size_log {
    disks::lv_mount{
      'www_loglv':
        folder  => '/var/log/httpd',
        owner   => root,
        group   => 0,
        mode    => '0700',
        size    => $size_log,
    }
    Disks::Lv_mount['www_loglv'] -> Package<| title == 'apache' |>
  }
}


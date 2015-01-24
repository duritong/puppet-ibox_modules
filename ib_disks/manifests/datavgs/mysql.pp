# Setups the filesystem for a mysql
class ib_disks::datavgs::mysql(
  $size_data   = '5G',
  $size_backup = '1G',
) {

  disks::lv_mount{
    'mysql_datalv':
      folder        => '/var/lib/mysql',
      size          => $size_data,
      before        => Package['mysql-server'];
    'mysql_backuplv':
      folder        => '/var/lib/mysql/backups',
      owner         => root,
      group         => 0,
      mode          => '0700',
      size          => $size_backup,
      require       => Disks::Lv_mount['mysql_datalv'];
  }
}

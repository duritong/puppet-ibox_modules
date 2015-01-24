# Setups the filesystem for a postgres
class ib_disks::datavgs::postgres(
  $size_data   = '3G',
  $size_backup = '100M',
) {

  disks::lv_mount{
    'pgsql_datalv':
      folder   => '/var/lib/pgsql',
      size     => $size_data;
    'pgsql_backuplv':
      folder   => '/var/lib/pgsql/backups',
      size     => $size_backup,
      require  => Disks::Lv_mount['pgsql_datalv'],
      before   => Package['postgresql-server'];
  }
}

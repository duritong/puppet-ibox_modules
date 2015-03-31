# Setups the filesystem for a mysql
class ib_disks::datavgs::mailstorage(
  $size_data   = '5G',
) {

  disks::lv_mount{
    'mail_datalv':
      folder        => '/var/mail',
      size          => $size_data,
      owner         => root,
      group         => mail,
      mode          => '0775',
      fs_type       => 'xfs',
      mount_options => 'noatime,nodiratime,logbufs=8',
      before        => Package['dovecot'];
  }
}

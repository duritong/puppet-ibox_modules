# Setups the filesystem for a mysql
class ib_disks::datavgs::mailstorage(
  $size_data   = '90%FREE',
) {

  disks::lv_mount{
    'mail_datalv':
      folder        => '/var/spool/mail',
      size          => $size_data,
      owner         => root,
      group         => mail,
      mode          => '0775',
      fs_type       => 'xfs',
      mount_options => 'noatime,nodiratime,logbufs=8',
      before        => Package['dovecot'];
  } -> file{'/var/spool/mail/mails':
    ensure => directory,
    owner  => root,
    group  => mail,
    mode   => '0660',
    before => Service['exim','dovecot'],
  }
}

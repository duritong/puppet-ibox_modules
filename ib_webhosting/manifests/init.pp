# webhosting stuff
class ib_webhosting(
  $backup_host     = "backup1.${::domain}",
  $backup_base_dir = '/data/backup_www',
) {
  include ::git

  file{
    '/usr/local/sbin/migrate_hosting.sh':
      source  => 'puppet:///modules/ib_webhosting/scripts/migrate_hosting.sh',
      owner   => root,
      group   => 0,
      mode    => '0500';
    '/usr/local/sbin/restore_hosting_from_backup.sh':
      content => template('ib_webhosting/scripts/restore_hosting_from_backup.sh.erb'),
      owner   => root,
      group   => 0,
      mode    => '0500';
  }

  if str2bool($::selinux) {
    # otherwise some operations via ssh are not allowed
    if $::operatingsystemmajrelease == '6' {
      selboolean{
        'ssh_chroot_manage_apache_content':
          value      => 'on',
          persistent => true,
          require    => Package['apache'],
          before     => Service['apache'];
      }
    }
  }
}

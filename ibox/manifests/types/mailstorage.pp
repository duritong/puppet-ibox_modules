# a mailstorage
class ibox::types::mailstorage(
  $sql_config = hiera('ib_dovecot::storage::sql_config'),
) {
  include ::ib_disks::datavgs::mailstorage
  class{'::ib_dovecot::storage':
    sql_config => $sql_config,
  }
  include ::ib_exim::storage
  Class['ib_disks::datavgs::mailstorage'] ->
    Class['ib_dovecot::storage','ib_exim::storage']
}

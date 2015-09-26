# a mailstorage
class ibox::types::mailstorage {
  include ::ibox
  include ::ib_disks::datavgs::mailstorage
  include ::ib_dovecot::storage
  include ::ib_exim::storage
  Class['ib_disks::datavgs::mailstorage'] ->
    Class['ib_dovecot::storage','ib_exim::storage']
}

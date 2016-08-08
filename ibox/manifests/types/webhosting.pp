# a simple webserver
class ibox::types::webhosting {
  include ::ib_webhosting::hostings
  include ::ibackup::sftp
}

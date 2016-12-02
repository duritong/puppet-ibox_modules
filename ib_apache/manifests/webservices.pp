# webservices
class ib_apache::webservices {
  include ::ib_apache::extended
  include ::ib_apache::services::myadmin
  include ::ib_apache::services::webhtpasswd
  if versioncmp($::operatingsystemmajrelease, '6') > 0 {
    include ::ib_apache::services::coquelicot
  }
  include ::ib_apache::services::piwik
}

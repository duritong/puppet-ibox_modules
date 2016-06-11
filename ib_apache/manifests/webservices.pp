# webservices
class ib_apache::webservices {
  include ::ib_apache::extended
  include ::ib_apache::services::myadmin
  include ::ib_apache::services::webhtpasswd
  include ::ib_apache::services::coquelicot
}

# webservices
class ib_apache::webservices {
  include ::ib_apache::webhosting_php
  include ::ib_apache::services::myadmin
}

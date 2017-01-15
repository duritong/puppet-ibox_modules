# manage ttrss installations
class ib_apache::services::ttrss(
  $instances = {}
){
  create_resources('ib_apache::services::ttrss::instance',$instances)
}

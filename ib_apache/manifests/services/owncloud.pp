# manage owncloud installations
class ib_apache::services::owncloud(
  $instances = {}
){
  create_resources('ib_apache::services::owncloud::instance',$instances)
}

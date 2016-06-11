# manage a coquelicot installation
class ib_apache::services::coquelicot(
  $instances = {}
){
  create_resources('ib_apache::services::coquelicot::instance',$instances)
}

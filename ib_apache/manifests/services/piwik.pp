# manage a piwik installation
class ib_apache::services::piwik(
  $instances = {}
){
  create_resources('ib_apache::services::piwik::instance',$instances)
}

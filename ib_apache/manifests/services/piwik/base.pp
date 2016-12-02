# base services for piwik
class ib_apache::services::piwik::base {
  file{
    '/usr/local/sbin/update_piwik.sh':
      source  => 'puppet:///modules/ib_apache/services/scripts/update_piwik.sh',
      owner   => root,
      group   => 0,
      mode    => '0700';
  }
}

# base services for piwik
class ib_apache::services::piwik::base(
  $php_installation = 'scl56',
) {
  file{
    '/usr/local/sbin/update_piwik.sh':
      content => template('ib_apache/services/piwik/update_piwik.sh.erb'),
      owner   => root,
      group   => 0,
      mode    => '0700';
  }
}

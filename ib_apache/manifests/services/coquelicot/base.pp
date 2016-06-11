# basic stuff for coquelicot
class ib_apache::services::coquelicot::base {
  $base_path = '/var/www/coquelicot'

  include ::systemd
  file{
    $base_path:
      ensure => directory,
      owner   => root,
      group   => 0,
      mode    => '0644';
    '/etc/systemd/system/coquelicot@.service':
      content => template('ib_apache/services/coquelicot/coquelicot@.service.erb'),
      owner   => root,
      group   => 0,
      mode    => '0644',
      notify  => Exec['systemctl-daemon-reload'],
  }

}

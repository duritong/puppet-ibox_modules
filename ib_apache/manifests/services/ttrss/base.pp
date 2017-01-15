# basic things for ttrss
class ib_apache::services::ttrss::base{
  if versioncmp($operatingsystemmajrelease,'6') > 0 {
    include ::systemd
    file{'/etc/systemd/system/ttrss@.service':
      source => 'puppet:///modules/ib_apache/services/ttrss/ttrss@.service',
      notify => Exec['systemctl-daemon-reload'],
      owner  => root,
      group  => 0,
      mode   => '0644',
    }
  }
}

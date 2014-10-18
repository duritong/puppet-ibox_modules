# keepalived wrapper
# only an internal calls hence referring
# to the types class
class ib_keepalived::hafw(
  $conntrackd_interface = $ibox::types::hafw::conntrackd_interface,
  $is_master            = $ibox::types::hafw::is_master,
  $auth_pass            = $ibox::types::hafw::auth_pass,
  $out_ipaddress        = $ibox::types::hafw::out_ipaddress,
  $out_interface        = $ibox::types::hafw::out_interface,
  $in_ipaddress         = $ibox::types::hafw::in_ipaddress,
  $in_interface         = $ibox::types::hafw::in_interface,
){
  #https://bugs.launchpad.net/tripleo/+bug/1342872
  selboolean{'domain_kernel_load_modules':
    persistent => true,
    value      => 'on',
    before     => Service['keepalived'],
  }
  include keepalived
  selinux::policy{'ib_keepalived':
    te_source => 'puppet:///modules/ib_keepalived/selinux/ib_keepalived.te',
    before    => Service['keepalived'],
  }
  #class{'keepalived::global_defs':
  #  notification_email => "root@${::fqdn}",
  #}
  $track_interface = reject(reject(
    split($::interfaces,','),
      $conntrackd_interface),'lo')

  if $is_master {
    $state = 'MASTER'
    $priority = '101'
  } else {
    $state = 'BACKUP'
    $priority = '100'
  }

  keepalived::vrrp::instance { 'VI_50':
    interface            => $conntrackd_interface,
    state                => $state,
    virtual_router_id    => '50',
    priority             => $priority,
    auth_type            => 'PASS',
    auth_pass            => $auth_pass,
    virtual_ipaddress    => [
      ## out
      #{
      #  ip  => $out_ipaddress,
      #  dev => $out_interface,
      #},
      # in
      {
        ip  => $in_ipaddress,
        dev => $in_interface,
      },
    ],
    track_interface      => $track_interface,
    notify_script_master => '"/etc/conntrackd/primary-backup.sh primary"',
    notify_script_backup => '"/etc/conntrackd/primary-backup.sh backup"',
    notify_script_fault  => '"/etc/conntrackd/primary-backup.sh fault"',
    #smtp_alert            => true,
  }
}

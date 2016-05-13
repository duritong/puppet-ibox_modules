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
  $in_ip6address        = $ibox::types::hafw::in_ip6address,
  $in_interface         = $ibox::types::hafw::in_interface,
){
  #https://bugs.launchpad.net/tripleo/+bug/1342872
  selboolean{'domain_kernel_load_modules':
    persistent => true,
    value      => 'on',
    before     => Service['keepalived'],
  }
  include ::keepalived
  selinux::policy{'ib_keepalived':
    te_source => 'puppet:///modules/ib_keepalived/selinux/ib_keepalived.te',
    before    => Service['keepalived'],
  }
  class{'::keepalived::global_defs':
    notification_email => "root@${::fqdn}",
  }

  if $is_master {
    $state = 'MASTER'
    $priority = '101'
  } else {
    $state = 'BACKUP'
    $priority = '100'
  }

  file{
    '/usr/local/sbin/set_vrrp_state':
      content => '#!/bin/bash
if [ -z $1 ] || [ -z $2 ] || [-z $3 ]; then
  echo "$0 GROUP|INSTANCE <name> <state>"
  exit 1
fi
echo $1 $2 is in $3 state > /run/keepalive.$1.$2.state
',
      owner => root,
      group => 0,
      mode  => '0700';
    '/usr/local/sbin/get_vrrp_state':
      content => '#!/bin/bash
cat /run/keepalive.*.*.state
',
      owner => root,
      group => 0,
      mode  => '0700';
  } -> keepalived::vrrp::instance { 'VI_50':
    interface            => $conntrackd_interface,
    state                => $state,
    virtual_router_id    => '50',
    dont_track_primary   => true,
    priority             => $priority,
    auth_type            => 'PASS',
    auth_pass            => $auth_pass,
    virtual_ipaddress    => [
      # out
      {
        ip  => $out_ipaddress,
        dev => $out_interface,
      },
      # in
      {
        ip  => $in_ipaddress,
        dev => $in_interface,
      },
      {
        ip  => $in_ip6address,
        dev => $in_interface,
      },
    ],
    notify_script_master => '/usr/local/sbin/conntrackd-primary-backup.sh primary',
    notify_script_backup => '/usr/local/sbin/conntrackd-primary-backup.sh backup',
    notify_script_fault  => '/usr/local/sbin/conntrackd-primary-backup.sh fault',
    notify_script        => '/usr/local/sbin/set_vrrp_state"',
    smtp_alert           => true,
  }
}

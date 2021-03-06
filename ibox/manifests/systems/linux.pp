# manage things that should go on linux based
# systems
class ibox::systems::linux(
  $use_denyhosts = true,
) {
  include ::gpm
  include ::logrotate
  include ::mc
  include ::grub::first_default
  include ::cron_splay

  # random generation for debian or EL > 5
  if !(($::operatingsystem in [ 'CentOS', 'RedHat' ])
    and ($::operatingsystemmajrelease == '5')){
    include ::haveged
  }

  class{'::rkhunter':
    local_conf => hiera_array('rkhunter::local_conf',[]),
  }

  if $ibox::use_shorewall {
    include ::ib_shorewall
  }
  if $ibox::use_munin {
    include ::ib_munin::plugins::linux
  }

  if $use_denyhosts {
    include ::denyhosts
  }
  include ::mlocate

  if $::operatingsystem in ['CentOS', 'RedHat'] and
    versioncmp($::operatingsystemmajrelease,'6') < 0 {
    include ::syslog
  } else {
    include ::rsyslog
  }

  if str2bool($::selinux) {
    class{'::selinux':
      manage_munin   => $ibox::use_munin,
      setroubleshoot => 'absent',
    }
  }
  case $::operatingsystem {
    'Debina','Ubuntu': { include ::lsb }
    'CentOS': {
      if versioncmp($::operatingsystemmajrelease,'7') < 0 {
        include ::lsb
      }
    }
    default: {}
  }

  # deploy unbound for local caching
  if '127.0.0.1' in $resolvconf::nameservers {
    include ::ib_unbound::local_only
  }

  include ::ib_certs

  if $::ekeyd_key or hiera('ekeyd::egd::host',false) {
    if $::operatingsystem == 'CentOS' and
      versioncmp($::operatingsystemmajrelease,'6') > 0 {
      $manage_monit = false
    } else {
      $manage_monit = true
    }
    if $::ekeyd_key {
      $ekeyd_key_path = hiera('ekeyd::key_path','/var/lib/puppet/ekeyd_keys')
      class{'::ekeyd':
        host             => true,
        manage_munin     => true,
        manage_shorewall => true,
        manage_monit     => $manage_monit,
        masterkey        => file("${ekeyd_key_path}/${::fqdn}.masterkey"),
      }
    } elsif hiera('ekeyd::egd::host',false) {
      $default_net = [ 'net' ]
      class{'::ekeyd::egd':
        manage_shorewall => true,
        manage_monit     => $manage_monit,
        shorewall_zones  => hiera('ekeyd::shorewall_zones',$default_net),
      }
    }
  }
  include ::restartmonkey
}

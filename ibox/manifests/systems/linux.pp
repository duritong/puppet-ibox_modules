# manage things that should go on linux based
# systems
class ibox::systems::linux(
  $use_denyhosts = true,
) {
  include gpm
  include logrotate
  include mc
  include grub::first_default
  include cron_splay

  # random generation for debian or EL > 5
  if !(($::operatingsystem in [ 'CentOS', 'RedHat' ]) and ($::operatingsystemmajrelease == '5')){
    include haveged
  }

  class{'rkhunter':
    local_conf => hiera_array('rkhunter::local_conf',[]),
  }

  if $ibox::use_shorewall {
    include ib_shorewall
  }
  if $ibox::use_munin {
    include ib_munin::plugins::linux
  }

  if $use_denyhosts {
    include denyhosts
  }
  include mlocate

  if $::operatingsystem in ['CentOS', 'RedHat'] and $::operatingsystemmajrelease < 6 {
    include syslog
  } else {
    include rsyslog
  }

  if str2bool($::selinux) {
    class { 'selinux':
      manage_munin    => $ibox::use_munin,
      setroubleshoot  => 'absent'
    }
  }
  case $::operatingsystem {
    debian,ubuntu: { include lsb }
    centos: {
      if $::operatingsystemmajrelease < 7 {
        include lsb
      }
    }
  }

  # deploy unbound for local caching
  if '127.0.0.1' in $resolvconf::nameservers {
    include ib_unbound::local_only
  }
}

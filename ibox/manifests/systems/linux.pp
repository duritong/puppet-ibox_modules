# manage things that should go on linux based
# systems
class ibox::systems::linux {
  include gpm
  include logrotate
  include mc
  include grub::first_default
  include cron_splay

  # random generation for debian or EL > 5
  include haveged

  class{'rkhunter':
    local_conf => hiera_array('rkhunter::local_conf',[]),
  }

  if $ibox::use_shorewall {
    include ib_shorewall
  }

  include denyhosts
  include mlocate

  include rsyslog

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
}

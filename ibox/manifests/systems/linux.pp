# manage things that should go on linux based
# systems
class ibox::systems::linux {
  include fwtools

  include gpm
  include logrotate
  include lsb
  include mc
  include grub::first_default
  include cron_splay

  $empty_arr = []
  class{'rkhunter':
    local_conf => hiera_array('rkhunter::local_conf',$empty_arr),
  }

  if $ibox::use_shorewall {
    include ib_shorewall
  }

  include denyhosts
  include mlocate

  if str2bool($::selinux) {
    class { 'selinux':
      manage_munin    => $ibox::use_munin,
      setroubleshoot  => 'absent'
    }
  }
}

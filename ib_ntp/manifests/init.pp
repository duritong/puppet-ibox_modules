# manage ntp/chrony installations
class ib_ntp {

  $ntp_munin = $::operatingsystem ? {
    OpenBSD => false,
    default => $ibox::use_munin,
  }
  if $::operatingsystem == 'CentOS' and $::operatingsystemmajrelease > 6 {
    include chrony
    if $ntp_munin {
      include ib_ntp::munin::chrony
    }
    if $ibox::use_shorewall {
      include shorewall::rules::ntp::client
    }
  } else {
    class{'ntp':
      manage_shorewall  => $ibox::use_shorewall,
      manage_munin      => $ntp_munin,
      manage_nagios     => $ibox::use_nagios,
    }
  }

}

# munin for chrony
# from https://raw.githubusercontent.com/munin-monitoring/contrib/master/plugins/time/chrony
class ib_ntp::munin::chrony {
  munin::plugin::deploy{'chrony'
    source  => 'ib_ntp/munin/chrony',
  }
}

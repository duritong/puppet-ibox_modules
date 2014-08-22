# only put diskstats on non virtual systems
class ib_munin::plugins::linux inherits munin::plugins::linux {

  $ensure_diskstats = str2bool($::is_virtual) ? {
    true    => 'absent',
    default => 'present'
  }
  Munin::Plugin['diskstats']{
    ensure => $ensure_diskstats,
  }

}

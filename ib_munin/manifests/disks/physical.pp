# monitor disks with smartd & hddtemp
class ib_munin::disks::physical(
  $disks = false
) {
  if $physical_disks {
    $hddtemp_disks = join($physical_disks,' ')
    munin::plugin { hddtemp_smartctl: config => "env.drives ${hddtemp_disks}\nuser root", }
    $smartd_disks = regsubst($physical_disks,'(.*)',"smart_\\1")
    munin::plugin { $smartd_disks: ensure => "smart_", config => "user root" }
  }
}

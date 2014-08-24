# monitor disks with smartd & hddtemp
class ib_munin::disks::physical(
  $disks = false
) {
  if $disks {
    $hddtemp_disks = join($disks,' ')
    munin::plugin { hddtemp_smartctl: config => "env.drives ${hddtemp_disks}\nuser root", }
    $smartd_disks = regsubst($disks,'(.*)',"smart_\\1")
    munin::plugin { $smartd_disks: ensure => "smart_", config => "user root" }
  }
}

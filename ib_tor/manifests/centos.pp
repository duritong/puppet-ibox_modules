# some temporary centos tuning
class ib_tor::centos {
  selinux::policy{
    'tor_dac':
      te_source => 'puppet:///modules/ib_tor/selinux/tor_dac/tor_dac.te',
      before    => Service['tor'],
  }
}

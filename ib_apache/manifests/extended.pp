# some things that not most but not all apaches need
# mainly this enables a few selinux booleans, as well
# as deploy our standard policy
class ib_apache::extended {
  if str2bool($::selinux) {
    selboolean{
      # in general we want that
      # it could be that we should think about it at one point
      [ 'httpd_ssi_exec',
        'httpd_can_network_connect_db',
        'httpd_can_network_connect', ]:
          value       => 'on',
          persistent  => true,
          require     => Package['apache'],
          before      => Service['apache'];
    }
    # only on centos >= 6
    if versioncmp($::operatingsystemmajrelease,'5') > 0 {
      selboolean{
        'httpd_use_gpg':
          value       => 'on',
          persistent  => true,
          require     => Package['apache'],
          before      => Service['apache'];
      }
      if versioncmp($::operatingsystemmajrelease,'6') == 0 {
        # so far only on el6
        # we might need to add a new one for el7
        selinux::policy{
          'ibox-httpd':
            te_source => 'puppet:///modules/ib_selinux/policies/ibox-httpd/ibox-httpd.te',
            require   => Package['apache'],
            before    => Service['apache'];
        }
      }
    }
  }
}

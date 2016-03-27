# manage ntp/chrony installations
class ib_ntp {

  $ntp_munin = $::operatingsystem ? {
    OpenBSD => false,
    default => $ibox::use_munin,
  }
  if $::operatingsystem == 'CentOS' and versioncmp($::operatingsystemmajrelease,'6') > 0 {
    $hiera_chrony_keys = hiera('chrony::config_keys',false)
    if $hiera_chrony_keys {
      $chrony_keys = $hiera_chrony_key
    } else {
      $chrony_keys_sha1 = sha1(hiera('chrony::config_keys_plain',fqdn_rand(6500000000)))
      $chrony_keys = "SHA1 HEX:${chrony_keys_sha1}"
    }
    class{'chrony':
      chrony_password => $chrony_keys,
    }
    if $ntp_munin {
      include ::ib_ntp::munin::chrony
    }
    if $ibox::use_shorewall {
      include ::shorewall::rules::ntp::client
    }
  } else {
    class{'ntp':
      manage_shorewall  => $ibox::use_shorewall,
      manage_munin      => $ntp_munin,
      manage_nagios     => $ibox::use_nagios,
    }
  }

}

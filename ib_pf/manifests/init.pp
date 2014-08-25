# add a few pf extensions
class ib_pf {
  file{'/etc/pf.iblacklist':
    ensure  => file,
    replace => false,
    before  => File['pf_config'],
    owner   => root,
    group   => 0,
    mode    => '0600';
  }

  file{'/usr/local/sbin/reload_pf_blacklist':
    content => "#!/usr/local/bin/bash\npfctl -t iblacklist -T replace -f /etc/pf.iblacklist\n",
    owner   => root,
    group   => 0,
    mode    => '0700';
  }
}

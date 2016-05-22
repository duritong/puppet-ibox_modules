# configure surroundings for apc:
class ib_php::extensions::apc {
  # fix apc location as it might use some diskspace
  file{'/var/www/apc_tmp':
    ensure  => directory,
    require => Package['apache'],
    owner   => root,
    group   => 0,
    mode    => '1777';
  }

  if str2bool($::selinux) {
    $seltype = $::operatingsystemmajrelease ? {
      '5'     => 'httpd_sys_script_rw_t',
      default => 'httpd_sys_rw_content_t'
    }
    File['/var/www/apc_tmp']{
      seltype => $seltype
    }
    selinux::fcontext{
      '/var/www/apc_tmp(/.*)?':
        setype  => $seltype,
        before  => [ Service['apache'], File['/var/www/apc_tmp'] ];
    }
  }

  # fix broken apc.ini
  exec{
    'sed -i s/^apc.preload_path$/apc.preload_path=/ /etc/php.d/apc.ini':
      before  => Augeas['apc_settings'],
      require => Package['php-pecl-apc'],
      onlyif  => 'grep -qE \'^apc.preload_path$\' /etc/php.d/apc.ini';
    'sed -i s/^apc.filters$/apc.filters=/ /etc/php.d/apc.ini':
      before  => Augeas['apc_settings'],
      require => Package['php-pecl-apc'],
      onlyif  => 'grep -qE \'^apc.filters$\' /etc/php.d/apc.ini';
  }
  augeas { 'apc_settings':
    # http://chrisgilligan.com/wordpress/how-to-configure-apc-cache-on-virtual-servers-with-php-running-under-fcgid/
    context => '/files/etc/php.d/apc.ini/.anon',
    changes => [
      'set apc.shm_size 64M',
      'set apc.ttl 0',
      'set apc.mmap_file_mask /var/www/apc_tmp/apc.XXXXXX',
      # partially because of http://lists.horde.org/archives/horde/Week-of-Mon-20140414/051263.html
      'set apc.enable_cli 1',
    ],
    require => [ File['/var/www/apc_tmp'], Package['php-pecl-apc']];
  }
}

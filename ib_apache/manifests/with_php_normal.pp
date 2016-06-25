# php host as normal as possible
class ib_apache::with_php_normal {
  include ::ib_apache::extended
  include ::php

  if $::operatingsystemmajrelease == '6' {
    include ::php::packages::zts
  }

  include ::php::extensions::alldbs
  include ::php::pear::common
  include ::php::pear::common::cli
  include ::php::extensions::pear::net_useragent_detect
  include ::php::extensions::mcrypt
  if !(($::operatingsystem == 'CentOS') and versioncmp($::operatingsystemmajrelease,'6') < 0) {
    include ::php::packages::mbstring
    include ::php::extensions::xml
  }

  include ::shorewall::rules::out::postgres
  include ::shorewall::rules::out::mysql

  augeas { 'apc_settings':
    # http://chrisgilligan.com/wordpress/how-to-configure-apc-cache-on-virtual-servers-with-php-running-under-fcgid/
    context => '/files/etc/php.d/apc.ini/.anon',
    changes => [
      'set apc.shm_size 64M',
      'set apc.ttl 0',
      # partially because of http://lists.horde.org/archives/horde/Week-of-Mon-20140414/051263.html
      'set apc.enable_cli 1',
    ],
  }
}

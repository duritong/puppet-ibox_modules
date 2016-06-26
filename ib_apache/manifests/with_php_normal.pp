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
}

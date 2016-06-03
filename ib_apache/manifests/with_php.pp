# setup an apache with php and fastcgi
# this is how our standard php setup looks like
# It is:
#   * apache    - running with the mpm worker
#   * mod_cfgid - which runs our php apps through suexec
#   * php       - standard and any kind of scls
#   * 
class ib_apache::with_php(
  $suhosin_cryptkey_id = 'main',
) {
  include ::ib_apache::extended

  class{'::php':
    suhosin_cryptkey => trocla("php_suhosin_cryptkey_${suhosin_cryptkey_id}",'plain',{ length => 32 })
  }
  include ::php::mod_fcgid

  include ::mod_fcgid
  include ::apache::include::mod_fcgid

  include ::shorewall::rules::out::postgres
  include ::shorewall::rules::out::mysql


  if $::operatingsystemmajrelease == '6' {
    include ::php::packages::zts
  }

  include ::php::extensions::alldbs
  include ::php::pear::common
  include ::php::pear::common::cli
  include ::php::extensions::pear::net_useragent_detect
  include ::php::extensions::mcrypt
  if !(($::operatingsystem == 'CentOS') and ($::operatingsystemmajrelease == '5')) {
    include ::php::packages::mbstring
    include ::php::extensions::xml
  }
}

# basic stuff to manage owncloud
class ib_apache::services::owncloud::base(
  $php_installation = 'scl56',
) {

  $php_scl = regsubst($php_installation,'scl','rh-php')

  # authenticate agains imap
  include ::shorewall::rules::out::imap

  # libraries without an own module
  ensure_packages(['ffmpeg'])

  file{
    '/usr/local/sbin/update_owncloud.sh':
      source  => 'puppet:///modules/ib_apache/services/owncloud/update_owncloud.sh',
      owner   => root,
      group   => 0,
      mode    => '0700';
    '/usr/local/sbin/occ_wrap':
      content => template('ib_apache/services/owncloud/occ_wrap.sh.erb'),
      owner   => root,
      group   => 0,
      mode    => '0700';
  }
}

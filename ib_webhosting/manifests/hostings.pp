# create hostings from hiera
class ib_webhosting::hostings(
  $static        = {},
  $php           = {},
  $wordpress     = {},
  $mediawiki     = {},
  $joomla        = {},
  $drupal        = {},
  $spip          = {},
  $simplemachine = {},
  $typo3         = {},
  $gallery2      = {},
  $silverstripe  = {},
  $passenger     = {},
  $redirect      = {},
  $modperl       = {},
){

  $default_options = {
    ssl_mode   => true,
    nagios_use => 'http-service',
    uid        => 'iuid',
    password   => 'trocla',
  }
  create_resources('webhosting::static', $static, $default_options)

  $php_options = merge($default_options, {
    watch_adjust_webfiles => 'present',
    user_scripts          => 'ALL',
    run_mode              => 'fcgid',
    run_uid               => 'iuid',
    wwwmail               => true
  })
  create_resources('webhosting::php', $php, $php_options)

  $wordpress_options = merge($php_options, {})
  create_resources('webhosting::php::wordpress', $wordpress, $wordpress_options)

  $mediawiki_options = delete(merge($php_options, {
    config          => 'template',
    db_server       => '127.0.0.1',
    secret_key      => 'trocla',
    db_pwd          => 'trocla',
    squid_servers   => 'absent',
    spam_protection => true,
  }),['watch_adjust_webfiles','user_scripts'])
  create_resources('webhosting::php::mediawiki', $mediawiki, $mediawiki_options)

  if versioncmp($::operatingsystemmajrelease,'7') < 0 {
    $php_installation = 'scl54'
  } else {
    $php_installation = 'system'
  }
  $joomla_options = merge($php_options, {
    manage_config    => false,
    git_repo         => 'https//git.immerda.ch/ijoomla.git',
    php_installation => $php_installation,
  })
  create_resources('webhosting::php::joomla', $joomla, $joomla_options)

  $drupal_options = merge($php_options, {
    git_repo => 'git://git.immerda.ch/idrupal.git'
  })
  create_resources('webhosting::php::drupal', $drupal, $drupal_options)

  $spip_options = $php_options
  create_resources('webhosting::php::spip', $spip, $spip_options)

  $smf_options = merge($php_options, {
    ssl_mode      => 'force',
    manage_config => false,
    git_repo      => 'https//git.immerda.ch/ismf.git',
  })
  create_resources('webhosting::php::simplemachine', $simplemachine, $smf_options)

  $typo3_options = merge($php_options, {
    manage_config => false,
  })
  create_resources('webhosting::php::typo3', $typo3, $typo3_options)

  $gallery2_options = merge($php_options, {
    git_repo => 'https//git.immerda.ch/igallery2.git',
  })
  create_resources('webhosting::php::gallery2', $gallery2, $gallery2_options)

  $silverstripe_options = merge($php_options, {
    manage_config => false,
    git_repo      => 'https//git.immerda.ch/silverstripe.git',
  })
  create_resources('webhosting::php::silverstripe', $silverstripe, $silverstripe_options)

  $passenger_options = merge($default_options, {
    run_mode      => 'fcgid',
    passenger_ree => $::operatingsystemmajrelease ? {
      /5/         => true,
      default     => false,
    },
    run_uid       => 'iuid',
    wwwmail       => true,
  })
  create_resources('webhosting::passenger', $passenger, $passenger_options)

  $perl_options = merge($default_options, {
    run_mode => 'fcgid',
    uid      => 'iuid',
    run_uid  => 'iuid',
    wwwmail  => true
  })
  create_resources('webhosting::modperl', $modperl,$perl_options)

  create_resources('apache::vhost::redirect', $redirect, {ssl_mode => true })

  include ::ib_apache::extended

  if !empty($php) or !empty($wordpress) or !empty($mediawiki) or
    !empty($joomla) or !empty($drupal) or !empty($spip) or
    !empty($simplemachine) or !empty($typo3) or !empty($gallery2) or
    !empty($silverstripe) {

    include ::ib_apache::webhosting_php
  }
}

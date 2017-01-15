# setup a piwik
#
#  ssl_mode: is here for compatibility, but handled completely internally atm.
define ib_apache::services::piwik::instance(
  $ensure   = 'present',
  $ssl_mode = true,
) {
  # header varies based on apache version
  $header_str = $operatingsystemmajrelease ? {
    /^6/    => 'set Vary User-Agent',
    default => 'always merge Vary User-Agent',
  }
  require ib_apache::services::piwik::base

  $php_installation = $ib_apache::services::piwik::base::php_installation
  webhosting::php{
    $name:
      ensure             => $ensure,
      # mind also the cron below that section
      domainalias        => 'absent',
      # this is a little bit special see below
      ssl_mode           => true,
      nagios_check       => 'unmanaged',
      php_settings       => {
        file_uploads     => 'Off',
        magic_quotes_gpc => 'Off',
      },
      run_mode           => 'fcgid',
      nagios_use         => 'http-service',
      uid                => 'iuid',
      run_uid            => 'iuid',
      password           => 'trocla',
      wwwmail            => true,
      php_installation   => $php_installation,
      additional_options => "
  <LocationMatch \"^/$\">
       # set this header to support user-agent
       # detection through a caching proxy
       # since mod_rewrite does not do it for us
       # (s. http://stackoverflow.com/questions/3698363/mod-rewrite-not-sending-vary-accept-language-when-rewritecond-matches)
       Header ${header_str}
  </LocationMatch>

  RewriteEngine on
  RewriteCond %{HTTPS} !=on
  RewriteRule ^/$ https://%{HTTP_HOST}/index.php [R=301,L]

  # Rewrite URLs to https that go for the admin area
  RewriteCond %{REMOTE_ADDR} !^127\\.[0-9]+\\.[0-9]+\\.[0-9]+$
  RewriteCond %{HTTPS} !=on
  RewriteCond %{REQUEST_URI} !^/piwik\\.(js|php)|/robots\\.txt$
  RewriteCond %{REQUEST_URI} (.*)
  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=permanent]";
  }
  file{"/etc/cron.d/piwik_${name}": }
  if $ensure == 'present' {
    $inst = regsubst($php_installation,'^scl','php')
    require "::php::scl::${inst}"
    $php_basedir = getvar("php::scl::${inst}::basedir")
    $cron_min = fqdn_rand(60,$name)
    archive { "/var/www/vhosts/${name}/latest.tar.gz":
      ensure          => present,
      extract         => true,
      extract_path    => "/var/www/vhosts/${name}/www",
      extract_command => 'tar --exclude "How*.html" --strip-components=1 -xzf %s',
      source          => 'https://builds.piwik.org/piwik-latest.tar.gz',
      creates         => "/var/www/vhosts/${name}/www/piwik.php",
      cleanup         => true,
      user            => $name,
    } -> file{"/var/www/vhosts/${name}/www/tmp":
      owner  => $name,
      group  => $name,
      mode   => '0660',
      before => Service['apache'];
    }
    File["/etc/cron.d/piwik_${name}"]{
      content => "${cron_min} 0 * * * ${name}_run  source ${php_basedir}/enable && php /var/www/vhosts/${name}/www/console core:archive --url=http://${name} > /dev/null\n",
      require => File["/var/www/vhosts/${name}/www/tmp"],
      owner   => root,
      group   => 0,
      mode    => '0644',
    }
  } else {
    File["/etc/cron.d/piwik_${name}"]{
      ensure => 'absent',
    }
  }

  nagios::service::http{$name:
    ensure   => $ensure,
    ssl_mode => 'force',
    use      => 'http-service',
  }
}

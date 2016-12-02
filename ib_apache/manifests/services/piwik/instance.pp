# setup a piwik
define ib_apache::services::piwik::instance() {
  # header varies based on apache version
  $header_str = $operatingsystemmajrelease ? {
    /^6/    => 'set Vary User-Agent',
    default => 'always merge Vary User-Agent',
  }
  webhosting::php{
    $name:
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
      php_installation   => 'scl56',
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

  # piwik stuff
  file{"/etc/cron.d/piwik_${name}":
      content => "5 0 * * * ${name}_run scl enable scl56 'php /var/www/vhosts/${name}/www/console core:archive --url=http://${name}' > /dev/null\n",
      require => Webhosting::Php[$name],
      owner   => root,
      group   => 0,
      mode    => '0644';
  }
  archive { "/var/www/vhosts/${name}/latest.tar.gz":
    ensure          => present,
    extract         => true,
    extract_path    => "/var/www/vhosts/${name}/www",
    extract_command => 'tar --exclude "How*.html" --strip-components=1 -xzf %s',
    source          => 'https://builds.piwik.org/piwik-latest.tar.gz',
    creates         => "/var/www/vhosts/${name}/www/piwik.php",
    cleanup         => true,
  }

  require ib_apache::services::piwik::base

  nagios::service::http{$name:
    ensure   => 'present',
    ssl_mode => 'force',
    use      => 'http-service',
  }
}

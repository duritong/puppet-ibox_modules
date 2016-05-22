# class that is used to configure
# php things for our shared webhosting
# servers
class ib_apache::webhosting_php(
  $fcgid_max_processes_per_vhost = $::processorcount * 2,
) {
  include ::ib_apache::with_php
  include ::apache::mozilla_autoconfig

  # limit amount of processes for webhosting
  # http://www.cloudlinux.com/blog/clnews/perfecting-fastcgi-settings-for-shared-hosting.php
  # it does not really make sense to allow more than twice as much processes
  # than cpus, as anyway only one can run at a time, requests are queued and we
  # are a shared hosting env, # hence there are tons of others running as well.
  apache::config::global{'mod_fcgid_tuning_shared_webhostings.conf':
    content => "<IfModule mod_fcgid.c>
  # A max of two times the processor count of
  # php requests per vhost.
  # so we don't trash systems with high load
  # especially our dbhosts
  FcgidMaxProcessesPerClass ${fcgid_max_processes_per_vhost}
</IfModule>\n",
  }


  include ::php::packages::ssh2
  include ::php::packages::soap
  include ::php::packages::imagick
  include ::php::extensions::spreadsheet_excel

  include ::imagemagick
  include ::gpg
}

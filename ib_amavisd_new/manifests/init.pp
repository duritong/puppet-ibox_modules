# our wrapper for amavisd
class ib_amavisd_new(
  $amavisd_domain = $::domain,
) {
  class{'amavisd_new':
    site_config    => 'ib_amavisd_new',
    config_content => template("ib_amavisd_new/amavisd.conf_el${::operatingsystemmajrelease}"),
    manage_munin   => $ibox::use_munin,
  }
}

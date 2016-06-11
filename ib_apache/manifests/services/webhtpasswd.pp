# our htpasswd helper site
class ib_apache::services::webhtpasswd(
  $htpasswd_name = undef,
) {
  if $htpasswd_name {
    webhosting::static{
      $htpasswd_name:
        ssl_mode     => 'force',
        git_repo     => {
          git_repo   => 'https://git.immerda.ch/web/htpasswd.immerda.ch.git',
          submodules => true,
        },
        mod_security => false;
    }
  }
}

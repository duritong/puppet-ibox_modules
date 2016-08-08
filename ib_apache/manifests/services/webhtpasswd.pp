# our htpasswd helper site
class ib_apache::services::webhtpasswd(
  $htpasswd_name = undef,
) {
  if $htpasswd_name {
    webhosting::static{
      $htpasswd_name:
        domainalias  => 'absent',
        ssl_mode     => 'force',
        uid          => iuid($htpasswd_name,'webhosting'),
        git_repo     => {
          git_repo   => 'https://git.immerda.ch/web/htpasswd.immerda.ch.git',
          submodules => true,
        };
    }
  }
}

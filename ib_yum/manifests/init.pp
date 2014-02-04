# yum setup for ibox
class ib_yum(
  $elrepo_enable = false,
) {
  stage{'yum': } -> Stage['setup']
  class {
    'yum':
      manage_munin                => $ibox::use_munin,
      repo_stage                  => 'yum';
    [ 'yum::centos::cr',
      'yum::centos::puppetlabs',
      'ib_yum::centos::glei' ]:
      stage => 'yum';
  }

  include yum::updatesd::disable
}

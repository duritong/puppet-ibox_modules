# yum setup for ibox
class ib_yum(
  $elrepo_enable = false,
) {
  Stage['root'] -> stage{'yum': } -> Stage['setup']
  class {
    'yum':
      manage_munin                => $ibox::use_munin,
      repo_stage                  => 'yum';
    [ 'yum::centos::puppet',
      'ib_yum::centos::glei' ]:
      stage => 'yum';
  }
  class{'yum::centos::cr':
    stage => 'yum';
  }
}

#
# ib_yum::centos::glei class
#
# manages our repository
#
# === Parameters
#
# $repos:: {} - to override default options
#
class ib_yum::centos::glei(
  $repos = {},
) {
  $default_repos = {
    'glei' => {
      descr         => 'CentOS-$releasever - glei',
      baseurl       => 'http://yum.glei.ch/el$releasever/$basearch/',
      enabled       => 1,
      gpgcheck      => 1,
      gpgkey_source => 'puppet:///modules/ib_yum/gpg/packages_glei.ch.asc',
      priority      => 1,
      gpgkey        => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-glei',
    },
    'glei-debuginfo' => {
      descr         => 'CentOS-$releasever - glei - debuginfo',
      baseurl       => 'http://yum.glei.ch/el$releasever/$basearch-debuginfo/',
      enabled       => 0,
      gpgcheck      => 1,
      manage_gpgkey => false,
      priority      => 1,
      gpgkey        => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-glei',
    },
    'glei-testing' => {
      descr         => 'CentOS-$releasever - glei - testing',
      baseurl       => 'http://yum.glei.ch/el$releasever-testing/$basearch/',
      enabled       => 0,
      gpgcheck      => 1,
      manage_gpgkey => false,
      priority      => 1,
      gpgkey        => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-glei',
    },
    'glei-testing-debuginfo' => {
      descr         => 'CentOS-$releasever - glei - testing - debuginfo',
      baseurl       => 'http://yum.glei.ch/el$releasever-testing/$basearch-debuginfo/',
      enabled       => 0,
      gpgcheck      => 1,
      manage_gpgkey => false,
      priority      => 1,
      gpgkey        => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-glei',
    }
  }
  create_resources('yum::repo',resources_deep_merge($default_repos,$repos))
}

# the glei yum repository
class ib_yum::centos::glei {
  yum::managed_yumrepo {
    'glei':
      descr => 'CentOS-$releasever - glei',
      baseurl => 'http://yum.glei.ch/el$releasever/$basearch/',
      enabled => 1,
      gpgcheck => 1,
      priority => 1,
      gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-glei',
      require => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-glei'];
    'glei-debuginfo':
      descr => 'CentOS-$releasever - glei - debuginfo',
      baseurl => 'http://yum.glei.ch/el$releasever/$basearch-debuginfo/',
      enabled => 0,
      gpgcheck => 1,
      priority => 1,
      gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-glei',
      require => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-glei'];
    'glei-testing':
      descr => 'CentOS-$releasever - glei - testing',
      baseurl => 'http://yum.glei.ch/el$releasever-testing/$basearch/',
      enabled => 0,
      gpgcheck => 1,
      priority => 1,
      gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-glei',
      require => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-glei'];
    'glei-testing-debuginfo':
      descr => 'CentOS-$releasever - glei - testing - debuginfo',
      baseurl => 'http://yum.glei.ch/el$releasever-testing/$basearch-debuginfo/',
      enabled => 0,
      gpgcheck => 1,
      priority => 1,
      gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-glei',
      require => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-glei'];
  }
  file{'/etc/pki/rpm-gpg/RPM-GPG-KEY-glei':
    source  => 'puppet:///modules/ib_yum/gpg/packages_glei.ch.asc',
    owner   => root,
    group   => 0,
    mode    => '0600';
  }
}

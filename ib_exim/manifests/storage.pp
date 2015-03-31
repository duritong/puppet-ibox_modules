# all we need to store mails
class ib_exim::storage(
  $maildir             = '/var/mail/dovecot',
  $spam_scanner_config = {},
) {
  class{'ib_exim::backend':
    component_type   => 'storage',
    local_interfaces => '0.0.0.0',
  }
  include ::ib_exim::types::special_transports

  exim::config_snippet{
    ['acl_defer_migrating', 'acl_defer_verify_recipient' ]:
  }

  include ::ib_exim::types::database
  file{
    ['/usr/local/mail','/usr/local/mail/bin' ]:
      ensure  => directory,
      owner   => root,
      group   => mail,
      mode    => '0750';
    '/usr/local/mail/bin/find_deleted_mailboxes.rb':
      source  => 'puppet:///modules/ib_exim/tools/find_deleted_mailboxes.rb',
      owner   => root,
      group   => mail,
      mode    => '0750';
    '/usr/local/mail/bin/find_deleted_mailboxes.config.rb':
      content => template('ib_exim/tools/find_deleted_mailboxes.config.rb.erb'),
      owner   => root,
      group   => mail,
      mode    => '0640';
    '/usr/local/mail/bin/generate_local_mail_users.rb':
      source  => 'puppet:///modules/ib_exim/tools/generate_local_mail_users.rb',
      owner   => root,
      group   => 0,
      mode    => '0700';
    '/usr/local/mail/bin/generate_local_mail_users.config.rb':
      content => template('ib_exim/tools/generate_local_mail_users.config.rb.erb'),
      owner   => root,
      group   => 0,
      mode    => '0600';
    '/etc/cron.hourly/generate_local_mail_users.rb':
      ensure  => symlink,
      target  => '/usr/local/mail/bin/generate_local_mail_users.rb';
    '/usr/local/mail/bin/migratembx.rb':
      source  => 'puppet:///modules/ib_exim/tools/migratembx.rb',
      owner   => root,
      group   => 0,
      mode    => '0700';
    '/usr/local/mail/bin/migratembx.config.rb':
      content => template('ib_exim/tools/migratembx.config.rb.erb'),
      owner   => root,
      group   => 0,
      mode    => '0600';
    '/etc/cron.weekly/find_deleted_mailboxes.rb':
      content => 'su - mail -s /bin/bash -c /usr/local/mail/bin/find_deleted_mailboxes.rb',
      owner   => root,
      group   => 0,
      mode    => '0755';
  }

  require rubygems::mail
  require rubygems::maildir
  file{
    '/usr/local/mail/bin/spam_inform.rb':
      source  => 'puppet:///modules/ib_exim/tools/spam_inform.rb',
      owner   => root,
      group   => 0,
      mode    => '0700';
    '/usr/local/mail/bin/spam_inform.yaml':
      content => template('ib_exim/tools/spam_inform.yaml.erb'),
      owner   => root,
      group   => 0,
      mode    => '0400';
    '/etc/cron.weekly/spam_inform.rb':
      ensure  => symlink,
      target  => '/usr/local/mail/bin/spam_inform.rb';
    '/var/mail/transport_home':
      ensure  => directory,
      require => Package['exim'],
      before  => Service['exim'],
      owner   => exim,
      group   => 12,
      mode    => '0660';
  }
}

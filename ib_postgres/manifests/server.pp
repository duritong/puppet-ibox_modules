# configures a database server
class ib_postgres::server(
  $admin_users               = {},
  $admin_user_defaults       = {
    password => 'trocla'
  },
  $manage_disks              = true,
  $default_databases         = {},
  $default_database_defaults = {
    password => trocla,
  },
) {
  class { 'postgres':
    manage_munin     => $ibox::use_munin,
    manage_shorewall => $ibox::use_shorewall,
  }
  # db admins
  create_resources('postgres::admin_user',$admin_users,$admin_user_defaults)

  if $manage_disks {
    include ib_disks::datavgs::postgres
  }

  create_resources('postgres::default_database',$default_databases,
    $default_database_defaults)
}

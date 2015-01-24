# a HA firewall type
class ibox::types::dbserver(
  $is_mysql_server    = true,
  $is_postgres_server = true,
) {
  include ibox

  if $is_mysql_server {
    include ib_mysql::server
  }
  if $is_postgres_server {
    include ib_postgres::server
  }
}

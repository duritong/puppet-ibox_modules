# a dovecot proxy
class ibox::types::mailaccessproxy(
  $sql_config = hiera('ib_dovecot::proxy'),
) {
  class{'::ib_dovecot::proxy':
    sql_config => $sql_config,
  }
}

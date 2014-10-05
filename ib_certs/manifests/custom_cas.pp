# manage a set of custom CAs
class ib_certs::custom_cas {
  certs::manage_custom_cacert{
    'immerda':
      source => 'puppet:///modules/ib_certs/custom_cas/immer-ca.crt'
  }
}

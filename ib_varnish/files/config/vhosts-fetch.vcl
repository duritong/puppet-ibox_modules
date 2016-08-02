sub vcl_backend_response {

  include "/etc/varnish/vhosts-common.fetch_header.vcl";

  ##############
  include "/etc/varnish/vhosts-common.fetch_inline.vcl";
  return (deliver);

  ##############

  include "/etc/varnish/vhosts-common.fetch_footer.vcl";
}

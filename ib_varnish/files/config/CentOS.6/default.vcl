/*
* Prepare the environment with backends and other data,
* include basic subroutines common to all requests,
* append specific vhost routines to do all heavy lifting,
* and finally append some fallbacks in case the vhosts
* fail to handle the request.
*/
include "/etc/varnish/backends.vcl";
include "/etc/varnish/custom_backends.vcl";
include "/etc/varnish/directors.vcl";
include "/etc/varnish/setup.vcl";
include "/etc/varnish/error.vcl";
include "/etc/varnish/vhosts-recv.vcl";
include "/etc/varnish/vhosts-fetch.vcl";
// Varnish will append its default routines last.

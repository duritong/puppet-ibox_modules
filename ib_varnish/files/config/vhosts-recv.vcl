# this is an example how backend selection could work
# it sents www.immerda.ch to the particular director
sub vcl_recv {

  include "/etc/varnish/vhosts-common.recv_header.vcl";

  ##############
  if (req.http.Host == "www.immerda.ch") {
    set req.backend_hint = dir_www_immerda_ch_80.backend();
  }
  if (req.http.Host == "immerda.ch") {
    if (req.http.X-Forwarded-Proto !~ "(?i)https") {
      return(synth(750, "http://www.immerda.ch"));
    }
  }

  ##############

  include "/etc/varnish/vhosts-common.recv_footer.vcl";
}


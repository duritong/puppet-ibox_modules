
# this is an example to overwrite the cache control of the backend for a certain page
#if (req.http.host == "foo.immerda.ch" ) {
#  unset beresp.http.Cache-Control;
#  set beresp.http.Cache-Control = "public";
#}


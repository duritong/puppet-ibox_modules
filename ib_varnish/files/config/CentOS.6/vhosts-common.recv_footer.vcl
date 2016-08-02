/*
* Bypass caching of large files
* https://stackoverflow.com/questions/23065255/varnish-bypass-a-large-file
*/
if (req.http.x-pipe-mark && req.restarts > 0) {
  return(pipe);
}

# https://www.varnish-software.com/blog/using-pipe-varnish
if (req.http.Upgrade ~ "(?i)websocket") {
  return (pipe);
}

/*
* Serve stale content if the backend is unhealthy.
* Cooperates with beresp.grace in vcl_fetch.
*/
if (req.backend.healthy) {
  set req.grace = 10s;
} else {
  set req.grace = 24h;
}

/*
* Pipe alien requests straight to the backend, and keep
* doing so until the connection closes.
*/
if (req.request !~ "^(GET|HEAD|PUT|POST|TRACE|OPTIONS|DELETE)$") {
  return (pipe);
}

/*
* Make sure to only cache GET and HEAD requests.
*/
if (req.request !~ "^(GET|HEAD)$") {
  return (pass);
}

/*
* Requests with authorization should not be cached.
*/
if (req.http.Authorization) {
  return (pass);
}

/*
* Requests with any cookies still left intact should not
* be cached.
*/
if (req.http.Cookie) {
  return (pass);
}

return (hash);


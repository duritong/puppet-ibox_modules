
# setup the first parts
sub vcl_recv {
  /*
  * Clean the Host only from things we can be sure would create
  * duplicates in the cache.
  */
  set req.http.Host = regsub(req.http.Host, ":80$", "");

  if (! req.http.Host) {
    return (synth(404,"Need a host header"));
  }
  # normalize Accept-Encoding to reduce vary
  if (req.http.Accept-Encoding) {
      if (req.http.Accept-Encoding ~ "gzip") {
          set req.http.Accept-Encoding = "gzip";
      } else {
          unset req.http.Accept-Encoding;
      }
  }

}

sub vcl_hit {
  #no-cache requests have a ttl of 120 -> wait at least 15s for the next one!
  if (  req.restarts == 0 && (req.http.Cache-Control ~ "no-cache" || req.http.Cache-Control ~ "must-revalidate") && (!obj.http.X-Manually-Refreshed || obj.ttl < 105s) ) {
    ban(req.url);
    #restart to fetch the page from the backend
    return (restart);
  }
  # https://info.varnish-software.com/blog/grace-varnish-4-stale-while-revalidate-semantics-varnish
  if (obj.ttl >= 0s) {
    # normal hit
    return (deliver);
  }
  # We have no fresh fish. Lets look at the stale ones.
  if (std.healthy(req.backend_hint)) {
    # Backend is healthy. Limit age to 10s.
    if (obj.ttl + 10s > 0s) {
      set req.http.grace = "normal(limited)";
      return (deliver);
    } else {
      # No candidate for grace. Fetch a fresh object.
      return(fetch);
    }
  } else {
    # backend is sick - use full grace
    if (obj.ttl + obj.grace > 0s) {
      set req.http.grace = "full";
      return (deliver);
    } else {
      # no graced object.
      return (fetch);
    }
  }
}

sub vcl_backend_response {
  #set beresp.http.X-Fetch-Debug = "ttl: "+beresp.ttl+" restart: "+beresp.restarts;
  if (beresp.http.Cache-Control ~ "no-cache" || beresp.http.Cache-Control ~ "must-revalidate") {
      #this was a no-cache request!
      set beresp.http.X-Manually-Refreshed = 1;
      set beresp.ttl = 120s;
    } else if ( !(beresp.http.Cache-Control ~ "private" || beresp.http.Authorization || beresp.http.Set-Cookie) &&
      beresp.ttl < 15s ) {
    #not private but still not cacheable -> we don't trust the backend
    set beresp.ttl = 15s;
  }
}

sub vcl_deliver {
  #set resp.http.X-Deliver-Debug = "restarts: "+req.restarts+", hits: "+obj.hits;
  if (resp.http.X-Manually-Refreshed) {
    unset resp.http.X-Manually-Refreshed;
  }
}

sub vcl_hash {
  # URL and hostname/IP are the default components of the vcl_hash
  # implementation. We add more below.
  hash_data(req.url);
  if (req.http.host) {
      hash_data(req.http.host);
  } else {
      hash_data(server.ip);
  }

  # Include the X-Forward-Proto header, since we want to treat HTTPS
  # requests differently, and make sure this header is always passed
  # properly to the backend server.
  if (req.http.X-Forwarded-Proto) {
    hash_data(req.http.X-Forwarded-Proto);
  }

  return (lookup);
}

sub vcl_pipe {
  # https://www.varnish-software.com/blog/using-pipe-varnish
  set bereq.http.Connection = "Close";
  # Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
  if (req.http.upgrade) {
    set bereq.http.upgrade = req.http.upgrade;
  }
  return (pipe);
}


sub vcl_synth {
  if (resp.status == 750) {
    set resp.http.Location = resp.reason;
    set resp.status = 301;
    return(deliver);
  }
}

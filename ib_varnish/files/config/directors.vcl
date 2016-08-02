# this is just an example how you could loadbalance
# backends using directors
sub vcl_init {
  new dir_www_immerda_ch_80 = directors.round_robin();
  dir_www_immerda_ch_80.add_backend(www_immerda_ch_80);
}

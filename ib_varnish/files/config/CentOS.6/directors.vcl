# this is just an example how you could loadbalance
# backends using directors
irector dir_www_immerda_ch_80 round-robin {
  {
    .backend = www_immerda_ch_80;
  }
}


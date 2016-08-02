# this file is mainly here as
# an example and to get the default config
# running.
backend www_immerda_ch_80 {
  .host = "212.103.72.234";
  .port = "80";
  .probe = {
    .url = "/";
    .timeout = 1s;
    .interval = 10s;
    .window = 10;
    .threshold = 8;
  }
}

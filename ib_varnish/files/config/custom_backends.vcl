backend localhost_80 {
  .host = "127.0.0.1";
  .port = "80";
  .probe = {
    .url = "/";
    .timeout = 1s;
    .interval = 10s;
    .window = 10;
    .threshold = 8;
  }
}


probe healthcheck {
  .url = "/check.html";
  .interval = 5s;
  .timeout = 1s;
  .window = 5;
  .threshold = 3;
  .expected_response = 200;
}

backend default {
  .host = "localhost";
  .port = "8000";
  .connect_timeout = 600s;
  .first_byte_timeout = 600s;
  .between_bytes_timeout = 600s;
  .max_connections = 800;
  .probe = healthcheck;
}

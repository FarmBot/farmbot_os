defmodule TestRouter do
  require Plug.Router
  use Plug.Router
  plug CORSPlug
  plug Plug.Parsers, parsers: [:urlencoded, :json],
                     pass:  ["text/*"],
                     json_decoder: Poison
  plug :match
  plug :dispatch
  def test_key do
    "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzXxHfRyMjsl6s4RMn/T3\nRaKWax8wRhKfVkkrbE7uAtRMlRmvLMlOPGQTD6E+CrhqknGwFiXBy9hfhs9aPBPX\nhhZfI/2QZok4lxvIK7gQzYfF9E5VZWRbv7MjvyVWkqOf1Ab9jTOefvyZL39EgIrM\n9d1g5qPc/a4TBJnrJas1/IzfSZhvFCHYQ7SaONo6UqhkqP+JOOFBXfxYiWP02U1p\nQ253g8Vnu5LjQBQJHkIQQ3jZjQw1ArhP7BM09gINVjyU+igSL+64qH3D5/jjMswv\nd0z9hRA7uCoLQIcbVCfQXQRITCjbVmvM/P3NRuxUtARD/9ZHXokOg0DsnWC1ljpx\ncQIDAQAB\n-----END PUBLIC KEY-----\n"
  end

  def test_token do
     "{\"token\":{\"unencoded\":{\"sub\":\"admin@admin.com\",\"iat\":1475157438,\"jti\":\"264e86bd-41ad-45df-a5ce-f9afbd951e10\",\"iss\":\"http://localhost:3000\",\"exp\":1475503038,\"mqtt\":\"192.168.29.154\",\"bot\":\"856b27df-65b5-4089-be55-c2c7aab17837\"},\"encoded\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbkBhZG1pbi5jb20iLCJpYXQiOjE0NzUxNTc0MzgsImp0aSI6IjI2NGU4NmJkLTQxYWQtNDVkZi1hNWNlLWY5YWZiZDk1MWUxMCIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6MzAwMCIsImV4cCI6MTQ3NTUwMzAzOCwibXF0dCI6IjE5Mi4xNjguMjkuMTU0IiwiYm90IjoiODU2YjI3ZGYtNjViNS00MDg5LWJlNTUtYzJjN2FhYjE3ODM3In0.h9j2X9WKuMvox491W2-GSpCB3OriH9BF60cxwbmst8Lo3XUbnP0wVmOCL6fQgvjJRWYGhYojrIjK5sLAeUyQ3SSh1PZrPwhBtw4eSnjCZ8iTRHur5TWui-9221k9JSpe5anYPn6fzkAM25-x1txf39T1M6ddf8UWmTNp7v-VW-byS2hqg3RWWllOzTE8GpVO5ZIdAr_ZnP8NpJxmQezlC45Vo6elnl5RzOho8xpX-OIeL2KNe3eO3cIcptSQ7kvl2Rlwha3tx2ahFOxBdRz9THj96I7rHXvWTqql7nuyvOkGMTFyUT2GeIw4vrghTgSLKoyC2jN9lJ7xgDaRr53cKw\"}}"
  end

  get "/api/public_key" do
    send_resp(conn, 200, test_key)
  end

  post "/api/tokens" do
    send_resp(conn, 200, test_token)
  end

  match _ do
    send_resp(conn, 404, "Whatever you did could not be found.")
  end
end

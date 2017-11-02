defmodule Farmbot.System.DebugRouter do
  use Plug.Router

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :farmbot
  end
  plug(Plug.Logger, log: :debug)
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart])
  plug(:match)
  plug(:dispatch)

  forward "/wobserver", to: Wobserver.Web.Router

  get "/socket_test" do
    html = """
    <html>
      <body>
      <script>
        var token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJib3QiLCJzdWIiOjIsImlhdCI6MTUwOTU2MjY2NywianRpIjoiNzk1NTFjMWMtYjUzNi00YzUyLWE4ODYtYjIwMDhlZDJiMDE5IiwiaXNzIjoiLy8xOTIuMTY4LjI5LjE2NTozMDAwIiwiZXhwIjoxNTEzMDE4NjY3LCJtcXR0IjoiMTkyLjE2OC4yOS4xNjUiLCJtcXR0X3dzIjoid3M6Ly8xOTIuMTY4LjI5LjE2NTozMDAyL3dzIiwib3NfdXBkYXRlX3NlcnZlciI6Imh0dHBzOi8vYXBpLmdpdGh1Yi5jb20vcmVwb3MvZmFybWJvdC9mYXJtYm90X29zL3JlbGVhc2VzL2xhdGVzdCIsImZ3X3VwZGF0ZV9zZXJ2ZXIiOiJERVBSRUNBVEVEIiwiYm90IjoiZGV2aWNlXzIifQ.coMXH40kr9K6tKAVzxZUmE2arq5g_bPyf0VzbEkSyeTmniTN6y2XDVdppIsee8ScQfx8h5EBi7jUYYIdeFp7_zofiq9n-twEPrF6a9kqyEPV8TshjaJb6zfJSby1JyOS0sd3acnvwOziVCPr64eHU_aFSWcVIAi6-YJryCdJ6kCdNC-Se1aA7gJhg0M8curq2Eh7BRD2jH7sJxqxrMiWT89FBSuUNv9lxBVIs40WbRElJGZaoZHV_R4pVC47dGuqX2VDCIa7HHU0ZDtI0FOkWZCVvfJgHh2EJdrpitrPz3Ev_dz4zuLB9N4fPoxmmtGn_GUR9KobiyFpCoiRg3zrhg"
        var socket = new WebSocket("ws://" + token + "@localhost:27347/ws")
        socket.onmessage = function (event) {
          console.log(JSON.parse(event.data));
        }
      </script>
      </body>
    </html>
    """
    send_resp(conn, 200, html)
  end

  match(_, do: send_resp(conn, 404, "Page not found"))

end

# AwsExample

Example Elixir app trying to connect to AWS IoT via tortoise.

Uses a custom tortoise to get security information for analyses purposes.

Here's the diff for tortoise

```diff
diff --git a/lib/tortoise/connection.ex b/lib/tortoise/connection.ex
index d8a2a86..3cacc38 100644
--- a/lib/tortoise/connection.ex
+++ b/lib/tortoise/connection.ex
@@ -581,8 +581,13 @@ defmodule Tortoise.Connection do
   defp do_connect(server, %Connect{} = connect) do
     %Transport{type: transport, host: host, port: port, opts: opts} = server
 
-    with {:ok, socket} <- transport.connect(host, port, opts, 10000),
-         :ok = transport.send(socket, Package.encode(connect)),
+    {:ok, socket} = transport.connect(host, port, opts, 10000)
+    {:ok, info} = :ssl.connection_information(socket, [:keylog])
+    [keylog_contents] = Keyword.get(info, :keylog)
+
+    File.write("/tmp/keylog", "#{keylog_contents}\n", [:append])
+
+    with :ok = transport.send(socket, Package.encode(connect)),
          {:ok, packet} <- transport.recv(socket, 4, 5000) do
       try do
         case Package.decode(packet) do
@@ -616,6 +621,7 @@ defmodule Tortoise.Connection do
       {:error, other} ->
         {:error, other}
     end
+    |> IO.inspect()
   end
 
   defp init_connection(socket, %State{opts: opts, server: transport, connect: connect} = state) do
```

Basically calls `:ssl.connection_info(socket, [:keylog])` and then writes those values to
`/tmp/kelog`.


The format of that file is a valid master-secret keylog file for Wireshare to
decrypt TLS/SSL trace.



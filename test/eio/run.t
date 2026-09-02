  $ frame() { printf 'Content-Length: %d\r\n\r\n%s' "$(printf '%s' "$1" | wc -c)" "$1"; }

  $ frame '{"jsonrpc":"2.0","id":1,"method":"echo", "params": {"message": "foobar", "shout": true}}' | ./bin/eio_server.exe | sed 's/\r/<CR>/g'
  Content-Length: 42<CR>
  <CR>
  {"jsonrpc":"2.0","id":1,"result":"FOOBAR"}


  $ { frame '{"jsonrpc":"2.0","id":1,"method":"ping"}'
  >   frame '{"jsonrpc":"2.0","method":"ping"}'
  >   frame '{"jsonrpc":"2.0","id":3,"method":"ping"}'
  >   frame '{"jsonrpc":"2.0","id":4,"method":"echo", "params": {"message": "FOO"}}'
  >   frame '{"jsonrpc":"2.0","id":5,"method":"echo", "params": {"message": "FOO", "shout": true}}'
  > } | ./bin/eio_server.exe | sed 's/\r/<CR>/g'
  Content-Length: 40<CR>
  <CR>
  {"jsonrpc":"2.0","id":1,"result":"pong"}Content-Length: 43<CR>
  <CR>
  {"jsonrpc":"2.0","id":null,"result":"pong"}Content-Length: 40<CR>
  <CR>
  {"jsonrpc":"2.0","id":3,"result":"pong"}Content-Length: 39<CR>
  <CR>
  {"jsonrpc":"2.0","id":4,"result":"FOO"}Content-Length: 39<CR>
  <CR>
  {"jsonrpc":"2.0","id":5,"result":"FOO"}


  $ { frame '{"jsonrpc":"2.0","id":1,"method":"ping"}'
  >   frame '{"jsonrpc":"2.0","method":"ping"}'
  >   frame '{"jsonrpc": "wrong"}'
  >   frame '{"jsonrpc":"2.0","id":3,"method":"ping"}'
  >   frame '{"jsonrpc":"2.0","id":4,"method":"echo", "params": {"message": "FOO"}}'
  >   frame '{"jsonrpc": "2.0", "id": 5, "method": "do not exists"}'
  >   frame '{"jsonrpc":"2.0","id":6,"method":"echo", "params": {"message": "FOO", "shout": true}}'
  >   frame '{"jsonrpc":"2.0","id":6,"method":"echo", "params": {"typo": "FOO", "shout": true}}'
  > } | ./bin/eio_server.exe | sed 's/\r/<CR>/g'
  Content-Length: 40<CR>
  <CR>
  {"jsonrpc":"2.0","id":1,"result":"pong"}Content-Length: 43<CR>
  <CR>
  {"jsonrpc":"2.0","id":null,"result":"pong"}Content-Length: 371<CR>
  <CR>
  {"jsonrpc":"2.0","id":null,"error":{"code":-32600,"message":"Invalid request","body":"{\"jsonrpc\": \"wrong\"}","data":{"message":"Invalid list","errors":[{"field":"method","message":"Missing field","aliases":[]},{"field":"jsonrpc","message":"Invalid field","error":{"message":"`2.0` is not equal to `wrong`","value":"wrong"},"aliases":[]}],"value":{"jsonrpc":"wrong"}}}}Content-Length: 40<CR>
  <CR>
  {"jsonrpc":"2.0","id":3,"result":"pong"}Content-Length: 39<CR>
  <CR>
  {"jsonrpc":"2.0","id":4,"result":"FOO"}Content-Length: 143<CR>
  <CR>
  {"code":-32601,"message":"Method not found","body":"{\"jsonrpc\": \"2.0\", \"id\": 5, \"method\": \"do not exists\"}","data":["do not exists"]}Content-Length: 39<CR>
  <CR>
  {"jsonrpc":"2.0","id":6,"result":"FOO"}Content-Length: 292<CR>
  <CR>
  {"code":-32602,"message":"Invalid params","body":"{\"jsonrpc\":\"2.0\",\"id\":6,\"method\":\"echo\", \"params\": {\"typo\": \"FOO\", \"shout\": true}}","data":{"message":"Invalid list","errors":[{"field":"message","message":"Missing field","aliases":[]}],"value":{"typo":"FOO","shout":true}}}

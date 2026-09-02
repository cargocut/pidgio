  $ frame() { printf 'Content-Length: %d\r\n\r\n%s' "$(printf '%s' "$1" | wc -c)" "$1"; }

  $ frame '{"jsonrpc":"2.0","id":1,"method":"echo", "params": {"message": "foobar", "shout": true}}' | ./bin/unix_server.exe
  Start the server
  Content-Length: 42
  
  {"jsonrpc":"2.0","id":1,"result":"FOOBAR"}


  $ { frame '{"jsonrpc":"2.0","id":1,"method":"ping"}'
  >   frame '{"jsonrpc":"2.0","method":"ping"}'
  >   frame '{"jsonrpc":"2.0","id":3,"method":"ping"}'
  >   frame '{"jsonrpc":"2.0","id":3,"method":"echo", "params": {"message": "FOO"}}'
  >   frame '{"jsonrpc":"2.0","id":3,"method":"echo", "params": {"message": "FOO", "shout": true}}'
  > } | ./bin/unix_server.exe | sed 's/\r/<CR>/g'
  Start the server
  Content-Length: 40<CR>
  <CR>
  {"jsonrpc":"2.0","id":1,"result":"pong"}Content-Length: 43<CR>
  <CR>
  {"jsonrpc":"2.0","id":null,"result":"pong"}Content-Length: 40<CR>
  <CR>
  {"jsonrpc":"2.0","id":3,"result":"pong"}Content-Length: 39<CR>
  <CR>
  {"jsonrpc":"2.0","id":3,"result":"FOO"}Content-Length: 39<CR>
  <CR>
  {"jsonrpc":"2.0","id":3,"result":"FOO"}

  $ frame() { printf 'Content-Length: %d\r\n\r\n%s' "$(printf '%s' "$1" | wc -c)" "$1"; }

  $ {
  >   frame '{"jsonrpc":"2.0","method":"ls", "id": 1, "params": "/"}'
  >   frame '{"jsonrpc":"2.0","method":"cat", "id": 2, "params": "/non-existent"}'
  >   frame '{"jsonrpc":"2.0","method":"cat", "id": 3, "params": "/d/e/e3"}'
  >   frame '{"jsonrpc":"2.0","method":"cat", "id": 4, "params": "/a/a3/foo.txt"}'
  >   frame '{"jsonrpc":"2.0","method":"write/file", "params": ["/a/a3/hello.txt", "Just be created !"]}'
  >   frame '{"jsonrpc":"2.0","method":"cat", "id": 6, "params": "/a/a3/hello.txt"}'
  >   frame '{"jsonrpc":"2.0","method":"ls", "id": 7, "params": "/a/a3"}'
  >   frame '{"jsonrpc":"2.0","method":"write/file", "params": ["/root.txt", "at the root"]}'
  >   frame '{"jsonrpc":"2.0","method":"ls", "id": 8, "params": "/"}'
  >   frame '{"jsonrpc":"2.0","method":"cat", "id": 9, "params": "/root.txt"}'
  >   frame '{"jsonrpc":"2.0","method":"delete/file", "params": "/a"}'
  >   frame '{"jsonrpc":"2.0","method":"ls", "id": 10, "params": "/"}'
  >   frame '{"jsonrpc":"2.0","method":"delete/file", "params": "/root.txt"}'
  >   frame '{"jsonrpc":"2.0","method":"ls", "id": 11, "params": "/"}'
  > } | ./bin/fs_server.exe | sed 's/\r/<CR>/g'
  Content-Length: 55<CR>
  <CR>
  {"jsonrpc":"2.0","id":1,"result":["a/","b/","c/","d/"]}Content-Length: 81<CR>
  <CR>
  {"jsonrpc":"2.0","id":2,"result":"cat: /non-existent: No such file or directory"}Content-Length: 64<CR>
  <CR>
  {"jsonrpc":"2.0","id":3,"result":"cat: /d/e/e3: Is a directory"}Content-Length: 47<CR>
  <CR>
  {"jsonrpc":"2.0","id":4,"result":"Hello World"}Content-Length: 53<CR>
  <CR>
  {"jsonrpc":"2.0","id":6,"result":"Just be created !"}Content-Length: 57<CR>
  <CR>
  {"jsonrpc":"2.0","id":7,"result":["foo.txt","hello.txt"]}Content-Length: 66<CR>
  <CR>
  {"jsonrpc":"2.0","id":8,"result":["a/","b/","c/","d/","root.txt"]}Content-Length: 47<CR>
  <CR>
  {"jsonrpc":"2.0","id":9,"result":"at the root"}Content-Length: 62<CR>
  <CR>
  {"jsonrpc":"2.0","id":10,"result":["b/","c/","d/","root.txt"]}Content-Length: 51<CR>
  <CR>
  {"jsonrpc":"2.0","id":11,"result":["b/","c/","d/"]}


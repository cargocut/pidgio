(lang dune 3.24)
(name pidgio)
(version dev)
(generate_opam_files)

(source (github cargocut/pidgio))
(license BSD-3-Clause)

(authors
  "xvw <xaviervdw@gmail.com>"
  "grm <grimfw@gmail.com>")

(maintainers
  "d-plaindoux <d.plaindoux@free.fr>"
  "xhtmlboi <xhtmlboi@gmail.com>"
  "xvw <xaviervdw@gmail.com>"
  "msp <spawnmick@gmail.com>"
  "grm <grimfw@gmail.com>")

(package
  (name pidgio)
  (synopsis "Description of JSONRPC Servers on processes")
  (description
    "A tool for describing JSONRPC servers on processes that uses Pidgin as its format")
  (depends
    (ocaml (>= 5.0.0))
    pidgin))
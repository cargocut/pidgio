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
    (primavera (>= 1.1.0))
    (pidgin (>= 1.1.0))
    highway

    ;; test setup
    (alcotest (and :with-test (>= 1.9.1)))

    ;; dev setup
    (utop :with-dev-setup)
    (ocamlformat :with-dev-setup)
    (ocp-indent :with-dev-setup)
    (merlin :with-dev-setup)
    (ocaml-lsp-server :with-dev-setup)))

(package
  (name pidgio-yojson)
  (synopsis "Use YOJSON as a JSON driver for Pidgio servers")
  (description "Use YOJSON as a JSON driver for Pidgio servers")
    (depends
    (ocaml (>= 5.0.0))
    (pidgio (= :version))
    (yojson (>= 3.0.0))))

(package
  (name pidgio-unix)
  (synopsis "A pure UNIX Pidgio server")
  (description "A pure UNIX Pidgio server")
  (depends
    (ocaml (>= 5.0.0))
    (pidgio (= :version))
    (pidgio-yojson (and (= :version) :with-test))))

(package
  (name pidgio-eio)
  (synopsis "An EIO Pidgio server")
  (description "An EIO Pidgio server")
  (depends
    (ocaml (>= 5.0.0))
    (pidgio (= :version))
    (eio (>= 1.5))
    (eio_main (>= 1.5))
    (pidgio-yojson (and (= :version) :with-test))))
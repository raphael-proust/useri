Useri — Declarative user input for OCaml
-------------------------------------------------------------------------------
Release %%VERSION%%

Useri gathers user input as [React][react] signals and events. 

Useri can be used with different backends. The library comes
with a backend that depends on [Tsdl][tsdl] and a JavaScript backend 
that depends on [js_of_ocaml][jsoo].

Useri and its backends depend on [React][react] and [Gg][gg]. They are
distributed under the ISC license.

Home page: http://erratique.ch/software/useri  
Contact: Daniel Bünzli `<daniel.buenzl i@erratique.ch>`

[react]: http://erratique.ch/software/react
[gg]: http://erratique.ch/software/gg
[tsdl]: http://erratique.ch/software/tsdl
[jsoo]: http://ocsigen.org/js_of_ocaml/


## Installation

Useri can be installed with `opam`:

    opam install tsdl useri             # tsdl backend
    opam install js_of_ocaml useri      # js_of_ocaml backend
    opam install tsdl js_of_ocaml useri # all backends 

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.


## Documentation

The documentation and API reference is automatically generated by
`ocamldoc` from the interfaces. It can be consulted [online][doc]
or via or via `odig doc useri`
and there is a generated version in the `doc` directory of the 
distribution. 

[doc]: http://erratique.ch/software/useri/doc/Useri


## Sample programs

If you installed Fut with `opam` sample programs are located in
the directory `opam config var useri:doc`. 

In the distribution sample programs are located in the `test`
directory of the distribution. They can be built with:

    ocamlbuild -use-ocamlfind test/tests.otarget

The resulting binaries are in `_build/test`.

- `test.native` tests the library, nothing should fail.

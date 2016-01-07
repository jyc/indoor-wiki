# README

Indoor Wiki is a program you can use to browse Markdown files in a directory.
Maybe it's not a wiki in the sense that anyone can edit pages through the web
interface -- although the intended use case is one where people can edit the
Markdown files themselves in the same repo used for their code, so it's not
_that_ far off.

It's written as a demo for [ppx_sexp](https://bitbucket.org/jyc/ppx_sexp),
[sxmlm](https://bitbucket.org/jyc/sxmlm),
[ocaml-scgi](https://github.com/esperco/ocaml-scgi),
and OCaml as a platform for web
development.
It's also using it to experiment with how I think OCaml projects should be in
terms of style, organization, and infrastructure (e.g. the `mk` script).

You end up with pages that look like this:

![Listing.](https://bytebucket.org/jyc/indoor-wiki/raw/dc235e47d8e68b9557ae03387cee41ebabc996f1/static/img/listing.png)
![Welcome page.](https://bytebucket.org/jyc/indoor-wiki/raw/dc235e47d8e68b9557ae03387cee41ebabc996f1/static/img/welcome.png)

# Dependencies

Indoor Wiki has a few dependencies, most of which are managed through
[OPAM](https://opam.ocaml.org/). Some you will have to install manually.

## car

See the [car repository](https://github.com/jonathanyc/car).
car is a collection of aliases for building OCaml projects.

## ocaml-cmark

Run `hg clone https://github.com/jonathanyc/ocaml-cmark.git`
Then `opam pin add ocaml-cmark`

## sxmlm

Run `hg clone ssh://hg@bitbucket.org/jyc/sxmlm`.
Then `opam pin add sxmlm`

## nginx

Install nginx. On Arch Linux you can run `pacman -S nginx`. On OS X you can use
`brew install nginx`.

## ocaml-scgi

Run `git clone https://github.com/esperco/ocaml-scgi`.
Then `cd ocaml-scgi` and `make world`.

I had some problems building `ocaml-scgi` at the time of writing, for which I
made a pull request. If you have problems you can try my fork, and do `git
clone https://github.com/jonathanyc/ocaml-scgi` instead.  The only change is to
the `myocamlbuild.ml`.

# Building and installing

Run `opam pin add indoor-wiki .`.
The `opam` file specifies to OPAM how Indoor Wiki is to be built and installed.
If you are upgrading from a previous version you should be able to run `opam
upgrade indoor-wiki`.

# Running with an "embedded" Nginx

Run `indoor -port 8080`. This will automatically launch an Nginx server
configured to reverse proxy to an SCGI server (Indoor Wiki) at 8081.

# Running as a standalone SCGI server

Run `indoor -noembed -port 8080`. This will start Indoor Wiki serving SCGI on
port 8080.

# Developer documentation

I am working on adding developer documentation. It will be stored in the
`pages/` directory, for viewing with Indoor Wiki!

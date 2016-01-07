open Lwt
open Indoor_util

let static_access_path = assert_opt @@ Indoor_path.of_string "_"
let mathjax_src = "https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
let mathjax_host = "https://cdn.mathjax.org"

let validate_dir name path =
  let paths = Indoor_path.to_string path in
  if not (Sys.file_exists paths && Sys.is_directory paths) then begin
    Printf.fprintf stderr "indoor: Could not find %s at %s.\n" name paths ;
    exit 1
  end else ()

type t = {
  title : string;
  root_name : string;
  static_path : Indoor_path.t;
  wiki_path : Indoor_path.t;
  highlight : bool;
  mathjax : bool;
  links : (string * string) list;
}

let load path =
  let data = Toml.Parser.(unsafe @@ from_filename path) in
  let must name = function
    | None -> failwith @@ Printf.sprintf "Couldn't find '%s'." name
    | Some x -> x
  in
  let load f name = must name TomlLenses.(get data (key name |-- f)) in
  let load_string = load TomlLenses.string in
  let load_bool = load TomlLenses.bool in
  let links =
    TomlLenses.(get data (key "links" |-- array |-- tables))
    |> must "links"
    |> List.map (fun link ->
        assert_opt @@ TomlLenses.(get link (key "label" |-- string)),
        assert_opt @@ TomlLenses.(get link (key "to" |-- string)))
  in
  try
    { title = load_string "title";
      root_name = load_string "root_name";
      static_path = load_string "static_path" |> Indoor_path.of_string |> assert_opt;
      wiki_path = load_string "wiki_path" |> Indoor_path.of_string |> assert_opt;
      highlight = load_bool "highlight";
      mathjax = load_bool "mathjax";
      links }
  with e ->
    Printf.fprintf stderr "indoor: Error while loading configuration file: %s\n" (Printexc.to_string e);
    exit 1

let check { title; static_path; wiki_path } = 
  validate_dir "static directory" static_path ;
  validate_dir "wiki directory" wiki_path

let key = Lwt.new_key ()

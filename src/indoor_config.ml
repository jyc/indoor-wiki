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
  let table = Toml.Parser.from_filename path in
  let load_named f name table =
    match f name table with
    | x -> x
    | exception Not_found ->
      failwith (Printf.sprintf "Couldn't find '%s'." name)
  in
  let load_string = load_named (Toml.get_string & Toml.key) in
  let load_bool = load_named (Toml.get_bool & Toml.key) in
  let load_links table =
    let load_link table =
      load_string "label" table,
      load_string "to" table
    in
    Toml.Table.find (Toml.key "links") table
    |> Toml.to_table_array
    |> List.map load_link
  in
  try
    { title = table |> load_string "title";
      root_name = table |> load_string "root_name";
      static_path = table |> load_string "static_path" |> Indoor_path.of_string |> assert_opt;
      wiki_path = table |> load_string "wiki_path" |> Indoor_path.of_string |> assert_opt;
      highlight = table |> load_bool "highlight";
      mathjax = table |> load_bool "mathjax";
      links = table |> load_links }
  with e ->
    Printf.fprintf stderr "indoor: Error while loading configuration file: %s\n" (Printexc.to_string e);
    exit 1

let check { title; static_path; wiki_path } = 
  validate_dir "static directory" static_path ;
  validate_dir "wiki directory" wiki_path

let key = Lwt.new_key ()

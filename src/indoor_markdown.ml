open Batteries
open Lwt

open Indoor_util

exception Failed_to_load of string

let embed_re = Pcre.regexp {|(?<!\\)(?>\\\\)*\[%embed ((?:[^\]\\]|\\.)*)\]|}

let do_embeds s =
  let { Indoor_config.static_path } = get_key_exn Indoor_config.key in
  let subst s =
    match Pcre.extract ~rex:embed_re s with
    | [|_; path'|] ->
      begin match Indoor_path.of_string path' with
      | Some path ->
        (* This converting back and forth is kind of annoying.
           But to solve it, we would have to wrap a lot of standard library functions. *)
        let path = Indoor_path.(static_path / path) in
        if not (Indoor_path.exists path) then
          Printf.sprintf {|<span class="error">Failed to embed file at <code>%s</code>. No file found at path.|} path'
        else
          File.with_file_in Indoor_path.(!$ path) (fun inp ->
            IO.read_all inp
          )
      | None ->
        Printf.sprintf {|<span class="error">Failed to embed file at <code>%s</code>. Path is not relative.|} path'
      end
    | _ -> assert false
  in
  Pcre.substitute ~rex:embed_re ~subst s

let html_of_file path =
  File.with_file_in path (fun inp ->
    let s = IO.read_all inp in
    do_embeds s
    |> 
    Cmark.of_string ~flags:[`Normalize; `ValidateUTF8; `Smart]
    |> Cmark.to_html 
    |> return
  )

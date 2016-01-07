open Lwt

exception Failed_to_load 

let html_of_file path =
  match Cmark.of_file ~flags:[`Normalize; `ValidateUTF8; `Smart] path with
  | `Error s -> Lwt.fail Failed_to_load
  | `Ok md ->
    return @@ Cmark.to_html md

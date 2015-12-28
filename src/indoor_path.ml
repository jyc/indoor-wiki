type t = {
  (* [path] contains the full path. Its components are the terms separated by
     slashes. It never has any trailing slashes, or .., ., or empty
     components. The current directory is represented by ".". It is never empty. *)
  path : string;
  (* [parts] contains [path] split into its components. *)
  parts : string list;
  (* [basename] contains the last element of [parts], or "" if [parts] is
     empty. *)
  basename : string;
} [@@deriving show]

exception Path_exn of string

let cwd = { path = "."; parts = ["."]; basename = "." }

let slash_re =
  Re.(compile (char '/'))

let of_string s = 
  if s = "." || s = "" then Some cwd 
  else if s.[0] = '/' then None
  else
    let s =
      if s.[String.length s - 1] = '/' then
        String.sub s 0 (String.length s - 1)
      else s
    in
    let parts = Re.split slash_re s in
    let is_invalid_component = function
      | "" -> true
      | ".." -> true
      | "." -> true
      | s -> false
    in
    if List.exists is_invalid_component parts then None
    else
      Some { path = s;
             parts;
             basename = List.hd (List.rev parts) }

let to_string { path } =
  path
let (!$) = to_string

let append a b =
  match a.path, b.path with
  (* Special case for the CWD paths. *)
  | ".", "." -> a
  | ".", _ -> b
  | _, "." -> a
  | _ ->
    { path = a.path ^ "/" ^ b.path;
      parts = a.parts @ b.parts;
      basename = b.basename }

let (/) = append

let appends a b =
  if a.path = "." then b
  else a.path ^ "/" ^ b

let (/$) = appends

let basename { basename } =
  basename

let parts { parts } =
  parts

let inside a b =
  let rec inside' xs ys =
    match xs, ys with
    | x :: xs, y :: ys ->
      if x = y then inside' xs ys
      else false
    | [], _ :: _ ->
      true
    | _ :: _, [] ->
      false
    | [], [] ->
      true
  in inside' a.parts b.parts

let relative root path =
  let rec loop xs ys =
    match xs, ys with
    | x :: xs, y :: ys ->
      if x = y then loop xs ys
      else None
    | [], parts ->
      Some { path = String.concat "/" parts ;
             parts ;
             basename = path.basename }
    | _ :: _, _ ->
      None
  in loop root.parts path.parts

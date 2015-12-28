open Indoor_util

type frag = frag Xmlm.frag

(** HtmlEscape is a module for escaping HTML against XSS. See
    https://www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet *)
module HtmlEscape = struct
  let amp = BatUChar.of_char '&'
  let lt = BatUChar.of_char '<'
  let gt = BatUChar.of_char '>'
  let quot = BatUChar.of_char '"'
  let squot = BatUChar.of_char '\''
  let fslash = BatUChar.of_char '/'

  (** [content s] returns the untrusted string [s] escaped for insertion into an
      HTML element's content.
      Raises [Malformed_code] (from [BatUTF8.validate]) if [s] is not valid
      UTF-8. *)
  let content s =
    let () = BatUTF8.validate s in
    let out = BatUTF8.Buf.create 128 in
    let adds = BatUTF8.Buf.add_string out in
    BatUTF8.iter
      (fun c ->
         if BatUChar.(eq c amp) then adds "&amp;"
         else if BatUChar.(eq c lt) then adds "&lt;"
         else if BatUChar.(eq c gt) then adds "&gt;"
         else if BatUChar.(eq c quot) then adds "&quot;"
         else if BatUChar.(eq c squot) then adds "&#x27;"
         else if BatUChar.(eq c fslash) then adds "&#x2F;"
         else BatUTF8.Buf.add_char out c)
      s ;
    BatUTF8.Buf.contents out

  (** [hexencode c] returns the "&#xHH;" sequence for [c], a UTF-8 character. *)
  let hexencode c =
    Printf.sprintf "&#x%x;" (BatUChar.code c)

  (* Raises [Malformed_code] (from [BatUTF8.validate]) if [s] is not valid
     UTF-8. *)
  let escape_ascii s =
    let () = BatUTF8.validate s in
    let out = BatUTF8.Buf.create 128 in
    BatUTF8.iter
      (fun c ->
         let code = BatUChar.code c in
         (* Escape all characters whose codes are < 256 and are not alphanumeric. *)
         if code < 256 &&
            not ((code >= 65 && code <= 90) || (* A-Z *)
                 (code >= 97 && code <= 122) || (* a-z *)
                 (code >= 48 && code <= 57)) (* 0-9 *)
         then
           BatUTF8.Buf.add_string out (hexencode c)
         else BatUTF8.Buf.add_char out c)
      s ;
    BatUTF8.Buf.contents out

  (** [attribute s] returns the untrusted string [s] escaped for insertion into
      an HTML element's attribute value. *)
  let attribute =
    escape_ascii

end

let string_of_xmlm x =
  let out = Buffer.create 1024 in
  let adds = Buffer.add_string out in

  let rec encode raw =
    let encode_name ns tag =
      match ns, tag with
      | _, "" -> invalid_arg "Names cannot have empty local elements."
      | "", _ -> adds tag
      | _ -> adds ns ; adds ";" ; adds tag
    in

    (* "Attribute values are a mixture of text and character references..."
       -- http://www.w3.org/TR/html51/syntax.html#attributes-2 *)
    let encode_attr ((ns, tag), value) =
      encode_name (if ns = "RAW" then "" else ns) tag ;
      if value <> "" then begin
        adds "=\"" ;
        adds (if raw || ns = "RAW" then value
              else HtmlEscape.attribute value) ;
        adds "\""
      end else ()
    in

    (* "Escapable raw text elements can have text and character references..."
       "Normal elements can have text, character references..."
       --- http://www.w3.org/TR/html51/syntax.html
       This should cover rules #1 (HTML content), #2, (HTML attributes),
       and #5 (URL escaping).
       This does not cover JavaScript, CSS, and URL protocol escaping. *)
    function
    | `Data s -> adds (if raw then s else HtmlEscape.content s)
    | `El (((ns, tag), attrs), children) ->
      if (ns, tag) = ("", "RAW") then begin
        if attrs <> [] then invalid_arg "Raw elements must not have any attributes."
        else List.iter (encode true) children
      end else begin
        adds "<" ;
        encode_name ns tag ;
        match attrs, children with
        (* <tag attrs /> *)
        | _, [] ->
          adds " " ;
          List.iter
            (fun attr ->
               encode_attr attr ;
               adds " ")
            attrs ;
          adds "/>"
        (* <tag attrs>children</tag> *)
        | _, _ ->
          List.iter
            (fun attr ->
               adds " " ;
               encode_attr attr)
            attrs ;
          adds ">" ;
          List.iter (encode raw) children ;
          adds "</" ;
          encode_name ns tag ;
          adds ">"
      end
  in
  let () = encode false x in
  Buffer.contents out

let html_of_sxml s =
  "<!DOCTYPE html>" ^
  string_of_xmlm (Sxmlm.xmlm_of_sexp s)

let string_of_char = String.make 1
let rec string_of_atom (x : PpxSexp.sexp) : string =
  match x with
  | `Char x -> string_of_char x
  | `Float x -> x
  | `Symbol x -> x
  | `Int x -> string_of_int x
  | `Int32 x -> Int32.to_string x
  | `Int64 x -> Int64.to_string x
  | `Nativeint x -> Nativeint.to_string x
  | `String x -> x
  | `Bool true -> "true"
  | `Bool false -> "false"
  | `List _ -> invalid_arg ("Expected atom, received list: " ^ (string_of_sexp x))
and string_of_sexp x =
  match x with
  | `String x -> "\"" ^ x ^ "\""
  | `List xs -> "(" ^ (String.concat " " (List.map string_of_sexp xs)) ^ ")"
  | _ -> string_of_atom x

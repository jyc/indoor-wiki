open Lwt

let lt = BatUChar.of_char '<'
let gt = BatUChar.of_char '>'

(* Less restrictive than Indoor_html's escaping because at least here the
   Markdown files are presumably coming form the same organization as the
   person who is running the wiki. We want them to be able to write things like
   &mdash; but not to accidentally forget to close a tag. *)
let escape s = 
  let () = BatUTF8.validate s in
  let out = BatUTF8.Buf.create 128 in
  let adds = BatUTF8.Buf.add_string out in
  BatUTF8.iter
    (fun c ->
       if BatUChar.(eq c lt) then adds "&lt;"
       else if BatUChar.(eq c gt) then adds "&lt;"
       else BatUTF8.Buf.add_char out c)
    s ;
  BatUTF8.Buf.contents out

let html_override = function
  | x -> None

let to_html (x : Omd.t) =
  (* HACK: Add the UTF-8 'zero-width space' character to the end to force Omd
     to not htmlentitize code blocks. We've already done what we wanted with
     [escape].

     In omd/src/Omd_backend.ml:
     {[| Code_block(lang, c) as e :: tl ->
         begin match override e with
           | Some s ->
             Buffer.add_string b s;
             loop indent tl
           | None ->
             (* ... *)
             let new_c = code_style ~lang:lang c in
             (* XXX This is why! *)
             if c = new_c then
               Buffer.add_string b (htmlentities ~md:false c)
             else
               Buffer.add_string b new_c;
             Buffer.add_string b "</code></pre>";
             loop indent tl
         end]}
  *)
  Omd.to_html ~override:html_override ~cs:(fun ~lang s -> s ^ "&#8203;") x

let html_of_file (file_name : string) : string Lwt.t =
  Lwt_io.with_file ~mode:Lwt_io.input file_name
    (fun chan ->
       Lwt_io.read chan
       >>= fun s ->
       escape s
       |> Omd.of_string
       |> to_html
       |> return)

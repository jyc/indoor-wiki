#!/usr/bin/env utop
#require "unix"

open Unix
open Printf

let src_dir = "src"

let log_commands = ref true

let with_log_commands x f =
  log_commands := x ;
  f () ;
  log_commands := not x

let run cmd =
  if !log_commands then
    print_endline cmd 
  else () ;
  match system cmd with
  | WEXITED 0 -> ()
  | WEXITED x ->
    fprintf Pervasives.stderr "\nCommand failed: '%s' exited with code %d.\n" cmd x ;
    exit 1
  | _ ->
    fprintf Pervasives.stderr "\nCommand failed: '%s' exited abnormally.\n" cmd ;
    exit 1

let ocb ?(quiet=false) cmd =
  if quiet then
    run ("ocamlbuild -quiet -use-ocamlfind " ^ cmd) 
  else
    run ("ocamlbuild -use-ocamlfind " ^ cmd) 

let mcase s =
  sprintf "%c%s"
    (Char.uppercase s.[0])
    (String.sub s 1 (String.length s - 1))

(** [check_prefix a b] returns true if [a] is a prefix of [b]. *)
let check_prefix a b =
  String.length a <= String.length b &&
  String.sub b 0 (String.length a) = a

let install path =
  run ("rm -rf ../" ^ path) ;
  run (sprintf "mv %s ../%s" path path)

let rules = [
  ("clean",
   (fun () ->
      ocb "-clean" ;
      run ("rm -f indoor_top.mltop") ;
      chdir ".." ;
      run ("rm -f main.native main.d.byte indoor_top.top indoor.docdir") ;
      chdir src_dir));
  ("debug",
   (fun () ->
      ocb "main.d.byte" ;
      install "main.d.byte"));
  ("prod",
   (fun () ->
      ocb "main.native" ;
      install "main.native"));
  ("mltop",
   (fun () ->
      let files =
        Sys.readdir "."
        |> Array.to_list
        |> List.filter (fun s -> Filename.check_suffix s ".ml")
        |> List.map Filename.chop_extension
      in
      let out = Buffer.create 128 in
      let och = open_out "indoor_top.mltop" in
      List.iter
        (fun file -> 
           Buffer.add_string out (mcase file ^ "\n"))
        files ;
      output_string och (Buffer.contents out) ;
      close_out och));
  ("top",
   (fun () ->
      ocb "indoor_top.top" ;
      install "indoor_top.top"));
  ("doc",
   (fun () ->
      ocb "indoor.docdir/index.html" ;
      install "indoor.docdir"));
  ("test",
   (fun () ->
      let test_files =
        Sys.readdir "."
        |> Array.to_list
        |> List.filter (fun s -> Filename.check_suffix s "_test.ml")
      in
      with_log_commands false
        (fun () ->
           List.iter
             (fun test ->
                let out = "./" ^ Filename.chop_extension test ^ ".d.byte" in
                printf "Testing: %s\n%!" test ;
                ocb ~quiet:true out ;
                run ({|OCAMLRUNPARAM="b" |} ^ out) ;
                run ("rm " ^ out))
             test_files)));
]

let rule name =
  match List.assoc name rules with
  | f ->
    printf "Rule: %s\n" name ;
    f ()
  | exception Not_found ->
    printf "No such rule: %s\n" name ;
    exit 1

let rule_all () =
  List.iter
    (fun (name, _) ->
       if name = "clean" then ()
       else begin
       rule name ;
       print_endline ""
    end)
    rules

let () = 
  chdir src_dir ;
  if Array.length Sys.argv = 1 then
    rule_all ()
  else
    rule Sys.argv.(1)

(* vim: set filetype=ocaml : *)

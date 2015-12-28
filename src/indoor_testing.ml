open Printf

let current_logs = ref []
let clear_logs () = current_logs := []

let log s =
  current_logs := s :: !current_logs

let test (name : string) (proc : unit -> unit) =
  clear_logs () ;
  try proc ()
  with
  | e ->
    fprintf stderr "Test '%s' threw an exception:\n  %s\n" name (Printexc.to_string e) ;
    fprintf stderr "\nBacktrace:\n" ;
    Printexc.print_backtrace stderr ;
    fprintf stderr "\nLogs:\n" ;
    if !current_logs = [] then
      fprintf stderr "  Empty.\n"
    else
      List.iteri
        (fun i x -> fprintf stderr "%d. %s\n" (i + 1) x)
        (List.rev !current_logs) ;
    flush stderr ;
    exit 1

let assert_eq a b =
  assert (a = b)

let test_eq name expected proc =
  test name (fun () -> assert_eq expected (proc ()))

let test_eqs name expected proc =
  test_eq name expected
    (fun () ->
       let s = proc () in
       log (sprintf "Got '%s'.\nExpected '%s'." s expected) ;
       s)

let assert_exn expected proc =
  try
    proc () ;
    log "Expected an exception, but none was thrown." ;
    assert false
  with 
  | e ->
    assert (e = expected)

let test_exn name expected proc =
  test name
    (fun () -> assert_exn expected proc)


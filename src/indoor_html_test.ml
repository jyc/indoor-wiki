open Indoor_html
open Indoor_testing
open Printf

let () =

  (* Tests for html_of_sxml. *)

  let test_html_of_sxml name expected sexp =
    test_eqs ("html_of_sxml: " ^ name) expected
      (fun () -> html_of_sxml sexp)
  in

  test_html_of_sxml "Test simple encoding."
    "<!DOCTYPE html><html><head><title>Hello, world!</title></head><body><h1>Hi there!</h1></body></html>"
    [%sexp (html (head (title "Hello, world!")) (body (h1 ("Hi there!"))))] ;

  test_html_of_sxml "Test escaping of element contents."
    "<!DOCTYPE html><html><head><title>&#x27;Hello&#x2F;, world!&lt;what&amp;is&gt;what&quot;</title></head><body></body></html>"
    [%sexp (html (head (title "'Hello/, world!<what&is>what\""))(body ""))] ;

  test_html_of_sxml "Test escaping of element attributes."
    {|<!DOCTYPE html><html lang="no&#x22;escape&#x20;"><head></head><body></body></html>|}
    [%sexp (html ((@) (lang "no\"escape ")) (head "")(body ""))] ;

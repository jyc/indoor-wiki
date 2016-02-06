open Indoor_path
open Indoor_util
open Indoor_testing
open Printf

let () = 

  test_eq "of_string: of_string returns None when given an absolute path."
    None
    (fun () -> of_string "/etc/passwd") ;

  test_eq "append: Simple test of trailing slash handling."
    "a/b/c"
    (fun () ->
       to_string (assert_opt (of_string "a/") / assert_opt (of_string "b/c/"))) ;

  test "inside: Simple tests."
    (fun () ->
       let abc = assert_opt @@ of_string "a/b/c" in
       let abb = assert_opt @@ of_string "a/b/b" in
       let abcd = assert_opt @@ of_string "a/b/c/d" in
       let ab = assert_opt @@ of_string "a/b" in

       assert (inside ab abc) ;

       assert (not (inside abb ab)) ;

       assert (inside abc abcd) ;
       assert (not (inside abcd abc))) ;

  test_eq "basename: Simple test."
    "hi.ml"
    (fun () -> basename @@ assert_opt @@ of_string "a/b/hi.ml") ;

  test "relative: Simple tests."
    (fun () ->
       let abc = assert_opt @@ of_string "a/b/c" in
       let abb = assert_opt @@ of_string "a/b/b" in
       let abcd = assert_opt @@ of_string "a/b/c/d" in

       assert (relative abc abb = None) ;
       assert (relative abc abcd = of_string "d")) ;

  test "CWD: properties"
    (fun () ->
       let cwd' = assert_opt @@ of_string "" in
       assert (cwd' = cwd) ;
       assert (cwd' / cwd = cwd) ;
       assert (parts cwd' = []) ;
       assert (basename cwd' = "") ;
       assert (to_string cwd' = ".")) ;

  ()

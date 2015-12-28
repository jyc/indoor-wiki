open Indoor_util
open Indoor_testing

let () =

  test "intersperse: Simple tests."
    (fun () ->
       assert (intersperse 0 [1; 2; 3] = [1; 0; 2; 0; 3]) ;
       assert (intersperse ~tail:true 0 [1; 2; 3] = [1; 0; 2; 0; 3; 0])) ;

  test "split: Simple tests."
    (fun () ->
       assert_eq
         ([2; 4], [1; 3; 5])
         (split
            (fun x ->
               if x mod 2 = 0 then `Left x
               else `Right x)
            [1; 2; 3; 4; 5])) ;

  test "drop: Simple tests."
    (fun () ->
       assert (drop 0 [1; 2; 3] = [1; 2; 3]) ;
       assert (drop 2 [1; 2; 3] = [1])) ;

  test "has_suffix: Simple tests."
    (fun () ->
       assert (has_suffix "fgh" "abcdefgh") ;
       assert (not (has_suffix "fgh" "abcdefg"))) ;

       (* These shouldn't throw exceptions! *)
       assert (has_suffix "" "abc") ;
       assert (not (has_suffix "abcdefg" "abc")) ;

  test "ensure_suffix: Simple tests."
    (fun () ->
       assert (ensure_suffix ".ml" "test.ml" = "test.ml") ;
       assert (ensure_suffix ".ml" "test" = "test.ml")) ;

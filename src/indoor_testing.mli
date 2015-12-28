val log : string -> unit

val test : string -> (unit -> unit) -> unit

val assert_eq : 'a -> 'a -> unit
val test_eq : string -> 'a -> (unit -> 'a) -> unit
val test_eqs : string -> string -> (unit -> string) -> unit

val assert_exn : exn -> (unit -> unit) -> unit
val test_exn : string -> exn -> (unit -> unit) -> unit


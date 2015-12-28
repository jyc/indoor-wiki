(* Convenience operators *)

(* Different than @@ (from Pervasives). This should be used to chain functions
   to come up with a new function, whereas @@ is used to just evaluate
   right-to-left instead of left-to-right.

   You could use @@ to change
     f (g (h x))    (1)
   into
     f @@ g @@ h x    (2)

   And you could use & to change
     (fun x -> f (g (h x)))   (3)
   into
     f & g & h    (4)
     
   Why can't we just use all @@ or all & ?
   Well we can't use @@ in (4) because you can't give 'a -> 'b the value 'c ->
   'a and get 'c -> 'b (it expects 'a, not a function!)
   And you can't use & in (2) because & has lower precedence than function
   application, and what you'll end up getting is
     f & g & (h x)    (5)
   ... and (h x) is not a function.

   To use one for both (like \circ in math!) we would need to have a
   right-associative infix operator with higher precedence than function
   application. But as you can see there is no such operator in OCaml.
   http://caml.inria.fr/pub/docs/manual-ocaml/expr.html#sec138

   So use @@ when you have an x and &* when you don't. *)
val (&) : ('a -> 'b) -> ('c -> 'a) -> 'c -> 'b

(* Strings *)

val has_suffix : string -> string -> bool
val ensure_suffix : string -> string -> string

(* Lwt *)

val get_key_exn : 'a Lwt.key -> 'a

(* Lists *)

val drop : int -> 'a list -> 'a list
val intersperse : ?tail:bool -> 'a -> 'a list -> 'a list

(** Like List.partition, but with the option of discarding elements. The order
    of elements is preserved. Tail-recursive. *)
val split : ('a -> [`Left of 'b | `Right of 'c | `Discard]) -> 'a list -> 'b list * 'c list

(* Options *)

val assert_opt : 'a option -> 'a

(* Combinators *)

val negate : bool -> bool

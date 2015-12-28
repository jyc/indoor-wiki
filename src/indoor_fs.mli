type tree = 
  | Directory of Indoor_path.t * tree list
  | File of Indoor_path.t

val tree : ?depth:int -> pred:(Indoor_path.t -> bool) -> Indoor_path.t -> tree list

val pp_tree : Format.formatter -> tree -> unit
val show_tree : tree -> string

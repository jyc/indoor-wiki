(** [Indoor_path] is used to handle relative filesystem paths.
    The goal is to provide lightweight assurances about the structure of the
    path, like about whether a path begins (it shouldn't) or ends with a
    trailing slash. These assurances are enforced through the operators on
    paths. Eventually it's expected that a path will be converted back to its
    string representation, at which point the assurances will hopefully come in
    handy.
    It is NOT intended for general path handling, only for the kind of paths
    handled by Indoor (i.e. paths in the URL used to access resources in the
    filesystem).
*)

(** [t] represents a relative filesystem path. Its string representation will
    never begin or end with a trailing slash, and it will never contain ".",
    "..", or empty components (words between slashes). It can be "." only, in
    which case it represents the current directory. *)
type t

exception Path_exn of string

val cwd : t

(** [of_string s] returns the path represented by [s], if [s] is valid. To be
    valid, [s] must be a relative path (it must not begin with a trailing
    slash), and must not contain any of the following components: "..", ".", or
    "".
    Special handling:
    - "" is converted to ".", which represents the current directory.
    - At most one trailing slash is removed. *)
val of_string : string -> t option

(* Concatenation *)
val append : t -> t -> t
val (/) : t -> t -> t

val appends : t -> string -> string
val (/$) : t -> string -> string

(* Accessors *)

(** [to_string p] returns the path [p] as a string. *)
val to_string : t -> string
val (!$) : t -> string

val basename : t -> string
val parts : t -> string list

(* Comparisons *)

(** [inside a b] returns true when [b] is inside [a]. *)
val inside : t -> t -> bool
val relative : t -> t -> t option

(* ppx_deriving show *)

val pp : Format.formatter -> t -> unit
val show : t -> string

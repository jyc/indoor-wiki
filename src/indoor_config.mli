open Lwt

val static_access_path : Indoor_path.t
val mathjax_src : string
val mathjax_host : string

type t = {
  title : string;
  root_name : string;
  static_path : Indoor_path.t;
  wiki_path : Indoor_path.t;
  highlight : bool;
  mathjax : bool;
  (** [links] is a list of links to show in the menu bar. Each tuple has
      the form [(label, to)]. *)
  links : (string * string) list;
}

val load : string -> t
val check : t -> unit

val key : t Lwt.key

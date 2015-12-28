open Indoor_util

type tree = 
  | Directory of Indoor_path.t * tree list
  | File of Indoor_path.t
[@@deriving show]

let tree ?depth ~pred root =
  let rec read_dir' ?depth fs_root root =
    match depth with
    | Some d when d <= 0 -> Directory (root, [])
    | None | Some _ ->
      let entries =
        let files_arr = Sys.readdir (Indoor_path.to_string fs_root) in
        let () = Array.sort String.compare files_arr in
        Array.to_list files_arr
        |> List.map (assert_opt & Indoor_path.of_string)
      in
      let depth' =
        match depth with
        | Some d -> Some (d - 1)
        | None -> None
      in
      let dirs, files =
        Indoor_util.split
          (fun entry ->
             let path = Indoor_path.(!$ (fs_root / entry)) in
             (* This is possible. Not sure why. *)
             if not (Sys.file_exists path) then `Discard
             else if Sys.is_directory path then `Left entry
             else if pred entry then `Right entry
             else `Discard)
          entries
      in
      Directory (root, List.map (fun s -> File Indoor_path.(root / s)) files @
                       List.map (fun d -> read_dir' ?depth:depth' Indoor_path.(fs_root / d) Indoor_path.(root / d)) dirs)
  in
  match read_dir' ?depth root Indoor_path.cwd with
  | Directory (_, fs) -> fs
  | _ -> failwith "Invalid state."

let (&) f g x = f (g x)

let get_key_exn key =
  match Lwt.get key with
  | None -> failwith "Undefined key."
  | Some x -> x

let drop n ls =
  let rec drop' n ls =
    if n = 0 then ls
    else match ls with
      | h :: tl -> drop' (n - 1) tl
      | [] -> []
  in List.rev (drop' n (List.rev ls))

let rec intersperse ?(tail=false) d ls =
  let rec intersperse' acc xs =
    match xs with
    | a :: b :: [] ->
      if tail then List.rev acc @ [a; d; b; d]
      else [a; d; b]
    | a :: b :: xs ->
      intersperse' (d :: b :: d :: a :: acc) xs
    | x :: [] ->
      if tail then List.rev acc @ [x; d]
      else List.rev acc @ [x]
    | [] ->
      failwith "Invalid state."
  in intersperse' [] ls

let split f xs =
  let rec split' f xs bs cs =
    match xs with
    | [] -> bs, cs
    | x :: xs ->
      begin match f x with
        | `Left b -> split' f xs (b :: bs) cs
        | `Right c -> split' f xs bs (c :: cs)
        | `Discard -> split' f xs bs cs
      end
  in
  let (bs, cs) = split' f xs [] [] in
  (List.rev bs, List.rev cs)

let has_suffix suffix target =
  let sn = String.length suffix in
  let tn = String.length target in
  if tn < sn then false
  else String.sub target (tn - sn) sn = suffix

let ensure_suffix suffix target =
  if has_suffix suffix target then target
  else (target ^ suffix)

let assert_opt x =
  match x with
  | Some x' -> x'
  | None -> failwith "[assert_opt x] expected [x] to be [Some x'] but got [None]."

let negate x = not x


open Lwt
open Indoor_html
open Indoor_util

let csp_report_path = "csp_report"
let output_csp_reports = ref false

let return_html status body =
  let { Indoor_config.mathjax } = get_key_exn Indoor_config.key in
  let headers = 
    [`Content_type "text/html; charset utf-8";
     (* The presence of inline source elements is disabled by the presence of the CSP header. *)
     `Other ("Content-Security-Policy",
             Printf.sprintf "default-src 'self'; report-uri /%s; script-src 'self'%s"
               csp_report_path
               (if mathjax then " " ^ Indoor_config.mathjax_host ^ "; style-src 'self' 'unsafe-inline'" else ""))]
  in
  return { Scgi.Response.
           status;
           headers;
           body = `String body }

let not_found () =
  return_html `Not_found "Not found"

let redirect where =
  return { Scgi.Response.
           status=`Moved_permanently;
           headers = [`Location where];
           body = `String "301 moved permanently" }

let respond_file path =
  let path' = Indoor_path.to_string path in
  Lwt_unix.stat path'
  >>= fun { Lwt_unix.st_kind; st_size } ->
  match st_kind with
  | Lwt_unix.S_DIR ->
    (* Return 404 for directories. *)
    not_found ()
  | _ ->
    Lwt_io.open_file ~mode:Lwt_io.input path'
    >>= fun ch ->
    let stream =
      Lwt_stream.from (fun () -> Lwt_io.read_char_opt ch)
    in
    let () =
      Lwt_stream.on_terminate stream (fun () -> ignore (Lwt_io.close ch))
    in
    return { Scgi.Response.
             status=`Ok;
             headers = [`Content_type (Magic_mime.lookup (Indoor_path.basename path) ^ "; charset utf-8")];
             body = `Stream (Some st_size, stream) }

let handle { Indoor_config.title; static_path; wiki_path } req =
  let ts = Sys.time () in
  let meth = Scgi.Request.meth req in
  let uri = Scgi.Request.uri req in
  (* We expect the first character [Uri.path uri] to be '/', as it comes from the HTTP request. *)
  let path' = String.sub (Uri.path uri) 1 (String.length (Uri.path uri) - 1) in
  let path = Indoor_path.of_string path' in

  let render_index ~(where:[`Root | `Indoor_path of Indoor_path.t]) =
    let parts, root =
      match where with
      | `Root -> [], wiki_path
      | `Indoor_path p -> Indoor_path.parts p, Indoor_path.(wiki_path / p)
    in
    let files =
      Indoor_fs.tree
        ~depth:1 ~pred:((has_suffix ".md") & Indoor_path.to_string)
        root
    in
    Indoor_template.index
      ~dt:(Sys.time () -. ts) ~dirs:parts
      ~files ~title:(if where = `Root then title else Indoor_path.(!$ root)) ()
    |> html_of_sxml
    |> return_html `Ok
  in

  match path with
  | None -> not_found ()
  | Some path ->
    let parts = Indoor_path.parts path in
    begin match meth, parts with
      (* Accessing / . *)
      | `GET, ["."] ->
        render_index ~where:`Root
      (* Accessing static files /_/... . *)
      | `GET, _ when Indoor_path.inside Indoor_config.static_access_path path ->
        (* Get rid of the leading /. Indoor_paths will look like static/... .*)
        let rel_path = assert_opt @@ Indoor_path.relative Indoor_config.static_access_path path in
        respond_file Indoor_path.(static_path / rel_path)
      (* Accessing a directory /a/b/.../c/ .*)
      | `GET, _ :: _ when has_suffix "/" path' ->
        let dir_path = Indoor_path.(!$ (wiki_path / path)) in
        if not (Sys.file_exists dir_path && Sys.is_directory dir_path) then not_found ()
        else render_index ~where:(`Indoor_path path)
      (* Accessing a Markdown file /a/b/.../c.md or /a/b/.../c . *)
      | `GET, (_ :: _ as ps) ->
        let file_name = ensure_suffix ".md" Indoor_path.(!$ (wiki_path / path)) in
        if not (Sys.file_exists file_name) then not_found ()
        else begin
          if not (has_suffix ".md" path') then
            redirect (Uri.of_string @@ Printf.sprintf "/%s.md" path')
          else
            Indoor_markdown.html_of_file file_name
            >>= fun contents ->
            Indoor_template.page
              ~dirs:(drop 1 ps) ~title:(ensure_suffix ".md" (Indoor_path.basename path))
              ~contents
            |> html_of_sxml
            |> return_html `Ok
        end
      (* Print CSP violations report. *)
      | `POST, [csp_report_path] ->
        let contents = Scgi.Request.contents req in
        if !output_csp_reports then begin
          print_endline "\nCSP Violation Report:\n" ;
          print_endline contents 
        end else ();
        return { Scgi.Response.
                 status = `Ok;
                 headers = [];
                 body = `String "ok" }
      | _ -> not_found ()
    end

let rec serve config port =
  let callback req =
    Lwt.catch
      (fun () ->
         Lwt.with_value Indoor_config.key (Some config) (fun () -> handle config req))
      (fun e ->
         let () = begin
           Printf.fprintf stderr "Handler error: %s\n%!" (Printexc.to_string e) ;
           Printexc.print_backtrace stderr ;
         end
         in Lwt.fail e)
  in
  try
    Scgi.Server.handler_inet "indoor-wiki" "127.0.0.1" port callback
  with
  | Unix.Unix_error(Unix.EADDRINUSE, _, _) ->
    Printf.fprintf stderr "indoor-wiki: %d is already in use. Shutting down...\n%!" port ;
    exit 1
  | Unix.Unix_error(Unix.EACCES, "bind", _) ->
    Printf.fprintf stderr "indoor-wiki: You don't have access to port %d. Shutting down...\n%!" port ;
    exit 1
  | Unix.Unix_error _ as e ->
    Printf.fprintf stderr "Server error: %s\n%!" (Printexc.to_string e) ;
    Printexc.print_backtrace stderr ;
    serve config port

let assert_normal_exit cmd = function
  | Unix.WEXITED 0 -> ()
  | Unix.WEXITED code ->
    failwith (Printf.sprintf "Command '%s' exited with code %d." cmd code)
  | Unix.WSIGNALED signal ->
    failwith (Printf.sprintf "Command '%s' killed by signal %d." cmd signal)
  | Unix.WSTOPPED signal ->
    failwith (Printf.sprintf "Command '%s' stopped by signal %d." cmd signal)

let command cmd = 
  let chan = Unix.open_process_in cmd in
  let out =
    let buf = Buffer.create 128 in
    let scratch = Bytes.make 128 ' ' in
    let rec loop () =
      let n = input chan scratch 0 128 in
      if n = 0 then ()
      else begin
        Buffer.add_bytes buf scratch ;
        loop ()
      end
    in
    loop () ;
    Buffer.contents buf
  in
  assert_normal_exit cmd (Unix.close_process_in chan) ;
  out

let write_to_file path s =
  let ch = open_out path in
  let () = output_string ch s in
  close_out ch

let () =
  let embed = ref true in
  let port = ref 8080 in
  let config_path = ref "indoor.toml" in
  let speclist =
    [("-port", Arg.Set_int port,
      " The port to serve HTTP on. Defaults to 8080. \
       By default, Indoor Wiki itself will serve SCGI on [port]+1, while \
       Nginx will be started on this port to reverse proxy. See -noembed.");
     ("-config", Arg.Set_string config_path,
      " The path to the Indoor Wiki configuration file. \
       Defaults to indoor.toml, in the current directory.");
     ("-noembed", Arg.Clear embed,
      " Don't start the embedded Nginx reverse proxy. \
       Indoor Wiki will serve SCGI directly on [port].");
     ("-output-csp-reports", Arg.Set output_csp_reports,
      " Output Content-Security-Policy violation reports.")]
  in
  let usage_msg = "An internal wiki server." in
  let anon_fun _ =
    Arg.usage speclist usage_msg ;
    exit 1
  in

  Arg.parse speclist anon_fun usage_msg ;
  let config = Indoor_config.load !config_path in
  Indoor_config.check config ;

  (* Launch an 'embedded' Nginx server if [embed] is true. *)
  let nginx =
    if not !embed then None
    else begin
      (* Move ourselves to [port]+1. *)
      let nginx_port = string_of_int !port in
      let () = port := !port + 1 in
      let scgi_port = string_of_int !port in

      (* Create temporary files to store the Nginx config, PID file, and error
         log. *)
      let conf_file = command "mktemp -t conf.XXX" |> String.trim in
      let pid_file = command "mktemp -t pid.XXX" |> String.trim in
      let error_log = command "mktemp -t error.XXX" |> String.trim in

      let tmp = command "mktemp -d -t tmp.XXX" |> String.trim in

      (* Generate and save an Nginx config that will reverse proxy this Indoor
         Wiki instance. *)
      let conf =
        Indoor_bake.nginx_conf
          ~pid_file ~error_log ~nginx_port ~scgi_port ~tmp
      in
      let () = write_to_file conf_file conf in

      let nginx_cmd = Printf.sprintf "nginx -c '%s' -p ." conf_file in
      let ch = Unix.open_process_in nginx_cmd in
      Some (ch,
            fun () ->
              let rm s = ignore (command (Printf.sprintf "rm '%s'" s)) in
              ignore (command (nginx_cmd ^ " -s stop")) ;
              assert_normal_exit "nginx" (Unix.close_process_in ch) ;
              (* The PID file is deleted by Nginx. *)
              ignore @@ command @@ "rm -rf " ^ tmp;
              rm conf_file ;
              rm error_log)
    end
  in

  (* Avoid closing when the connection drops unexpectedly. This should be
     handled by the code doing the reads/writes. *)
  Sys.(set_signal sigpipe Signal_ignore) ;

  (* Use the libev Lwt backend. Important for this to start before any Lwt
     threads are in use. *)
  Lwt_engine.set ~transfer:true ~destroy:true (new Lwt_engine.libev) ;

  (* Start the server.
     [server] is a handle that lets us shut it down. *)
  let server = serve config (!port) in

  (* [shutdown_waiter] will be wakened when we want to finally exit the
     program. *)
  let shutdown_waiter, shutdown_wakener = Lwt.wait () in

  (* SIGINT/SIGTERM handler. Make sure we shut down everything cleanly. *)
  let shutdown _ =
    match nginx with
    | None -> ()
    | Some (ch, cleanup) ->
      print_endline "Received signal, shutting down..." ;
      cleanup () ;
      Lwt_io.shutdown_server server ;
      Lwt.wakeup shutdown_wakener ()
  in
  Sys.(set_signal sigint (Signal_handle shutdown)) ;
  Sys.(set_signal sigterm (Signal_handle shutdown)) ;


  (* Here we go! *)
  Lwt_main.run shutdown_waiter

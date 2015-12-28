let nginx_conf ~pid_file ~error_log ~nginx_port ~scgi_port = 
  Printf.sprintf
    {|pid %s;
error_log %s info;

events {
	worker_connections 1024;
}

http {
	server {
		listen %s;

		location / {
       # From the nginx distribution.
       scgi_param  REQUEST_METHOD     $request_method;
       scgi_param  REQUEST_URI        $request_uri;
       scgi_param  QUERY_STRING       $query_string;
       scgi_param  CONTENT_TYPE       $content_type;

       scgi_param  DOCUMENT_URI       $document_uri;
       scgi_param  DOCUMENT_ROOT      $document_root;
       scgi_param  SCGI               1;
       scgi_param  SERVER_PROTOCOL    $server_protocol;
       scgi_param  HTTPS              $https if_not_empty;

       scgi_param  REMOTE_ADDR        $remote_addr;
       scgi_param  REMOTE_PORT        $remote_port;
       scgi_param  SERVER_PORT        $server_port;
       scgi_param  SERVER_NAME        $server_name;

       scgi_pass localhost:%s;
		}
  }
}|}
    pid_file error_log nginx_port scgi_port

map $http_user_agent $whitelist_ua {
    default 0;               
    "${user_agent}" 1;                       
}                                   

server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /var/www/html;
        index index.html;
        server_name *.${domain_name};  

        include /etc/nginx-blocklist.conf;

        location / {
            if ($whitelist_ua = 0) {
                return 301 https://www.notion.so;
            }
            try_files $uri $uri/ @c2;
        }

        location @c2 {
            proxy_pass https://127.0.0.1:2222;
            proxy_redirect off;
            proxy_ssl_verify off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}
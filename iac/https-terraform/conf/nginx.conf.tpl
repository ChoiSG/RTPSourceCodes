# Bottom part taken from https://github.com/threatexpress/cs2modrewrite
user www-data;                                                                                                                                                              
worker_processes auto;                                                                                                                                                      
pid /run/nginx.pid;                                                                                                                                                         
include /etc/nginx/modules-enabled/*.conf;                                                                                                                                  
                                                                                                                                                                            
events {                                                                                                                                                                    
        worker_connections 768;                                                                                                                                             
        # multi_accept on;                                                                                                                                                  
}                                                                                                                                                                           
                                                                                                                                                                            
http {                                                                                                                                                                      
                                                                                                                                                                            
    ##                                                                                                                                                                  
    # Basic Settings                                                                                                                                                    
    ##      

    # Updating sizes for useragent map 
    map_hash_max_size 512;
    map_hash_bucket_size 512;                                                                                                                                                            
                                                                                                                                                                        
    sendfile on;                                                                                                                                                        
    tcp_nopush on;                                                                                                                                                      
    types_hash_max_size 2048;                                                                                                                                           
    # server_tokens off;                                                                                                                                                
                                                                                                                                                                        
    # server_names_hash_bucket_size 64;                                                                                                                                 
    # server_name_in_redirect off;                                                                                                                                      
                                                                                                                                                                        
    include /etc/nginx/mime.types;                                                                                                                                      
    default_type application/octet-stream;                                                                                                                              
                                                                                                                                                                        
    ##                                                                                                                                                                  
    # SSL Settings                                                                                                                                                      
    ##                                                                                                                                                                  
                                                                                                                                                                        
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE                                                                                          
    ssl_prefer_server_ciphers on;
    
    ##                                                                                                                                                                  
    # Logging Settings                                                                                                                                                  
    ##                                                                                                                                                                  
                                                                                                                                                                        
    access_log /var/log/nginx/access.log;                                                                                                                               
    error_log /var/log/nginx/error.log;                                                                                                                                 
                                                                                                                                                                        
    ##                                                                                                                                                                  
    # Gzip Settings                                                                                                                                                     
    ##                                                                           
                                                                                                                                                                        
    # Disable GZIP compression to prevent C2 errors
    gzip off;
    gzip_disable "msie6";                                                                   
                                        
    # gzip_vary on;                                                              
    # gzip_proxied any;                                                                                                                                               
    # gzip_comp_level 6;                                                         
    # gzip_buffers 16 8k;            
    # gzip_http_version 1.1;                                                      
    # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
                                                                                    
    ##                                                                           
    # Virtual Host Configs                                                                                                                                            
    ##                                                                            
                                                                                    
    map $http_user_agent $whitelist_ua {
        default 0;               
        "${user_agent}" 1;                       
    }                                   

    server {
        listen 80 default_server;
        listen [::]:80 default_server;

        #####################
        # SSL Configuration
        #####################
        #listen 443 ssl;
        #listen [::]:443 ssl;
        #ssl on;

        #ssl_certificate /etc/letsencrypt/live/<DOMAIN_NAME>/fullchain.pem; # managed by Certbot
        #ssl_certificate_key /etc/letsencrypt/live/<DOMAIN_NAME>/privkey.pem; # managed by Certbot
        #ssl_session_cache shared:le_nginx_SSL:1m; # managed by Certbot
        #ssl_session_timeout 1440m; # managed by Certbot
        #ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # managed by Certbot
        #ssl_prefer_server_ciphers on; # managed by Certbot

        root /var/www/html;
        index index.html;
        server_name *.${domain_name};  

        include /etc/nginx-blocklist.conf;

        location / {
            if ($whitelist_ua = 0) {
                return 301 https://www.google.com;
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
}
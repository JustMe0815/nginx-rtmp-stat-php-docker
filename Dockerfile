FROM debian:10

MAINTAINER Dennis Joeken version: 1.0

RUN apt-get update && apt-get install -y nano supervisor nginx libnginx-mod-rtmp stunnel4 git php-fpm && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 80
EXPOSE 22901
ARG streamkey
ARG facebook
ARG youtube
ARG login_user
ARG login_pass
RUN touch ./etc/stunnel/stunnel.conf

RUN echo "pid = /var/run/stunnel4/stunnel.pid\n\
output = /var/log/stunnel4/stunnel.log\n\
setuid = stunnel4\n\
setgid = stunnel4\n\
socket = r:TCP_NODELAY=1\n\
socket = l:TCP_NODELAY=1\n\
debug = 4\n\
[fb-live]\n\
client = yes\n\
accept = 127.0.0.1:22999\n\
connect = live-api-s.facebook.com:443\n\
verifyChain = no" > /etc/stunnel/stunnel.conf

RUN touch /etc/nginx/nginx.conf
RUN touch /etc/nginx/.htpasswd
RUN echo -n "$login_user:" > /etc/nginx/.htpasswd
RUN echo -n $(openssl passwd $login_pass) >> /etc/nginx/.htpasswd
RUN touch /var/www/html/index.php
WORKDIR "/var/www/html"
RUN mkdir /var/www/html/streams
RUN chmod -R 777 streams
RUN echo "<?php phpinfo(); phpinfo(INFO_MODULES);?>" > /var/www/html/index.php
WORKDIR "/usr/src"
RUN git clone https://github.com/arut/nginx-rtmp-module
RUN cp /usr/src/nginx-rtmp-module/stat.xsl /var/www/html/stat.xsl

RUN touch /var/www/html/obsauth.php
RUN echo "<?php\n\
\$file = 'streams/$streamkey';\n\
if(isset(\$_GET['name'])){\n\
\$streamkey = \$_GET['name'];\n\
\$password = '$streamkey';\n\
\$status = \$_GET['call'];\n\
if (\$streamkey == \$password) {\n\
if(isset(\$status)){\n\
if(\$status == 'publish'){\n\
file_put_contents(\$file, 'true');\n\
}\n\
elseif(\$status == 'publish_done'){\n\
file_put_contents(\$file, 'false');}\n\
}\n\
  http_response_code(201);\n\
} else {\n\
  http_response_code(500);}}\n\
if(isset(\$_GET['status'])){\n\
\$current = file_get_contents(\$file);\n\
if(\$current == 'true'){  http_response_code(200);}else{http_response_code(201);}\n\
}?>" > /var/www/html/obsauth.php

RUN echo "user www-data;\n\
worker_processes 1;\n\
pid /run/nginx.pid;\n\
include /etc/nginx/modules-enabled/*.conf;\n\
events {\n\
worker_connections 768;\n\
}\n\
http {\n\
	sendfile on;\n\
	tcp_nopush on;\n\
	tcp_nodelay on;\n\
	keepalive_timeout 65;\n\
	types_hash_max_size 2048;\n\
	include /etc/nginx/mime.types;\n\
	default_type application/octet-stream;\n\
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE\n\
	ssl_prefer_server_ciphers on;\n\
	access_log /var/log/nginx/access.log;\n\
	error_log /var/log/nginx/error.log;\n\
	gzip on;\n\
	include /etc/nginx/conf.d/*.conf;\n\
  server {\n\
  	listen 80 default_server;\n\
    root /var/www/html;\n\
            location / {\n\
                    try_files $uri $uri/ =404;\n\
            }\n\
            location ~ \.php$ {\n\
                    include snippets/fastcgi-php.conf;\n\
                    fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;\n\
            }\n\
            location ~ /\.ht {\n\
                    deny all;\n\
            }\n\
    location /stat {\n\
              rtmp_stat all;\n\
              rtmp_stat_stylesheet /stat.xsl;\n\
              auth_basic \"Restricted Content\";\n\
              auth_basic_user_file /etc/nginx/.htpasswd;\n\
          }\n\
  location /stat.xsl {\n\
  	root /var/www/html/;\n\
  	}\n\
      }\n\
}\n\
rtmp {\n\
        server {\n\
                listen 22901;\n\
                chunk_size 4096;\n\
                notify_method get;\n\
                application obsstream {\n\
                live on;\n\
                record off;\n\
                on_publish http://127.0.0.1/obsauth.php;\n\
                on_publish_done http://127.0.0.1/obsauth.php;\n\
                push rtmp://127.0.0.1:22999/rtmp/$facebook;\n\
                push rtmp://a.rtmp.youtube.com/live2/$youtube;\n\
}\n\
        }\n\
}" > /etc/nginx/nginx.conf

ENTRYPOINT ["/bin/bash", "-c", "service stunnel4 start && service nginx start && service php7.3-fpm start && tail -f /dev/null"]

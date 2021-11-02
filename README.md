# nginx-rtmp-stat-php-docker
Complete Dockerfile for nginx rtmp stat php to push to youtube and facebook.

# How to?
Copy file to your linux box and run:
```
 docker build\
 --build-arg streamkey=your-random-stream-key \
 --build-arg login_user=your-statuser \
 --build-arg login_pass=your-statpassword \
 --build-arg youtube=youtube-streamkey \
 --build-arg facebook=facebook-streamkey \
 -t myawesomestream .
 ```
 And then just start the container up with for example:
 
```
docker run --name myawesomestream -p 22222:22901 -p 22902:80 -dit myawesomestream
```
Stats will be availabe at:

```
https://yourdomain.tld:22902/stat

Username = your-statuser
Password = your-statpassword
```

If you use OBS-Studio:
```
  In OBS go to settings->stream
  
  serice = custom...
  server = rtmp://yourdomain.tld:2222/obsstream
  Stream Key = your-random-stream-key
  ```
 
 If you have a webpage monitor for live status, you can use the http-response-code
 ```
 url http://yourdomain.tld:22902/obsauth.php?status
 
 return codes will be:
 
 200 = live
 201 = not live
 
 ```

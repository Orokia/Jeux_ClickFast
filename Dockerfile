
FROM nginxinc/nginx-unprivileged:1.28-alpine

USER root
RUN rm -f /usr/share/nginx/html/50x.html

COPY index.html style.css script.js /usr/share/nginx/html/

USER nginx

EXPOSE 8080

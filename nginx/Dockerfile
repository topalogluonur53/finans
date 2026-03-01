FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy our compiled Flutter web app
COPY finans_app/build/web/ /usr/share/nginx/html/

# Copy nginx config
COPY nginx/docker-nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

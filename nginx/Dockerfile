# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
# Copy the flutter app source code
COPY finans_app/ ./

# Get dependencies and build for web
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the app with nginx
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy our compiled Flutter web app from the build stage
COPY --from=build /app/build/web/ /usr/share/nginx/html/

# Copy nginx config
COPY nginx/docker-nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

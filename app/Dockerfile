# Use lightweight Nginx image
FROM nginx:alpine

# Copy index.html into Nginx web root
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
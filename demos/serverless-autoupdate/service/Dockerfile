# Set the base image
FROM registry.access.redhat.com/ubi8/ubi:latest

# Install packages
RUN dnf -y install httpd 

# Copy index
COPY index.html /var/www/html/index.html

# Expose the default port
EXPOSE 8080

# Default args
CMD ["-D FOREGROUND"]

# Set default container command
ENTRYPOINT /usr/sbin/httpd

# Use an official WordPress image as the base image
FROM wordpress:latest

# Install necessary packages
RUN apt-get update && apt-get install -y \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create a script to generate a self-signed certificate
RUN echo "\
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/server.key -out /etc/ssl/certs/server.crt -subj '/CN=localhost'\
    " > /usr/local/bin/generate_certificate.sh

# Make the script executable
RUN chmod +x /usr/local/bin/generate_certificate.sh

# Run the script to generate the certificate
RUN /usr/local/bin/generate_certificate.sh

# Configure Apache with the generated SSL certificate
RUN a2enmod ssl \
    && a2ensite default-ssl \
    && sed -i '/<VirtualHost \*:80>/a \ \n<VirtualHost *:443>\n\
           SSLEngine on\n\
           SSLCertificateFile /etc/ssl/certs/server.crt\n\
           SSLCertificateKeyFile /etc/ssl/private/server.key\n\
       </VirtualHost>' /etc/apache2/sites-available/000-default.conf

# Expose port 443 for SSL
EXPOSE 443
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
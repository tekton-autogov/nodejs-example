FROM registry.access.redhat.com/ubi9/ubi
USER root

# Update image
RUN dnf update --disablerepo=* --enablerepo=ubi-9-appstream --enablerepo=ubi-9-baseos -y && rm -rf /var/cache/yum
RUN dnf install --disablerepo=* --enablerepo=ubi-9-appstream --enablerepo=ubi-9-baseos httpd -y && rm -rf /var/cache/yum

# Add default Web page and expose port
RUN echo "The Web Server is Running" > /var/www/html/index.html
EXPOSE 80

# Start the service
CMD ["-D", "FOREGROUND"]
ENTRYPOINT ["/usr/sbin/httpd"]


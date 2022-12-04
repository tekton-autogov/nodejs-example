FROM registry.access.redhat.com/ubi8/ubi

# Based on https://access.redhat.com/login?redirectTo=https%3A%2F%2Faccess.redhat.com%2Fdocumentation%2Fen-us%2Fred_hat_enterprise_linux%2F9%2Fhtml-single%2Fbuilding_running_and_managing_containers%2Findex%23proc_building-ubi-based-images_assembly_adding-software-to-a-ubi-container

USER root

# Install httpd, add a webpage, update permissions so that random uids in the root group can run httpd
RUN dnf install --disablerepo=* --enablerepo=ubi-8-appstream-rpms --enablerepo=ubi-8-baseos-rpms httpd -y && rm -rf /var/cache/yum && \
    echo "The Web Server is Running" > /var/www/html/index.html && \
    chown -R root: /var/run/httpd/ /var/log/httpd/ && \
    chmod -R g+rwx /var/run/httpd/ /var/log/httpd/

# Add a configuration that has been updated to listen on port 8080 so that non-root users can start httpd
COPY httpd.conf /etc/httpd/conf/httpd.conf

EXPOSE 8080

USER 1001

# Start the service
CMD ["-D", "FOREGROUND"]
ENTRYPOINT ["/usr/sbin/httpd"]


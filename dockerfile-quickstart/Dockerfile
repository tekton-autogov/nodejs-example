FROM registry.access.redhat.com/ubi8/ubi

# Based on https://access.redhat.com/login?redirectTo=https%3A%2F%2Faccess.redhat.com%2Fdocumentation%2Fen-us%2Fred_hat_enterprise_linux%2F9%2Fhtml-single%2Fbuilding_running_and_managing_containers%2Findex%23proc_building-ubi-based-images_assembly_adding-software-to-a-ubi-container

USER root

RUN dnf install --disablerepo=* --enablerepo=ubi-8-appstream --enablerepo=ubi-8-baseos httpd -y && rm -rf /var/cache/yum && \ # Install httpd
    echo "The Web Server is Running" > /var/www/html/index.html && \
    chown -R root: /var/run/httpd/ /var/log/httpd/ && \
    chmod -R g+rwx /var/run/httpd/ /var/log/httpd/
COPY httpd.conf /etc/httpd/conf/httpd.conf
EXPOSE 8080

USER 1001

# Start the service
CMD ["-D", "FOREGROUND"]
ENTRYPOINT ["/usr/sbin/httpd"]


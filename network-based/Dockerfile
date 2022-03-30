FROM registry.access.redhat.com/ubi8/ubi
RUN yum -y install nginx && yum clean all
ARG kickstart
ARG commit
ADD $kickstart /usr/share/nginx/html/
ADD $commit /usr/share/nginx/html/
ADD nginx.conf /etc/
EXPOSE 8080
CMD ["/usr/sbin/nginx", "-c", "/etc/nginx.conf"]
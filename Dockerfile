#FROM dockeruser/noisebuntu:latest
FROM library/ubuntu:14.04

MAINTAINER n4sjamk

 
RUN apt-get update && apt-get install -y openssh-server supervisor pptpd nano vim
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor
#RUN sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY pptpd.conf    /etc/
COPY chap-secrets  /etc/ppp/
COPY pptpd-options /etc/ppp/
COPY rc.local		/etc/
COPY sysctl.conf	/etc/
RUN /etc/init.d/pptpd restart
RUN sudo useradd dockeruser -m -s /bin/bash
RUN echo dockeruser:dockeruser | sudo chpasswd
RUN sudo usermod -aG sudo dockeruser
RUN iptables -t nat -A POSTROUTING -s 172.17.0.0/24 -o eth0 -j MASQUERADE
RUN iptables -A FORWARD -p tcp --syn -s 172.17.0.0/24 -j TCPMSS --set-mss 1356
RUN apt-get install iptables-persistent

#VOLUME ["/etc/supervisor/conf.d"]

#WORKDIR /etc/supervisor/conf.d

EXPOSE 22 1723
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
#CMD ["/usr/bin/supervisord"]


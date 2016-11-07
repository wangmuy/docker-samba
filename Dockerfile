FROM ubuntu:16.04
MAINTAINER wangmuy <wangmuy@gmail.com>

RUN export DEBIAN_FRONTEND='noninteractive'

COPY sources.list /etc/apt/sources.list
RUN apt-get update -qq && \
  apt-get install -qqy samba vim

RUN sed -i 's|^\(   unix password sync = \).*|\1no|' /etc/samba/smb.conf && \
  echo '   security = user' >>/etc/samba/smb.conf && \
  echo '' >>/etc/samba/smb.conf

EXPOSE 137/udp 138/udp 139 445

COPY start.sh /start.sh
RUN chmod 777 /start.sh
CMD ["/start.sh"]

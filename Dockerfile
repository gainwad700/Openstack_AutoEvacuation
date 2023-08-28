FROM docker.io/dokken/rockylinux-8
MAINTAINER sns.network
RUN dnf update -y
RUN dnf install python3 python3-pip -y
RUN pip3 install -U pip
RUN pip install python-openstackclient
RUN dnf install mariadb -y
RUN mkdir /etc/hostevac
COPY mig.sh /etc/hostevac
COPY admin-openrc.sh /etc/hostevac
CMD ["cat", "hosts", ">>", "/etc/hosts"]
CMD ["sh", "/etc/hostevac/mig.sh"]
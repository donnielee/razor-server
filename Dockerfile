# This file is used in conjnction with docker-compose command to
#  build the razorserver_razorserver razorserver_razordb images in dockerhub
#  so that the 'docker-compose up' command can pull them down and run setup
#  script to get razor running locally in two containers.
#
#From centos/postgresql-94-centos7
#VOLUME /var/lib/pgsql/data
#ENV POSTGRESQL_USER razor
#ENV POSTGRESQL_PASSWORD mypass
#ENV POSTGRESQL_DATABASE razor_prd

From centos:latest
MAINTAINER "kev" spam4kev@gmail.com

COPY ./razor-entrypoint.sh /etc/razor/razor-entrypoint.sh
#ADD http://links.puppetlabs.com/razor-microkernel-latest.tar /tmp
#Install deps
RUN yum update -y && \
    yum install -y \
	http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm \
        wget \
	ruby \
	rubygems && \
    gem install razor-client
RUN yum install -y razor-server

RUN sed -i 's/mypass/cloud000@/g' /etc/razor/config.yaml

ENV TORQUEBOX_HOME "/opt/razor-torquebox"
ENV JBOSS_HOME "${TORQUEBOX_HOME}/jboss"
ENV JRUBY_HOME "${TORQUEBOX_HOME}/jruby"
ENV PATH "${JRUBY_HOME}/bin:${PATH}"
RUN export PATH TORQUEBOX_HOME JBOSS_HOME JRUBY_HOME

ENTRYPOINT /etc/razor/razor-entrypoint.sh

#EXPOSE 8150
EXPOSE 8080
#the rest of the razor server prep is performed via entrypoint script "razor-entrypoint.sh" in this git repo using docker-compose.

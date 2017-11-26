FROM ubuntu
MAINTAINER Steven Yan

ENV PIO_VERSION 0.12.0
ENV SPARK_VERSION 2.1.1
ENV ELASTICSEARCH_VERSION 5.5.2
ENV HBASE_VERSION 1.2.6

ENV PIO_HOME /PredictionIO-${PIO_VERSION}-incubating
ENV PATH=${PIO_HOME}/bin:$PATH
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=141 \
    JAVA_VERSION_BUILD=15 \
    JAVA_PACKAGE=server-jre \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin

RUN apt-get update \
    && apt-get install -y --auto-remove --no-install-recommends curl libgfortran3 python-pip wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
    http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/336fa29ff2bb4ef291e347e091f7f4a7/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
    && gunzip /tmp/java.tar.gz \
    && tar -C /opt -xf /tmp/java.tar \
    && ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk \
    && find /opt/jdk/ -maxdepth 1 -mindepth 1 | grep -v jre | xargs rm -rf \
    && cd /opt/jdk/ \
    && ln -s ./jre/bin ./bin

RUN curl -O http://apache.mirrors.pair.com/incubator/predictionio/${PIO_VERSION}-incubating/apache-predictionio-${PIO_VERSION}-incubating.tar.gz \
    && mkdir apache-predictionio-${PIO_VERSION}-incubating \
    && tar -xvzf apache-predictionio-${PIO_VERSION}-incubating.tar.gz -C ./apache-predictionio-${PIO_VERSION}-incubating \
    && rm apache-predictionio-${PIO_VERSION}-incubating.tar.gz \
    && cd apache-predictionio-${PIO_VERSION}-incubating \
    && ./make-distribution.sh

RUN tar zxvf /apache-predictionio-${PIO_VERSION}-incubating/PredictionIO-${PIO_VERSION}-incubating.tar.gz -C /
RUN rm -r /apache-predictionio-${PIO_VERSION}-incubating
RUN mkdir /${PIO_HOME}/vendors
COPY files/pio-env.sh ${PIO_HOME}/conf/pio-env.sh

RUN wget http://d3kbcqa49mib13.cloudfront.net/spark-2.1.1-bin-hadoop2.6.tgz \
    && tar zxvfC spark-2.1.1-bin-hadoop2.6.tgz PredictionIO-${PIO_VERSION}-incubating/vendors \
    && rm spark-${SPARK_VERSION}-bin-hadoop2.6.tgz

RUN echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
    && apt-get update \
    && apt-get install -y --auto-remove --no-install-recommends sbt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && tar -xvzf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz -C ${PIO_HOME}/vendors \
    && rm elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && echo 'cluster.name: predictionio' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml \
    && echo 'network.host: 127.0.0.1' >> ${PIO_HOME}/vendors/elasticsearch-${ELASTICSEARCH_VERSION}/config/elasticsearch.yml

RUN curl -O http://apache.mirrors.hoobly.com/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar -xvzf hbase-${HBASE_VERSION}-bin.tar.gz -C ${PIO_HOME}/vendors \
    && rm hbase-${HBASE_VERSION}-bin.tar.gz
COPY files/hbase-site.xml ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml
RUN sed -i "s|VAR_PIO_HOME|${PIO_HOME}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml \
    && sed -i "s|VAR_HBASE_VERSION|${HBASE_VERSION}|" ${PIO_HOME}/vendors/hbase-${HBASE_VERSION}/conf/hbase-site.xml
#!/bin/bash
script_path=$(cd $(dirname $0)/../;pwd)
. $script_path/build/logutil.lib
. $script_path/build/comm_lib
PAK_PATH="/root/elk-single/packages/"
INSTALL_PATH="/data/service/"

function elk_install_init(){
    if [ ! -d ${INSTALL_PATH} ]; then
        mkdir -p ${INSTALL_PATH} > /dev/null 2>&1
    fi

}


function install_elk(){

    install_jdk
    log_echo RATE 30
    install_elasticsearch
    sleep 5
    log_echo RATE 34
    install_kibana
    log_echo RATE 38
    install_nginx
    log_echo RATE 42
    install_logstash
    log_echo RATE 44
    config_logstash
    install_logstash-forwarder

}

function install_logstash(){
    install_log INFO "LOGSTASH_INSTALL" "logstash install ..."

    cd ${PAK_PATH}
    LOGSTASH_PAK="logstash-6.1.3.tar.gz"
    LOGSTASH_PATH="logstash-6.1.3"
    cp $LOGSTASH_PAK $INSTALL_PATH
    cd ${INSTALL_PATH}
    tar -zxvf $LOGSTASH_PAK > /dev/null 2>&1
    rm -rf $LOGSTASH_PAK
    cd ${INSTALL_PATH}
    bin/logstash

}
function install_nginx(){
    install_log INFO "NGNIX_INSTALL" "start to install nginx ..."

    cd ${PAK_PATH}
    NGINX_PAK="nginx-1.11.13-1.el7.ngx.x86_64.rpm"
    if [ ! -e ${NGINX_PAK} ]; then
        install_log ERROR "KIBANA_INSTALL" "{NGINX_PAK} is not exit,install JDK failed"
        exit 1
    fi
    rpm -ivh $NGINX_PAK > /dev/null 2>&1
    rm /etc/nginx/conf.d/default.conf
    cp ../conf/kibana.conf /etc/nginx/conf.d/
    cd /usr/sbin/
    nginx


}
function install_kibana(){
    install_log INFO "KIBANA_INSTALL" "install elastic search"

    cd ${PAK_PATH}
    KIBANA_PAK="kibana-6.1.3-linux-x86_64.tar.gz"
    KIBANA_PATH="kibana-6.1.3-linux-x86_64"
    if [ ! -e ${KIBANA_PAK} ]; then
        install_log ERROR "KIBANA_INSTALL" "{KIBANA_PAK} is not exit,install JDK failed"
        exit 1
    fi
    cp $KIBANA_PAK $INSTALL_PATH
    tar -zxvf $KIBANA_PAK > /dev/null 2>&1
    rm -rf $KIBANA_PAK
    sed -i '/#elasticsearch.url/c elasticsearch.url: "http://localhost:9200"' ${KIBANA_PATH}/config/kibana.yml
    cd ${KIBANA_PATH}
    (bin/kibana &)


}
function install_elasticsearch(){
    install_log INFO "ELASTIC_SEARCH" "install elastic search"

    cd ${PAK_PATH}
    ELASTICSEARCH_PAK="elasticsearch-6.1.3.tar.gz"
    ELASTICSEARCH_PATH="elasticsearch-6.1.3"
    if [ ! -e "${ELASTICSEARCH_PAK}" ]; then
        install_log ERROR "ELASTIC_SEARCH" "{ELASTICSEARCH_PAK} is not exit,install JDK failed"
        exit 1
    fi
    cp $ELASTICSEARCH_PAK $INSTALL_PATH
    cd ${INSTALL_PATH}
    tar -zxvf $ELASTICSEARCH_PAK > /dev/null 2>&1
    rm -rf $ELASTICSEARCH_PAK
    sed -i '/network.host/c network.host: localhost' ${ELASTICSEARCH_PATH}/config/elasticsearch.yml
    groupadd elk
    useradd elk -g elk
    chown -R elk:elk /data/service/$ELASTICSEARCH_PATH
    cd ${ELASTICSEARCH_PATH}
    chmod +x bin/*
    su - elk -c "(/data/service/$ELASTICSEARCH_PATH/bin/elasticsearch &)"
}

function install_jdk(){
    install_log INFO "JDK_INSTALL" "install jdk..."
    cd ${PAK_PATH}
    JDK_PAK="jdk-8u162-linux-x64.rpm"
    if [ ! -e ${JDK_PAK} ]; then
        install_log ERROR "JDK_INSTALL" "{JDK_PAK} is not exit,install JDK failed"
        exit 1
    fi
    rpm -ivh $JDK_PAK > /dev/null 2>&1

    echo "JAVA_HOME=/usr/java/jdk1.8.0_162" >> /etc/profile
    echo "export JAVA_HOME" >> /etc/profile
    echo "PATH=\$JAVA_HOME/bin:$PATH" >> /etc/profile
    echo "CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:$JAVA_HOME/bin/tools.jar" >> /etc/profile

    source /etc/profile

    java_version=`java -version 2>&1`
    install_log INFO "JDK_INSTALL" "installed ${java_version}"
}

elk_install_init
install_elk
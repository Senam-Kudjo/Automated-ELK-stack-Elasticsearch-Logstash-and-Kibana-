#!/bin/bash

NGX=nginx
ELS=elasticsearch
ELSV=elastic-8.x.list #elastic version list
ELSVN="8.x" #elastic version number
LGS=logstash
KIB=kibana

# Define green color code
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Define pink color code
PINK='\033[1;35m'
NC='\033[0m' # No Color

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#requesting the IP hosting the ELK Stack
read -p "Enter Server IP:" ServerIP

sudo apt update
sudo apt install -y openjdk-8-jdk
apt install -y default-jre default-jdk

#Check if Nginx is installed
if systemctl is-failed --quiet $NGX
then
        echo "You do not have $NGX installed, installation will now commence"
        sudo apt purge $NGX
        sudo apt autoremove
        sudo apt -y install nginx
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl daemon-reload
        echo -e "${GREEN}Web Server Installed Successfuly (1/4)${NC}"

else
        echo -e "${GREEN}Package already installed${NC}"
fi
#End Of


# Check if /elastic file exists
if [ -f "/etc/apt/sources.list.d/$ELSV" ]; then
    rm /etc/apt/sources.list.d/$ELSV
    echo -e "${PINK} $ELSV removed.${NC}"
else
    # If file does not exist
    echo -e "${PINK} file does not exists. Let's proceed.${NC}"
fi
#End Of


#Check for elasticsearch and install Elasticsearch
if systemctl is-failed --quiet $ELS
then
        echo "ELASTICSEARCH Installation Commencing"
        cd /opt
        mkdir elasticsearch
        cd /opt/elasticsearch
        wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
        sudo apt-get install apt-transport-https
        echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/$ELSVN/apt stable main" | sudo tee /etc/apt/sources.list.d/$ELSV
        sudo apt-get update && sudo apt-get install elasticsearch

        # generating elasticseach's password and token in yellow
        echo -e "${YELLOW}++++++++++++++++++COPY NEW PASSWORD BELOW!!!+++++++++++++++++${NC}"
        /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
        echo -e "${YELLOW}++++++++++++++++++COPY NEW PASSWORD ABOVE!!!+++++++++++++++++${NC}"

        echo -e "${YELLOW}+----------------------COPY THE TOKEN BELOW------------------------+${NC}"
        /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
        echo -e "${YELLOW}+----------------------TOKEN ABOVE---------------------------------+${NC}"

        read -p "IF YOU ARE DONE COPYING THE PASSWORD AND TOKEN ABOVE HIT ENTER TO CONTINUE: "
        echo -e "${GREEN}proceeding ... to install logstash. ${NC}"
        sudo systemctl daemon-reload
        sudo systemctl enable elasticsearch.service
        sudo systemctl start elasticsearch.service

else
        echo "Package Already Installed"
fi

#Check for Logstash and Install
if systemctl is-failed --quiet $LGS
then
        echo "ELASTICSEARCH Installation Commencing"
        cd /opt
        mkdir logstash
        cd /opt/logstash
        echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/$ELSVN/apt stable main" | sudo tee -a /etc/apt/sources.list.d/$ELSV
        sudo apt-get update && sudo apt-get install logstash
        systemctl daemon-reload
        sed -i "s/api.http.host: 127.0.0.1/api.http.host: $ServerIP/" /etc/logstash/logstash.yml
        systemctl enable logstash
        systemctl start logstash
else
        echo "Logstash Already installed."
fi



#Check for Kibana and Install
if systemctl is-failed --quiet $KBN
then
        echo "ELASTICSEARCH Installation Commencing"
        cd /opt
        mkdir kibana
        cd /opt/kibana
        sudo apt-get update && sudo apt-get install kibana
        echo -e "${YELLOW}++++++++++++++++++COPY NEW PASSWORD BELOW!!!+++++++++++++++++${NC}"
        sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
        echo -e "${YELLOW}++++++++++++++++++COPY NEW PASSWORD ABOVE!!!+++++++++++++++++${NC}"
        read -p "IF YOU ARE DONE COPYING THE TOKEN ABOVE HIT ENTER key TO CONTINUE: "
        echo "Kibana service is being enabled"
        sed -i "s/server.host: 127.0.0.1/server.host: $ServerIP/" /etc/kibana/kibana.yml
        sudo systemctl daemon-reload
        sudo systemctl enable kibana.service
        sudo systemctl start kibana
else
        echo "Kibana Already Installed but might be Inactive"
fi

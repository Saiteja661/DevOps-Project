#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
  echo -e "${R}You should run this script as root user or with sudo privileges${N}" | tee -a $LOG_FILE
  exit 1
fi

VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "${R}FAIL${N}" | tee -a $LOG_FILE
    echo -e "${Y}Check the log file for more details: ${LOG_FILE}${N}" | tee -a $LOG_FILE
    exit 1
  else
    echo -e "${G}SUCCESS${N}" | tee -a $LOG_FILE
  fi
}

dnf module disable nginx -y &>>$LOG_FILE
dnf module enable nginx:1.24 -y &>>$LOG_FILE
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default nginx content"

curl -L -o /tmp/frontend.zip "https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip" &>>$LOG_FILE
VALIDATE $? "Downloading frontend content"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extracting frontend content"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing default nginx configuration file"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying nginx configuration file"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting nginx"


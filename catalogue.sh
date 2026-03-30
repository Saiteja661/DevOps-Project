#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.saiteja.shop"

if [ $USERID -ne 0 ]; then
  echo -e "${R}You should run this script as root user or with sudo privileges${N}" | tee -a $LOG_FILE
  exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "${R}FAIL${N}"
    echo -e "${Y}Check the log file for more details: $LOG_FILE${N}" | tee -a $LOG_FILE
    exit 1
  else
    echo -e "${G}SUCCESS${N}" | tee -a $LOG_FILE
  fi
}

dnf module disable nodejs -y   &>>$LOG_FILE
VALIDATE $?

dnf module enable nodejs:20 -y    &>>$LOG_FILE
VALIDATE $?

dnf install nodejs -y    &>>$LOG_FILE 
VALIDATE $?

id roboshop    &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $?
else
    echo -e "${Y}User 'roboshop' already exists. Skipping user creation.${N}" | tee -a $LOG_FILE
fi

mkdir /app    &>>$LOG_FILE
VALIDATE $?

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue.zip    &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application"

cd /app    &>>$LOG_FILE
VALIDATE $?

rm -rf /app/*    &>>$LOG_FILE
VALIDATE $? " Cleaning up old catalogue application files"

unzip /tmp/catalogue.zip    &>>$LOG_FILE
VALIDATE $? "Extracting catalogue application"

npm install    &>>$LOG_FILE
VALIDATE $? "Installing catalogue application dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service    &>>$LOG_FILE
VALIDATE $? "Copying catalogue systemd service file"

systemctl daemon-reload    &>>$LOG_FILE
systemctl enable catalogue    &>>$LOG_FILE
systemctl start catalogue    &>>$LOG_FILE
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo    &>>$LOG_FILE
dnf install mongodb-mongosh -y    &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Shell"

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")  &>>$LOG_FILE

if [$INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST < /app/db/master-data.js    &>>$LOG_FILE
    VALIDATE $? "Loading initial data into MongoDB"
else
    echo -e "${Y}MongoDB already contains 'catalogue' database. Skipping
fi

systemctl restart catalogue    &>>$LOG_FILE
VALIDATE $? "Restarting catalogue service"





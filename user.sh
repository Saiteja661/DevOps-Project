#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
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

mkdir -p $LOG_FOLDER

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
dnf module enable nodejs:20 -y    &>>$LOG_FILE
VALIDATE $?

dnf install nodejs -y    &>>$LOG_FILE
VALIDATE $?

id roboshop    &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $?
else
    echo -e "${Y}User 'roboshop' already exists. Skipping user creation.${N}" | tee -a $LOG_FILE
fi                  

mkdir /app    &>>$LOG_FILE
VALIDATE $?

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip    &>>$LOG_FILE

cd /app    &>>$LOG_FILE
VALIDATE $?

rm -rf /app/*    &>>$LOG_FILE
VALIDATE $?

unzip /tmp/user.zip    &>>$LOG_FILE
VALIDATE $?

npm install    &>>$LOG_FILE
VALIDATE $? "Installing Node.js dependencies for user application"

cp $SCRIPT_DIR/systemd/user.service /etc/systemd/system/user.service    &>>$LOG_FILE
VALIDATE $?

systemctl daemon-reload    &>>$LOG_FILE
VALIDATE $?
systemctl enable user    &>>$LOG_FILE
systemctl start user    &>>$LOG_FILE

VALIDATE $? "Starting user service"
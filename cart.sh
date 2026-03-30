#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$PWD
REDIS_HOST="redis.saiteja.shop"

if [ $USERID -ne 0 ]; then
  echo -e "${R}You should run this script as root user or with sudo privileges${N}"
  exit 1
fi

mkdir -p $LOG_FOLDER

VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "${R}FAIL${N}"
    exit 1
  else
    echo -e "${G}SUCCESS${N}"
  fi
}

dnf modules disable nodejs -y &>>$LOG_FILE
dnf modules enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "NodeJS Installation"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Adding Roboshop User"
else
    echo -e "${Y}Roboshop user already exists, skipping user creation${N}"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating Application Directory"

curl -L -o /tmp/cart.zip "https://roboshop-artifacts.s3.amazonaws.com/cart.zip" &>>$LOG_FILE
VALIDATE $? "Downloading Cart Application"

cd /app
VALIDATE $? "Changing Directory to /app"

rm -rf /app/*
VALIDATE $? "Cleaning Old Content"

unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Extracting Cart Content"

npm install &>>$LOG_FILE
VALIDATE $? "Installing NodeJS Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "Copying Cart Service File"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
systemctl start cart &>>$LOG_FILE
VALIDATE $? "Starting and Enabling Cart Service"

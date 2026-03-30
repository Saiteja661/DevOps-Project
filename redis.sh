#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf modules disable redis -y &>>$LOGS_FILE
dnf modules enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "Enabling Redis Module"

dnf install redis -y  &>>$LOGS_FILE
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 'protected-mode/ c protected-mode no' /etc/redis.conf &>>$LOGS_FILE
VALIDATE $? "Allowing Remote Connections to Redis"

systemctl enable redis &>>$LOGS_FILE
VALIDATE $? "Enabling Redis Service"

systemctl start redis &>>$LOGS_FILE
VALIDATE $? "Starting Redis Service"
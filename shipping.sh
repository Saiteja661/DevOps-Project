#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$PWD
MYSQL_HOST="mysql.saiteja.shop"

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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "${Y}User roboshop already exists${N}"
fi

mkdir -p /app
VALIDATE $? "Creating application directory"

curl -L -o /tmp/shipping.zip "https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip" &>>$LOG_FILE
VALIDATE $? "Downloading application content"

cd /app

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Removing old application content"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Extracting application content"

cd /app
mvn clean package &>>$LOG_FILE
VALIDATE $? "Building application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Renaming application jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copying systemd service file"      

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/schema/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/schema/app-user.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/schema/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading schema and data into mysql database"
else
    echo -e "${Y}Database cities already exists${N}"
fi

systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting shipping service"


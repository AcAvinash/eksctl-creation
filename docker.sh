#!/bin/bash

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

USERID=$(id -u)
DATE=$(date +%F-%H-%M-%S)
LOGSDIR=/tmp
SCRIPT_NAME=$(basename "$0")
LOGFILE=$LOGSDIR/$SCRIPT_NAME-$DATE.log

echo -e "$Y This script installs Docker, eksctl, kubectl, Helm, and supporting tools on Amazon Linux 2023 $N"

if [[ "$USERID" -ne 0 ]]; then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N"
        echo -e "$R Check log: $LOGFILE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

# -----------------------------------------------------------------------------  
echo -e "$Y Installing Docker and Git... $N"
dnf install -y dnf-plugins-core docker git &>>$LOGFILE
VALIDATE $? "Docker and Git installation"

echo -e "$Y Enabling and starting Docker service... $N"
systemctl enable --now docker &>>$LOGFILE
VALIDATE $? "Docker service enabled and started"

echo -e "$Y Adding ec2-user to Docker group... $N"
usermod -aG docker ec2-user &>>$LOGFILE
VALIDATE $? "ec2-user added to Docker group"

echo -e "$Y Installing Docker Compose... $N"
curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" \
     -o /usr/local/bin/docker-compose &>>$LOGFILE
VALIDATE $? "Docker Compose downloaded"
chmod +x /usr/local/bin/docker-compose &>>$LOGFILE
VALIDATE $? "Docker Compose made executable"

# -----------------------------------------------------------------------------  
echo -e "$Y Expanding root EBS volume (non-LVM setup)... $N"
growpart /dev/nvme0n1p1 &>>$LOGFILE || true
xfs_growfs / &>>$LOGFILE || true
VALIDATE $? "Root volume expanded"

# -----------------------------------------------------------------------------  
echo -e "$Y Installing eksctl... $N"
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" &>>$LOGFILE
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp &>>$LOGFILE
install -m 0755 /tmp/eksctl /usr/local/bin &>>$LOGFILE
rm -f eksctl_$PLATFORM.tar.gz /tmp/eksctl &>>$LOGFILE
VALIDATE $? "eksctl installation"

# -----------------------------------------------------------------------------  
echo -e "$Y Installing kubectl... $N"
curl -LO "https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.0/2025-05-01/bin/linux/amd64/kubectl" &>>$LOGFILE
chmod +x kubectl &>>$LOGFILE
mv kubectl /usr/local/bin/ &>>$LOGFILE
VALIDATE $? "kubectl installation"

# -----------------------------------------------------------------------------  
echo -e "$Y Verifying eksctl and kubectl versions... $N"
eksctl version &>>$LOGFILE
kubectl version --client &>>$LOGFILE
VALIDATE $? "Tool verification"

# -----------------------------------------------------------------------------  
echo -e "$Y Installing kubectx and kubens... $N"
git clone https://github.com/ahmetb/kubectx /opt/kubectx &>>$LOGFILE
ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx &>>$LOGFILE
ln -sf /opt/kubectx/kubens /usr/local/bin/kubens &>>$LOGFILE
VALIDATE $? "kubectx and kubens installation"

# -----------------------------------------------------------------------------  
echo -e "$Y Installing Helm... $N"
curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 &>>$LOGFILE
chmod 700 /tmp/get_helm.sh &>>$LOGFILE
/tmp/get_helm.sh &>>$LOGFILE
VALIDATE $? "Helm installation"

# -----------------------------------------------------------------------------  
echo -e "$G ✅ All components installed successfully! $N"
echo -e "$R ⚠️ Please logout and login again to apply Docker group permissions. $N"
echo -e "$Y Logs saved to: $LOGFILE $N"



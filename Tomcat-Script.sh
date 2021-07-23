#Script to setup Tomcat on centOS/RHEL 6.x and 7.x

#Author Emilie (Sandra)  July 2021

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check OS Version and Type
OS_VERSION=`cat /etc/*release |grep VERSION_ID |awk -F\" '{print $2}'`
OS_TYPE=`cat /etc/*release|head -1|awk '{print $1}'`

echo -e "\n Checking if your server is connected to the network...."

sleep 4

ping google.com -c 4

if
  [[ ${?} -ne 0 ]]
 then
 echo -e "\nPlease verify that your server is connected!!\n"
 exit 2
 fi

echo -e "\nChecking if system is centOS 6 or 7\n"

if
  [[ ${OS_VERSION} -eq 7 ]] && [[ ${OS_TYPE} == CentOS ]]
 then
 echo -e "\nDetected that you are running CentOS7 \n"
fi

# Java Installation
sleep 6
echo "Installing Java8..."
sleep 3

yum install java-1.8* -y
echo "Checking the java version, please wait"

echo

sleep 2

java -version

sleep 2

# Tomcat installation
cd /opt
wget https://downloads.apache.org/tomcat/tomcat-10/v10.0.8/bin/apache-tomcat-10.0.8.tar.gz

#Extract the Tomcat downloaded
tar -xvzf /opt/apache-tomcat-10.0.8.tar.gz

#Change permissions
chmod +x /opt/apache-tomcat-10.0.8/bin/startup.sh
chmod +x /opt/apache-tomcat-10.0.8/bin/shutdown.sh

# Creating a soft link to start Tomcat
ln -s /opt/apache-tomcat-10.0.8/bin/startup.sh /usr/local/bin/tomcatup
ln -s /opt/apache-tomcat-10.0.8/bin/shutdown.sh /usr/local/bin/tomcatdown


#Add Port 8090 to firewall
firewall-cmd --permanent --add-port=8090/tcp

firewall-cmd --reload

#Change the default port of Tomcat from 8080 to 8090
sed -i 's/8080/8090/g' /opt/apache-tomcat-10.0.8/conf/server.xml

# Modifying context.xml files to remove some lines in that file using the sed command
sed -i '21 s/^/<!--/' /opt/apache-tomcat-10.0.8/webapps/host-manager/META-INF/context.xml
sed -i '22 s/$/-->/' /opt/apache-tomcat-10.0.8/webapps/host-manager/META-INF/context.xml

sed -i '21 s/^/<!--/' /opt/apache-tomcat-10.0.8/webapps/manager/META-INF/context.xml
sed -i '22 s/$/-->/' /opt/apache-tomcat-10.0.8/webapps/manager/META-INF/context.xml

## Alternative - sed -i 's/<Valve/<!-- <Valve/; s/<\/Context>/ --> <\/Context>/' context.xml

tomcatup


#Add Users to the Tomcat Server using the sed command
sed -i 's/<\/tomcat-users>/<role rolename="manager-gui"\/><role rolename="manager-script"\/><role rolename="manager-jmx"\/><role rolename="manager-status"\/><user username="admin" password="admin" roles="manager-gui, manager-script, manager-jmx, manager-status"\/><user username="deployer" password="deployer" roles="manager-script"\/><user username="tomcat" password="s3cret" roles="manager-gui"\/><\/tomcat-users>/g' /opt/apache-tomcat-10.0.8/conf/tomcat-users.xml

tomcatdown

tomcatup

echo "Install complete"

tomcatdown

echo "Rebooting Tomcat"

tomcatup

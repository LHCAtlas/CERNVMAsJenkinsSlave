#!/bin/sh
# Run from the directory you wish to have everything installed.
# A short su will be done in order to copy everything over.
# Usage: ./configure.sh JENKINS_URL COMPUTER_NAME SECRET
#
#  JENKINS_URL is something like http://192.168.1.5:8080/ - gets you the jenkins home page
#  COMPUTER_NAME is what you called this when you declared this node in jenkin's UI.
#  SECRET is the horrible hash given to you by the jenkins web page for this computer.
#
# Run this from the account you want jenkins to run from!

JENKINS_URL=$1
COMPUTER_NAME=$2
SECRET=$3

# Setup the directory structure to run from.
[ -e jenkins ] || mkdir jenkins
cd jenkins
JENKINS_WORKDIR=`pwd`

# Get java down and loaded
echo Downloading Java SE
[ -e java ] || mkdir java
cd java
#curl -L -b "oraclelicense=a" http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-linux-x64.tar.gz -O
#tar -xzf jdk-8u111-linux-x64.tar.gz
JAVADIR=`pwd`/jdk1.8.0_111
cd ..

# Get the slave.jar file
echo Downloading slave.jar file
curl -s -o slave.jar $JENKINS_URL/jnlpJars/slave.jar

# Now, write out the files that are going to control everything when we reboot, run headless, etc.

echo "#!/bin/sh" > jenkins-slave.sh
echo "# chkconfig: - 91 35" >> jenkins-slave.sh
echo "# description: Starts and stops the jenkins-build slave service for $JENKINS_URL" >> jenkins-slave.sh
echo "#" >> jenkins-slave.sh
echo "# Launch a jenkins build slave" >> jenkins-slave.sh
echo ". /etc/rc.d/init.d/functions" >> jenkins-slave.sh

echo "start()" >> jenkins-slave.sh
echo "{" >> jenkins-slave.sh
echo "  echo -n \"Staring Jenkins BuildSlave: \"" >> jenkins-slave.sh
echo "  su $USER sh -c \"cd $JENKINS_WORKDIR; export PATH=$JAVADIR/bin:\$PATH; java -jar slave.jar -jnlpUrl $JENKINS_URL/computer/$COMPUTER_NAME/slave-agent.jnlp -secret $SECRET > slave.log 2>&1 &\"" >> jenkins-slave.sh
echo "  echo Done." >> jenkins-slave.sh
echo "}" >> jenkins-slave.sh

echo "stop()" >> jenkins-slave.sh
echo "{" >> jenkins-slave.sh
echo "  echo -n \"Shutting down Jenkins BuildSlave: \"" >> jenkins-slave.sh
echo "  killproc slave.jar" >> jenkins-slave.sh
echo "  echo Done." >> jenkins-slave.sh
echo "}" >> jenkins-slave.sh

echo "case \$1 in" >> jenkins-slave.sh
echo "  start)" >> jenkins-slave.sh
echo "    start" >> jenkins-slave.sh
echo "    ;;" >> jenkins-slave.sh
echo "  stop)" >> jenkins-slave.sh
echo "    stop" >> jenkins-slave.sh
echo "    ;;" >> jenkins-slave.sh
echo "  restart|reload)" >> jenkins-slave.sh
echo "    stop" >> jenkins-slave.sh
echo "    start" >> jenkins-slave.sh
echo "    ;;" >> jenkins-slave.sh
echo "  status)" >> jenkins-slave.sh
echo "    status java" >> jenkins-slave.sh
echo "    ;;" >> jenkins-slave.sh
echo "  *)" >> jenkins-slave.sh
echo "    echo Usage: \$0 {start|stop|restart|reload}" >> jenkins-slave.sh
echo "    exit 1" >> jenkins-slave.sh
echo "esac" >> jenkins-slave.sh
echo "exit 0" >> jenkins-slave.sh

chmod a+x jenkins-slave.sh

# Next, the su commands to put this in the right spot, and configure it to always work
sudo cp $JENKINS_WORKDIR/jenkins-slave.sh /etc/init.d/jenkins-slave
sudo chkconfig --add jenkins-slave
sudo chkconfig jenkins-slave on

echo "To start: /etc/init.d/jenkins-slave start"

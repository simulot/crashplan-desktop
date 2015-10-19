#!/bin/bash

#########################################
##        ENVIRONMENTAL CONFIG         ##
#########################################
echo "in install.sh"
# Configure user nobody to match unRAID's settings
export DEBIAN_FRONTEND="noninteractive"
usermod -u 99 nobody
usermod -g 100 nobody
usermod -d /home nobody
chown -R nobody:users /home

# Disable SSH
rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh


#########################################
##             INSTALLATION            ##
#########################################

cat <<'EOT' > /opt/install-crashplan.sh
#!/bin/bash
echo "in /opt/install-crashplan.sh"
APP_BASENAME=CrashPlan
DIR_BASENAME=crashplan
TARGETDIR=/usr/local/crashplan
BINSDIR=/usr/local/bin
MANIFESTDIR=/data
INITDIR=/etc/init.d
RUNLEVEL=`who -r | sed -e 's/^.*\(run-level [0-9]\).*$/\1/' | cut -d \  -f 2`
RUNLVLDIR=/etc/rc${RUNLEVEL}.d
JAVACOMMON=`which java`

#File downloaded during docker build.
tar -zx -f /tmp/CrashPlan.tgz -C /tmp

# Installation directory
cd /tmp/crashplan-install
INSTALL_DIR=`pwd`

# Make the destination dir
mkdir -p ${TARGETDIR}

# create a file that has our install vars so we can later uninstall
echo "" > ${TARGETDIR}/install.vars
echo "TARGETDIR=${TARGETDIR}" >> ${TARGETDIR}/install.vars
echo "BINSDIR=${BINSDIR}" >> ${TARGETDIR}/install.vars
echo "MANIFESTDIR=${MANIFESTDIR}" >> ${TARGETDIR}/install.vars
echo "INITDIR=${INITDIR}" >> ${TARGETDIR}/install.vars
echo "RUNLVLDIR=${RUNLVLDIR}" >> ${TARGETDIR}/install.vars
NOW=`date +%Y%m%d`
echo "INSTALLDATE=$NOW" >> ${TARGETDIR}/install.vars
cat ${INSTALL_DIR}/install.defaults >> ${TARGETDIR}/install.vars
echo "JAVACOMMON=${JAVACOMMON}" >> ${TARGETDIR}/install.vars
echo "${TARGETDIR}/install.vars"


# Definition of ARCHIVE occurred above when we extracted the JAR we need to evaluate Java environment
ARCHIVE=`ls ./*_*.cpi`
cd ${TARGETDIR}
cat "${INSTALL_DIR}/${ARCHIVE}" | gzip -d -c - | cpio -i --no-preserve-owner
cd ${INSTALL_DIR}

#update the configs for file storage

if grep "<manifestPath>.*</manifestPath>" ${TARGETDIR}/conf/default.service.xml > /dev/null
        then
                sed -i "s|<manifestPath>.*</manifestPath>|<manifestPath>${MANIFESTDIR}</manifestPath>|g" ${TARGETDIR}/conf/default.service.xml
        else
                sed -i "s|<backupConfig>|<backupConfig>\n\t\t\t<manifestPath>${MANIFESTDIR}</manifestPath>|g" ${TARGETDIR}/conf/default.service.xml
fi

sed -i "s|</servicePeerConfig>|</servicePeerConfig>\n\t<serviceUIConfig>\n\t\t\
       <serviceHost>0.0.0.0</serviceHost>\n\t\t<servicePort>4243</servicePort>\n\t\t\
       <connectCheck>0</connectCheck>\n\t\t<showFullFilePath>false</showFullFilePath>\n\t\
       </serviceUIConfig>|g" ${TARGETDIR}/conf/default.service.xml

# the log dir
LOGDIR=${TARGETDIR}/log
chmod 777 $LOGDIR

# Install the control script for the service
cp scripts/run.conf ${TARGETDIR}/bin

# desktop init script
GUISCRIPT=${TARGETDIR}/bin/${APP_BASENAME}Desktop
cp scripts/${APP_BASENAME}Desktop ${GUISCRIPT}
chmod 755 ${GUISCRIPT}

# Tweak the ui.properties to docker environment
sed -i -e "s|.*serviceHost.*|serviceHost=172.17.42.1|" ${TARGETDIR}/conf/ui.properties

# Create lib symlink
ln -sf /config/id /var/lib/crashplan

# Fix permissions
chmod -R u-x,go-rwx,go+u,ugo+X /usr/local/crashplan
chmod -R 777 /usr/local/crashplan/bin

# Remove install data
rm -rf ${INSTALL_DIR}
rm /tmp/CrashPlan.tgz

EOT

# create ubuntu user
useradd --create-home --shell /bin/bash --user-group --groups adm,sudo ubuntu
echo "ubuntu:PASSWD" | chpasswd
usermod -u 99 ubuntu
usermod -g 100 ubuntu
bash /opt/install-crashplan.sh

cat <<'EOT' > /usr/local/crashplan/bin/CrashPlanDesktop
#!/bin/bash

SCRIPT=$(ls -l $0 | awk '{ print $NF }')
SCRIPTDIR=$(dirname $SCRIPT)
TARGETDIR="$SCRIPTDIR/.."
export SWT_GTK3=0
. ${TARGETDIR}/install.vars
. ${TARGETDIR}/bin/run.conf

cd ${TARGETDIR}
${JAVACOMMON} ${GUI_JAVA_OPTS} -classpath "./lib/com.backup42.desktop.jar:./lang:./skin" com.backup42.desktop.CPDesktop > ${TARGETDIR}/log/ui_output.log 2> ${TARGETDIR}/log/ui_error.log
EOT

chmod 777 /usr/local/crashplan/bin/CrashPlanDesktop


#########################################
##                 CLEANUP             ##
#########################################

# Clean APT install files
apt-get clean -y
rm -rf /var/lib/apt/lists/* /var/cache/* /var/tmp/* /usr/share/man /usr/share/groff /usr/share/info /usr/share/lintian /usr/share/linda /var/cache/man
find /usr/share/doc -depth -type f ! -name copyright|xargs rm
find /usr/share/doc -empty|xargs rmdir

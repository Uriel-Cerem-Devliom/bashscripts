#!/usr/bin/env bash

# DEVLION.co
# Advanced MOODLE backup bash script
# Author: Sergiy Glynianskyi
# Script start: "backup-moodle-advanced.sh /var/www/moodle" as example. Argument must point to site root (where config.php is located)

# Turn on debug mode here - TOREMOVE later
# set -vx

# Define user's script vars here if needed
AUTODELETEAFTER=7   # Remove backups older 7 days

#-------- Do NOT Edit Below This Line --------#

DATE=$(date +%Y%m%d)

# Check if Site DIR is specified as 1st argument
if [ -z "$1" ]
then
 echo "Provide path to site as argument: /var/www/moodle"
 exit 1
fi
# Strip trailing slashes from SITE_DIR
SITE_DIR=${1%/}

# Check if backup directory exists
BACKUP_DIR="${SITE_DIR%/*}/backup_${SITE_DIR##*/}"
if [ ! -d "${BACKUP_DIR}" ] && [ "$(mkdir -p ${BACKUP_DIR})" ]; then
    echo "Directory not found. The script can't create it, either!"
    echo "Please create it manually and then re-run this script"
    exit 1
fi

# Turn on logging of this script into log file, located in user's HOME dir
LOG_FILE=${BACKUP_DIR}/backup_${DATE}.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# Get auto site DB ans moodledata configs here (for MOODLE)
DB_TYPE=`cat ${SITE_DIR}/config.php | grep dbtype | cut -d \' -f 2`
DB_NAME=`cat ${SITE_DIR}/config.php | grep dbname | cut -d \' -f 2`
DB_USER=`cat ${SITE_DIR}/config.php | grep dbuser| cut -d \' -f 2`
DB_PASSWORD=`cat ${SITE_DIR}/config.php | grep dbpass | cut -d \' -f 2`
DB_HOST=`cat ${SITE_DIR}/config.php | grep dbhost | cut -d \' -f 2`
MDATA=`cat ${SITE_DIR}/config.php | grep dataroot | cut -d \' -f 2`

# Make DB dump in SITE_DIR
echo -n "Dumping database... "
if [ $DB_TYPE == "mysqli" ]; then
	echo "of the MYSQLI type..."
	DUMP_NAME=${DB_NAME}_${DATE}.sql
	mysqldump --user=${DB_USER} --password=${DB_PASSWORD} --host=${DB_HOST} --databases ${DB_NAME} > ${SITE_DIR}/${DUMP_NAME}
	if [ "$?" -ne "0" ]; then
		echo "failed!"
		exit 1
	fi
	echo "done"
else 
	# TODO add another DB_TYPE dumps
	echo "ERROR. Need to create DB backup for other DB type than MYSQLI - PostreSQL, for example. That's all for now"
	exit 1
fi

# Make archive of the backup
echo -n "Creating archive... "
tar -czf ${BACKUP_DIR}/${DATE}.tar.gz ${SITE_DIR} ${MDATA}
if [ "$?" -ne "0" ]; then
	echo "failed!"
	exit 1
fi
echo "done"

# Remove DB backup from SITE_DIR
echo -n "Cleaning... "
rm ${SITE_DIR}/${DUMP_NAME}
if [ "$?" -ne "0" ]; then
	echo "failed!"
	exit 1
fi
# Auto delete backups 
find $BACKUP_DIR -type f -mtime +$AUTODELETEAFTER -exec rm {} \;
if [ "$?" -ne "0" ]; then
	echo "failed!"
	exit 1
fi
echo "done"



# TODO - add upload to FTP/SFTP/AWS/GDrive etc
# TODO - cron tasks


# add to crontab
echo "Don't forget to add this script to cron"
#4 10 * * * /bin/bash /home/yourusername/backup-wp-advanced.sh /var/www/wp

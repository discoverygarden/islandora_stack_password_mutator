#!/bin/bash
#
# @author: William Panting

input_file='./sql_user_pass.input'
sql_file=./mysql_reset.sql
fedora_config_file="$FEDORA_HOME/server/config/fedora.fcfg"

if [ -e /var/www/html ] ; then
	drupal_config_file=/var/www/html/drupal/sites/default/settings.php
else
	drupal_config_file=/var/www/drupal/sites/default/settings.php
fi

. ./drupal_fedora_users.input

#build sql
sql=
file_lines=`cat $input_file`
is_user_line=1
for line in $file_lines
do
	if [ "$is_user_line" = 1 ] ; then
		user=$line
		
		is_user_line=0
	else
		password=$line
		if [ "$user" = "$fedora_user" ] ; then
			fedora_password=$password
		elif [ "$user" = "$drupal_user" ] ; then
			drupal_user="${drupal_user%'@'*}"
			drupal_user="${drupal_user#*'}"
			drupal_password=$password
		fi
		
		user="${user%'@'*}'@'${user#*'@'}"
		sql="$sql SET PASSWORD FOR $user = PASSWORD('$password');"
	 
		is_user_line=1
	fi
done

#commit fedora changes
`echo $fedora_config_file | xargs sed -i "s/<param name=\"dbPassword\" value=\".*\">/<param name=\"dbPassword\" value=\"$fedora_password\">/"`

#commit drupal changes
`echo $drupal_config_file | xargs sed -i "s/$drupal_user:.*@/$drupal_user:$drupal_password@/"`

#commit sql changes
echo $sql > $sql_file
mysql -u root -p < $sql_file
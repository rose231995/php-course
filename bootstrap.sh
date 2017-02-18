#!/usr/bin/env bash

# Variables path
PROJECT_NAME='myproject'
DBUSER='vagrant'
DBPASSWD='vagrant'
DBNAME='myproject'
DBDUMPSQL='/path/to/dump.sql'
php_config_file="/etc/php5/apache2/php.ini"

# create project folder
#sudo mkdir "/var/www/html/${PROJECT_NAME}"

echo "--- Start installation ---"

echo "--- Update / upgrade ---"
sudo apt-get update
sudo apt-get -y upgrade

echo "--- Install base packages ---"
sudo apt-get -y install vim curl build-essential python-software-properties git

echo "--- Install Apache2 ---"
sudo apt-get install -y apache2

echo "--- Install PHP ---"
sudo apt-get install -y php5 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt php5-mysql php-apc

echo "--- Install and configure xDebug ---"
sudo apt-get install -y php5-xdebug

cat << EOF | sudo tee -a ${xdebug_config_file}
xdebug.scream=1
xdebug.cli_color=1
xdebug.show_local_vars=1
EOF

echo "--- Configure php.ini and apache2.conf ---"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${php_config_file}
sed -i "s/display_errors = .*/display_errors = On/" ${php_config_file}
sed -i "s/short_open_tag = .*/short_open_tag = On/" ${php_config_file}

echo "--- Install MySql ---"
echo "mysql-server mysql-server/root_password password ${DBPASSWD}" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password ${DBPASSWD}" | debconf-set-selections
sudo apt-get -y install mysql-server-5.5 mysql-client

mysql -uroot -p${DBPASSWD} -e "CREATE DATABASE ${DBNAME}"
mysql -uroot -p${DBPASSWD} -e "grant all privileges on $DBNAME.* to '${DBUSER}'@'localhost' identified by '${DBPASSWD}'"
mysql -uroot -p${DBPASSWD} ${DBNAME} < ${DBDUMPSQL}

echo "--- Install PhpMyAdmin ---"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    ServerName ${PROJECT_NAME}.local
    DocumentRoot "/var/www/html/${PROJECT_NAME}"
    <Directory "/var/www/html/${PROJECT_NAME}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
sudo a2enmod rewrite

a2enconf phpmyadmin

echo "--- Restart Apache2 ---"
service apache2 restart

echo "--- Restart mysql ---"
service mysql restart

echo "--- Install composer ---"
curl --silent https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "--- Update project components ---"
cd /var/www/html/${PROJECT_NAME}
#sudo -u vagrant -H sh -c "composer install"

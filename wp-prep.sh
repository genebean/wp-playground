yum install -y augeas yum-utils wget \
  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  http://rpms.remirepo.net/enterprise/remi-release-7.rpm

yum-config-manager --enable remi-php72

cat > /etc/yum.repos.d/MariaDB.repo <<"EOF"
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum makecache

yum install -y httpd MariaDB-server MariaDB-client php php-cli php-gd php-curl php-fileinfo php-ldap php-mbstring php-mcrypt php-mysql php-pecl-imagick php-xml php-zip

sed -i 's/^Listen.*/Listen 8080/g' /etc/httpd/conf/httpd.conf

# This allows the permalinks to not include index.php
# Augeas is used so that the script can find the AllowOverrid inside the Directory block for /var/www/html
augtool <<-EOF
set /files/etc/httpd/conf/httpd.conf/Directory[arg='\"/var/www/html\"']/*[self::directive='AllowOverride']/arg ALL
save
quit
EOF

sed -i 's/^max_execution_time.*$/max_execution_time = 300/g' /etc/php.ini
sed -i 's/^max_input_time.*$/max_input_time = 1000/g' /etc/php.ini
sed -i 's/^; max_input_vars.*$/max_input_vars = 2000/g' /etc/php.ini
sed -i 's/^memory_limit.*$/memory_limit = 256M/g' /etc/php.ini
sed -i 's/^post_max_size.*$/post_max_size = 256M/g' /etc/php.ini
sed -i 's/^upload_max_filesize.*$/upload_max_filesize = 256M/g' /etc/php.ini

echo 'start and enable httpd'
systemctl start httpd.service
systemctl enable httpd.service

echo 'start and enable mariadb'
systemctl enable mariadb
systemctl start mariadb

echo 'create WordPress database'
mysql -u root < /vagrant/wp-db.sql

echo 'install WordPress'
cd /root
wget -q -c http://wordpress.org/latest.tar.gz -O - | tar -xz
rsync -aP /root/wordpress/ /var/www/html/
mkdir /var/www/html/wp-content/uploads
chown -R apache:apache /var/www/html/*

echo 'configure WordPress'
cd /var/www/html
cp wp-config-sample.php wp-config.php

sed -i 's/database_name_here/wordpress/g' wp-config.php
sed -i 's/username_here/wordpressuser/g' wp-config.php
sed -i 's/password_here/password/g' wp-config.php

sed -i "2idefine( 'WP_MEMORY_LIMIT', '256M' );" wp-config.php

echo 'install wp-cli'
curl -sS -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

/usr/local/bin/wp --info

echo 'setup WordPress'
/usr/local/bin/wp core install \
  --path='/var/www/html' \
  --url='http://localhost:8080' \
  --title='WP test' \
  --admin_user='admin' \
  --admin_email='root@localhost.localdomain' \
  --admin_password='password' \
  --skip-email

echo 'update WordPress'
/usr/local/bin/wp --path='/var/www/html' plugin update --all
/usr/local/bin/wp --path='/var/www/html' theme update --all

echo 'set WordPress theme'
/usr/local/bin/wp --path='/var/www/html' theme activate twentyseventeen

chown -R apache:apache /var/www/html

cd /vagrant

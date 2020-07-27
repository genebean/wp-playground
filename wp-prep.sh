yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm http://rpms.remirepo.net/enterprise/remi-release-7.rpm yum-utils wget
yum-config-manager --enable remi-php72

cat > /etc/yum.repos.d/MariaDB.repo <<"EOF"
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum makecache

yum install -y httpd MariaDB-server MariaDB-client php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo

sed -i 's/^Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf

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

echo 'install wp-cli'
curl -sS -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

/usr/local/bin/wp --info

echo 'setup WordPress'
/usr/local/bin/wp core install --path='/var/www/html' --url='http://localhost:8080' --title='WP test' --admin_user='admin' --admin_email='root@localhost.localdomain' --admin_password='password' --skip-email

echo 'update WordPress'
/usr/local/bin/wp --path='/var/www/html' plugin update --all
/usr/local/bin/wp --path='/var/www/html' theme update --all

echo 'set WordPress theme'
/usr/local/bin/wp --path='/var/www/html' theme activate twentyseventeen
cd /vagrant

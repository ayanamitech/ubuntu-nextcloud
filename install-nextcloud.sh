#!/bin/bash
###
#
# Install Nextcloud, Nginx, PHP 7.4, Redis, and PostgreSQl all together
#
# https://github.com/linuxserver/docker-nextcloud/blob/master/Dockerfile
#
# Tested on Ubuntu Focal (20.04)
#
###

## MUST RUN THIS SCRIPT AS ROOT!!!!

echo "**** Enter new DB Password ****" && \
read DB_PASSWORD && \
echo "**** Your DB PASSWORD ****" && \
echo ${DB_PASSWORD}

NEXTCLOUD_RELEASE="23.0.5"

echo "**** Will install Nextcloud ${NEXTCLOUD_RELEASE} along with Nginx, Redis, PostgreSQL, and PHP 7.4 ****" && \

echo "**** Install build packages ****" && \
apt-get update && \
apt-get install -y autoconf automake file g++ gcc make php7.4-dev re2c samba-dev zlib1g-dev build-essential

echo "**** Install runtime packages ****" && \
apt-get install -y curl ffmpeg libc6-dev imagemagick libxml2 php-apcu php7.4-bcmath php7.4-bz2 php7.4-common php7.4-curl php7.4-xml php7.4-gd php7.4-gmp php-imagick php7.4-imap php7.4-intl php7.4-ldap php-memcached php7.4-opcache php7.4-mysql php7.4-pgsql php7.4-pgsql php-redis php7.4-sqlite3 php7.4-mbstring php-zip smbclient libsmbclient-dev sudo tar unzip

echo "**** Install Nginx && php7.4-fpm ****" && \
add-apt-repository -y ppa:nginx/stable && \
apt-get install -y nginx php7.4-fpm

echo "**** Install Redis ****" && \
add-apt-repository -y ppa:redislabs/redis && \
apt-get install -y redis-server && \
systemctl enable redis-server

echo "**** Install PostgreSQl ****" && \
wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'  && \
apt-get update && \
apt-get install postgresql postgresql-contrib -y

echo "**** Create DB & DB USER ****" && \
sudo -Hiu postgres psql -c "CREATE DATABASE nextcloud TEMPLATE template0 ENCODING 'UNICODE'" && \
sudo -Hiu postgres psql -c "CREATE USER nextcloud WITH PASSWORD '${DB_PASSWORD}'" && \
sudo -Hiu postgres psql -c "ALTER DATABASE nextcloud OWNER TO nextcloud" && \
sudo -Hiu postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud"

echo "**** Compile Smbclient ****" && \
git clone https://github.com/eduardok/libsmbclient-php.git /tmp/smbclient && \
  cd /tmp/smbclient && \
  phpize && \
  ./configure && \
  make && \
  make install

echo "**** Configure PHP and Nginx for Nextcloud ****" && \
  echo "extension="smbclient.so"" > /etc/php/7.4/fpm/conf.d/00_smbclient.ini && \
  echo 'apc.enable_cli=1' >> /etc/php/7.4/fpm/conf.d/apcu.ini && \
  sed -i \
    -e 's/;opcache.enable.*=.*/opcache.enable=1/g' \
    -e 's/;opcache.interned_strings_buffer.*=.*/opcache.interned_strings_buffer=16/g' \
    -e 's/;opcache.max_accelerated_files.*=.*/opcache.max_accelerated_files=10000/g' \
    -e 's/;opcache.memory_consumption.*=.*/opcache.memory_consumption=128/g' \
    -e 's/;opcache.save_comments.*=.*/opcache.save_comments=1/g' \
    -e 's/;opcache.revalidate_freq.*=.*/opcache.revalidate_freq=1/g' \
    -e 's/;always_populate_raw_post_data.*=.*/always_populate_raw_post_data=-1/g' \
    -e 's/memory_limit.*=.*128M/memory_limit=8092M/g' \
    -e 's/max_execution_time.*=.*30/max_execution_time=120/g' \
    -e 's/upload_max_filesize.*=.*2M/upload_max_filesize=8092M/g' \
    -e 's/post_max_size.*=.*8M/post_max_size=8092M/g' \
      /etc/php/7.4/fpm/php.ini && \
  sed -i \
    '/opcache.enable=1/a opcache.enable_cli=1' \
      /etc/php/7.4/fpm/php.ini && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php/7.4/fpm/php-fpm.conf && \
  systemctl restart php7.4-fpm && \
  rm -r /tmp/smbclient && cd $ROOT

echo "**** Download Nextcloud ****" && \
  curl -o nextcloud.zip -L \
    https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_RELEASE}.zip && \
  unzip nextcloud.zip && \
  curl -o nextcloud/config/config.php -L \
    https://raw.githubusercontent.com/ayanamitech/ubuntu-nextcloud/main/config.php && \
  sed -i "s/replacethisdbpasswordplz/${DB_PASSWORD}/g" \
    nextcloud/config/config.php && \
  mv nextcloud /var/www/nextcloud && \
  chown -R www-data:www-data /var/www && \
  find /var/www -type d -exec chmod 2775 {} \; && \
  find /var/www -type f -exec chmod ug+rw {} \;

echo "**** Generate self signed SSL certificate ****" && \
IP_ADDR=$(curl -4 ifconfig.co)
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout example.key -out example.crt -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:${IP_ADDR}" && \
chmod 400 example.key && \
mv example.key /etc/nginx/example.key && \
mv example.crt /etc/nginx/example.crt

echo "**** Configure Nginx ****" && \
rm /etc/nginx/sites-enabled/default && \
curl -o /etc/nginx/sites-enabled/nextcloud -L \
  https://raw.githubusercontent.com/ayanamitech/ubuntu-nextcloud/main/nextcloud.conf

echo "**** Testing Nginx ****" && \
nginx -t && \
service nginx reload

echo "**** Installing systemd files to run cron job ****" && \
curl -o /etc/systemd/system/nextcloud.service -L \
  https://raw.githubusercontent.com/ayanamitech/ubuntu-nextcloud/main/nextcloud.service && \
curl -o /etc/systemd/system/nextcloud.timer -L \
  https://raw.githubusercontent.com/ayanamitech/ubuntu-nextcloud/main/nextcloud.timer

echo "**** Run systemctl enable --now nextcloud.timer to enable cron job after initiating Nextcloud ****"  && \

echo "**** Nextcloud installed on https://${IP_ADDR} ****" && \
echo "**** DB: PostgreSQl ****" && \
echo "**** DB USER: nextcloud ****" && \
echo "**** DB PASSWORD: ${DB_PASSWORD} ****" && \
echo "**** DB NAME: nextcloud ****"

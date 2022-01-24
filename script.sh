#!/bin/bash

### PREFERENCES
export DB_ROOT_PASS="myRootDbPassword2X";
export PHP_CHOOSED="8.0"
export PHP_VERSIONS_TO_INSTALL=('5.6' '7.0' '7.1' '7.2' '7.3' '7.4' '8.0')

log(){
  msg=$1;
  echo -e "**************************************************************************\n"
  echo -e "$msg\n"
  echo -e "**************************************************************************\n"
}

### Install locales-all
log "Install locales-all..."
sudo -E apt-get -yqq update
sudo apt-get install locales-all

### Export env...
log "Export env..."
export DEBIAN_FRONTEND=noninteractive
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

### Generate locales (en_US, pt_BR)
log "Generate locales (en_US, pt_BR)...."
sudo -E locale-gen en_US.UTF-8
sudo -E locale-gen pt_BR.utf8

### PHP Repository
log "Add PHP Repository..."
sudo -E apt -y install lsb-release apt-transport-https ca-certificates
sudo -E wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo -E tee /etc/apt/sources.list.d/php.list

### Updating repository
log "Updating repository..."
sudo -E apt-get -yqq update
sudo -E apt-get -y upgrade

# Remove unattended upgrades
log "Remove unattended upgrades..."
sudo -E apt-get purge -y unattended-upgrades

# Install common packages
log "Install common packages..."
sudo -E apt-get install -y imagemagick gettext git unzip curl vim openssl

### Installing net-tools (ipconfig, route...)
log "Installing net-tools (ipconfig, route...)..."
sudo -E apt-get -y install net-tools

### Apply and Display Motd
#sudo -E sed -i 's/PrintMotd no/PrintMotd yes/g' /etc/ssh/sshd_config
sudo -E systemctl restart sshd.service
sudo -E cp -f /vagrant/motd /etc/motd

### Installing Apache
echo "Instaling Apache..."
sudo -E apt-get -y install apache2
# sudo -E apt-get -y install libapache2-mpm-itk

for pv in ${PHP_VERSIONS_TO_INSTALL[*]}; do
  ### PHP 5.6
  if [[ " ${pv} " = *" 5.6 "* ]]; then
    log "Instaling PHP 5.6..."
    sudo -E apt-get -y install php5.6 libapache2-mod-php5.6
    mod="curl,gd,imap,intl,ldap,mbstring,mcrypt,mysql,pgsql,tidy,xml,xsl,zip,xdebug"
    eval sudo -E apt-get -y install php5.6-{$mod}
  ### PHP 7x
  elif [[ " ${pv} " = *" 7"* ]]; then
    log "Instaling PHP ${pv}..."
    sudo -E apt-get -y install php${pv} libapache2-mod-php${pv}
    mod="curl,gd,imap,intl,ldap,mbstring,mcrypt,mysql,pgsql,tidy,xml,xsl,zip,xdebug"
    eval sudo -E apt-get -y install php${pv}-{$mod}
  ## PHP 8x
  elif [[ " ${pv} " = *" 8"* ]]; then
    log "Instaling PHP ${pv}..."
    sudo -E apt-get -y install php${pv} libapache2-mod-php${pv}
    mod="mysql,cli,common,imap,ldap,xsl,tidy,xml,fpm,curl,bcmath,bz2,intl,gd,mbstring,zip,xdebug"
    eval sudo -E apt-get -y install php${pv}-{$mod}
  fi
done

### Instaling PHP and additional packages
log "Instaling PHP and additional packages..."
sudo -E apt-get -y install php-imagick php-mongo php-oauth php-pear php-ssh2

### Configuring Apache
log "Configuring Apache..."
sudo -E a2enmod filter deflate mime expires rewrite proxy_fcgi setenvif

if [ ! -e /etc/apache2/sites-available/000-default.conf.BAK ]; then
  mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.BAK
fi
if [ ! -e /etc/apache2/sites-available/default-ssl.conf.BAK ]; then
  mv /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.BAK
fi
cp -f /vagrant/apache2/000-default.conf /etc/apache2/sites-available/

log "Configuring Apache for HTTPS..."
sudo -E a2enmod ssl headers
sudo -E a2ensite default-ssl.conf
sudo -E mkdir -p /etc/apache2/certs
sudo -E echo -e 'BR\nSanta Catarina\nJaragua do sul\nInternet Widgits Pty Ltd\n\nlocalhost\nadmin@your_domain.com\n' |openssl \ 
  req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/apache2/certs/apache-selfsigned.key -out /etc/apache2/certs/apache-selfsigned.crt
cp -f /vagrant/apache2/ssl-params.conf /etc/apache2/conf-available/
cp -f /vagrant/apache2/default-ssl.conf /etc/apache2/sites-available/
sudo -E a2enconf ssl-params

### Configuring PHP
log "Configuring PHP..."
sudo -E phpdismod opcache
sudo -E phpdismod xdebug

### Switching PHP version
if [ ! -z ${PHP_CHOOSED} ]; then
  log "Switching PHP version..."
  PHP_BIN=`which php${PHP_CHOOSED}`
  ## Change PHP version on CLI
  sudo -E update-alternatives --set php ${PHP_BIN} >/dev/null
  ## Change PHP (module) version on Apache
  for mod in $(cd /etc/apache2/mods-enabled/; ls -A php*.load); do
    sudo -E a2dismod $mod > /dev/null
  done
  sudo -E a2enconf php${PHP_CHOOSED}-fpm
  sudo -E a2enmod php${PHP_CHOOSED}

  sudo -E service apache2 restart

  log "PHP version switched to version ${PHP_CHOOSED}."
fi

# Install PHP Composer package manager
log "Install PHP Composer package manager..."
curl -sS https://getcomposer.org/installer | php
sudo -E mv composer.phar /usr/local/bin/composer
sudo -E chmod +x /usr/local/bin/composer

# Apache Tests
log "Apache config test..."
sudo -E apache2ctl configtest

### Installing MariaDB (Database)
log "Installing MariaDB (Database)..."
sudo -E apt-get -y install mariadb-server

### Set root password for MariaDB access
log "Set root password for MariaDB access..."
sudo -E mysql_secure_installation 2>/dev/null <<MSI

n
y
${DB_ROOT_PASS}
${DB_ROOT_PASS}
y
y
y
y

MSI


### Remove APT archives
log "Remove APT archives..."
sudo -E apt-get clean

# Clear Bash history and exit
log "Clear Bash history and exit..."
cat /dev/null > ~/.bash_history && history -c && exit

#!/bin/bash

apache_config_file="/etc/apache2/envvars"
apache_vhost_file="/etc/apache2/sites-available/001-oac.conf"
php_config_file="/etc/php5/apache2/php.ini"
mysql_config_file="/etc/mysql/my.cnf"
default_apache_index="/var/www/html/index.html"
proftpd_config_file="/etc/proftpd/proftpd.conf"
proftpd_rsa_pem="/etc/proftpd/ftpd-rsa.pem"
proftpd_rsa_key_pem="/etc/proftpd/ftpd-rsa-key.pem"
wp_cli_phar="/home/ontar026/wp-cli.phar"
postfix_main_cf="/etc/postfix/main.cf"
postfix_virtual="/etc/postfix/virtual"
postfix_header_checks="/etc/postfix/header_checks"
postfix_local="/etc/postfix/local.cf"
spamassassin="/etc/default/spamassassin"

# This function is called at the very bottom of the file
main() {
    update_go

    if [[ -e /var/lock/vagrant-provision ]]; then
        cat 1>&2 << EOD
################################################################################
# To re-run full provisioning, delete /var/lock/vagrant-provision and run
#
#    $ vagrant provision
#
# From the host machine
################################################################################
EOD
        exit
    fi

    network_go
    tools_go
    mail_go
    users_go
    apache_go
    php_go
    mysql_go
    proftpd_go

    touch /var/lock/vagrant-provision
}

update_go() {
    # Update the server
    sed -i "s/jessie main\$/jessie main contrib non-free/g" /etc/apt/sources.list
    sed -i "s/updates main\$/updates main contrib non-free/g" /etc/apt/sources.list
    apt-get update

    # comment out these lines if not using Vagrant debian image
    echo "set grub-pc/install_devices /dev/sda" | debconf-communicate
    sed -i "s/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/g" /etc/default/grub
    apt-get -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
    sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g" /etc/default/grub
}

network_go() {
    IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')
    sed -i "s/^${IPADDR}.*//" /etc/hosts
    #echo ${IPADDR} ubuntu.localhost >> /etc/hosts          # Just to quiet down some error messages
}

tools_go() {
    # Install basic tools
    apt-get -y install build-essential binutils-doc git emacs24-nox unzip curl

    apt-get -y install dkms virtualbox-guest-utils 
}

mail_go() {
    apt-get -y install postfix spamassassin spamd postsrsd

    cat << EOF > ${postfix_main_cf}
# See /usr/share/postfix/main.cf.dist for a commented, more complete version


# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname

smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# See /usr/share/doc/postfix/TLS_README.gz in the postfix-doc package for
# information on enabling SSL in the smtp client.

alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = localhost, localhost.localdomain, localhost
relayhost = 
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

virtual_alias_domains = ontarioaccesscoalition.com
virtual_alias_maps = hash:/etc/postfix/virtual

# spam
smtpd_client_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination reject_rbl_client zen.spamhaus.org reject_rbl_client bl.spamcop.net reject_rbl_client cbl.abuseat.org reject_unknown_client permit
header_checks = regexp:/etc/postfix/header_checks
EOF
    cat << EOF > ${postfix_virtual}
webmaster@ontarioaccesscoalition.com prof.lam@gmail.com
info@ontarioaccesscoalition.com akolos@hotmail.com laura.alexis.banks@gmail.com mprisner@gmail.com prof.lam@gmail.com tony.berlier@sympatico.ca

chair@ontarioaccesscoalition.com tony.berlier@sympatico.ca
climbingaccess@ontarioaccesscoalition.com chair@ontarioaccesscoalition.com
membership@ontarioaccesscoalition.com chair@ontarioaccesscoalition.com
oac@ontarioaccesscoalition.com chair@ontarioaccesscoalition.com akolos@hotmail.com
tony.berlier@ontarioaccesscoalition.com tony.berlier@sympatico.ca
treasurer@ontarioaccesscoalition.com akolos@hotmail.com
volunteer@ontarioaccesscoalition.com mprisnr@gmail.com
oacapproved@ontarioaccesscoalition.com akolos@hotmail.com
EOF
    cat << EOF > ${postfix_header_checks}
/^X-Spam-Level: \*{5,}.*/ DISCARD spam
EOF
    cat << EOF > ${postfix_local}
rewrite_header Subject *****SPAM*****
EOF

    groupadd spamd
    useradd -g spamd -s /bin/false -d /var/log/spamassassin spamd
    mkdir /var/log/spamassassin
    chown spamd:spamd /var/log/spamassassin

    cat << EOF > ${spamassassin}
# /etc/default/spamassassin
# Duncan Findlay

# WARNING: please read README.spamd before using.
# There may be security risks.

# If you're using systemd (default for jessie), the ENABLED setting is
# not used. Instead, enable spamd by issuing:
# systemctl enable spamassassin.service
# Change to "1" to enable spamd on systems using sysvinit:
ENABLED=1

# Options
# See man spamd for possible options. The -d option is automatically added.

# SpamAssassin uses a preforking model, so be careful! You need to
# make sure --max-children is not set to anything higher than 5,
# unless you know what you're doing.

SAHOME="/var/log/spamassassin"
OPTIONS="--create-prefs --max-children 5 --helper-home-dir --username spamd -H ${SAHOME} -s ${SAHOME}spamd.log"

# Pid file
# Where should spamd write its PID to file? If you use the -u or
# --username option above, this needs to be writable by that user.
# Otherwise, the init script will not be able to shut spamd down.
PIDFILE="/var/run/spamd.pid"

# Set nice level of spamd
#NICE="--nicelevel 15"

# Cronjob
# Set to anything but 0 to enable the cron job to automatically update
# spamassassin's rules on a nightly basis
CRON=1

EOF
    service spamassassin start
}

users_go() {
    useradd -m -G www-data -s /bin/bash ontar026
    curl -s -o ${wp_cli_phar} https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
}

apache_go() {
    # Install Apache
    apt-get -y install apache2

    cat << EOF > ${apache_vhost_file}
<VirtualHost *:80>
    # The ServerName directive sets the request scheme, hostname and port that
    # the server uses to identify itself. This is used when creating
    # redirection URLs. In the context of virtual hosts, the ServerName
    # specifies what hostname must appear in the request's Host: header to
    # match this virtual host. For the default virtual host (this file) this
    # value is not decisive as it is used as a last resort host regardless.
    # However, you must set it for any further virtual host explicitly.
    ServerName www.ontarioaccesscoalition.com

    ServerAdmin prof.lam@gmail.com
    DocumentRoot /home/ontar026/public_html/

    # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
    # error, crit, alert, emerg.
    # It is also possible to configure the loglevel for particular
    # modules, e.g.
    #LogLevel info ssl:warn

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    # For most configuration files from conf-available/, which are
    # enabled or disabled at a global level, it is possible to
    # include a line for only one particular virtual host. For example the
    # following line enables the CGI configuration for this host only
    # after it has been globally disabled with "a2disconf".
    #Include conf-available/serve-cgi-bin.conf
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF

    cat <<EOF >> /etc/apache2/apache2.conf
<Directory /home/ontar026/public_html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>
EOF

    a2dissite 000-default
    a2ensite 001-oac

    a2enmod rewrite

    service apache2 reload
    update-rc.d apache2 enable
}

php_go() {
    apt-get -y install php5 php5-curl php5-mysql php5-sqlite php5-xdebug php5-gd libapache2-mod-php5

    sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" ${php_config_file}
    sed -i "s/display_errors = Off/display_errors = On/g" ${php_config_file}

    service apache2 reload
}

mysql_go() {
    # Install MySQL
    echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections
    apt-get -y install mysql-client mysql-server

    sed -i "s/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" ${mysql_config_file}

    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION" | mysql -u root --password=root
    echo "CREATE USER 'ontar026_blog'@'localhost' IDENTIFIED BY 'changeme';" | mysql -u root --password=root
    echo "CREATE DATABASE ontar026_wordpress;" | mysql -u root --password=root
    echo "GRANT ALL PRIVILEGES ON ontar026_wordpress.* TO ontar026_blog;" | mysql -u root --password=root

    echo "CREATE USER 'civicrm'@'localhost' IDENTIFIED BY 'changeme';" | mysql -u root --password=root
    echo "CREATE DATABASE civicrm;" | mysql -u root --password=root
    echo "GRANT ALL PRIVILEGES ON civicrm.* TO civicrm;" | mysql -u root --password=root

    service mysql restart
    update-rc.d apache2 enable
}

proftpd_go() {
    echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections
    apt-get -y install proftpd
    openssl req -new -x509 -days 365 -nodes \
       -subj "/C=CA/ST=Ontario/L=Toronto/O=Ontario Access Coalition/CN=www.ontarioaccesscoalition.com" -out ${proftpd_rsa_pem} \
       -keyout ${proftpd_rsa_key_pem}

    cat << EOF > ${proftpd_config_file}
<IfModule mod_tls.c>
   TLSEngine on
   TLSLog /var/log/proftpd-tls.log
   TLSProtocol TLSv1

   # Are clients required to use FTP over TLS when talking to this server?
   TLSRequired off

   TLSRSACertificateFile    /etc/proftpd/ftpd-rsa.pem
   TLSRSACertificateKeyFile /etc/proftpd/ftpd-rsa-key.pem
    
   # Authenticate clients that want to use FTP over TLS?
   TLSVerifyClient off
</IfModule>
DefaultRoot ~
EOF

}

main
exit 0

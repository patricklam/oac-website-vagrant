WordPress installation notes
============================

To migrate a WP install from another site:

- modified wp_config.php for sitename

```mysql> update oac_wp_options set option_value="http://localhost:8080" where option_id=1;

mysql> update oac_wp_options set option_value="http://localhost:8080" where option_id=37;

mysql> update oac_wp_options set option_value='a:1:{s:12:"header_image";s:78:"/wp-content/uploads/2011/01/cropped-OacBanner.jpg";}' where option_id=10401;

mysql> update oac_wp_options set option_value='/vagrant/src/wp-content/themes/k2/styles' where option_id=156;

mysql> update oac_wp_options set option_value='http://localhost:8080/wp-content/themes/k2/styles' where option_id=157;
```

CiviCRM installation notes
==========================

- installation directions at http://wiki.civicrm.org/confluence/display/CRMDOC/WordPress+Installation+Guide+for+CiviCRM+4.5
- download CiviCRM, https://civicrm.org/download/list
- unzip civicrm zip file in wp-content/plugins
- create wp-content/plugins/files writable by www-data
- chgrp www-data wp-content/plugins/civicrm; chmod g+w wp-content/plugins/civicrm
- CREATE DATABASE civicrm
- GRANT ALL ON civicrm.* TO 'civicrm'@'localhost' IDENTIFIED BY <pw>;
- `http://sitename/wp-admin/plugins.php`: activate/configure CiviCRM
- after doing the configure, back up <wordpress>/wp-content/plugins/civicrm/civicrm.settings.php

- admin page: `http://oac-dev.patricklam.ca/wp-admin/admin.php?page=CiviCRM`

- import: can't figure out how to import join date with CiviCRM 4.6
   * need to change Ontario to ON? no, that doesn't work, but can manually adjust

Limesurvey installation notes
=============================

$ adduser limesurvey
$ su - limesurvey
$ mkdir store
$ cd store
$ wget "https://www.limesurvey.org/en/stable-release?download=1413:limesurvey206plus-build151215tarbz2"
$ mv stable-release\?download\=1413\:limesurvey206plus-build151215tarbz2 limesurvey206plus-build151215.tar.bz2
$ mkdir ~/public_html
$ cd ../public_html
$ tar xjvf ../store/limesurvey206plus-build151215.tar.bz2
$ chgrp -R www-data .
$ chmod -R g+w .


running as oac-survey.patricklam.ca, set up 002-limesurvey.conf
<VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	ServerName oac-survey.patricklam.ca

	ServerAdmin prof.lam@gmail.com
	DocumentRoot /home/limesurvey/public_html/limesurvey/

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	#LogLevel info ssl:warn

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with "a2disconf".
	#Include conf-available/serve-cgi-bin.conf
</VirtualHost>

<Directory /home/limesurvey/public_html/limesurvey>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet

$ a2ensite 002-limesurvey
$ service apache2 reload
$ sudo apt-get install php5-gd php5-imap
$ mysql -u root -p
mysql> CREATE USER 'limesurvey'@'localhost' IDENTIFIED BY <pw>;

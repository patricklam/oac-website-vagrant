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


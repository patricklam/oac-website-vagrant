OAC Website Configuration
=========================

This is a Vagrant configuration for the OAC website. As seen in the Vagrantfile,
it assumes a Debian jessie base box.

After running bootstrap.sh (in Vagrant, just `vagrant up` will do that for you),
you still need to import data and set passwords. Here's what you need to add:

* passwords/ssh keys for the `ontar026` Linux user;
* passwords for the MySQL `root` (default pw = `root`) and `ontar026_blog` users;
  + `ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass';`
  + `ALTER USER 'ontar026_blog'@'localhost' IDENTIFIED BY 'MyNewPass';`
  or, under current MySQL:
  + SET PASSWORD FOR 'root'@'localhost' = PASSWORD('MyNewPass');
  + SET PASSWORD FOR 'ontar026_blog'@'localhost' = PASSWORD('MyNewPass');
* the contents of the `ontar026_wordpress` database;
  + `mysql ontar026_wordpress < SQL-file`
* the `public_html` filesystem under /home/ontar026/public_html (mounted from `src/` subdir on host).
  + update usernames/passwords in `public_html/wp-config.php`.
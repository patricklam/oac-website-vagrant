OAC Website Configuration
=========================

This is a Vagrant configuration for the OAC website. As seen in the Vagrantfile,
it assumes a Debian jessie base box.

After running bootstrap.sh (in Vagrant, just `vagrant up` will do that for you),
you still need to import data and set passwords. Here's what you need to add:

* passwords/ssh keys for the `ontar026` Linux user;
* passwords for the MySQL `root` and `ontar026_blog` users;
* the contents of the `ontar026_wordpress` database;
* the `public_html` filesystem under /home/ontar026/public_html,
  + with an update to usernames/passwords in `public_html/wp-config.php`.
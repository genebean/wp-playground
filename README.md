# WordPress Playground

This is a simple Vagrant-based setup of WordPress running with the following components:

- CentOS 7
- Apache 2.4
- MariaDB 10.2
- PHP 7.2
- WordPress (latest)
- wp-cli

| App       | User          | Password | Notes             |
|-----------|---------------|----------|-------------------|
| MariaDB   | root          |          | there isn't one   |
| MariaDB   | wordpressuser | password | used by WordPress |
| WordPress | admin         | password |                   |

After running `vagrant up` you should be able to access the site at [http://localhost:8080](http://localhost:8080)

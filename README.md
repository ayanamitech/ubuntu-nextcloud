# ubuntu-nextcloud

Spin up Nextcloud instance from Ubuntu server, without the help of docker


### Install Nextcloud 23.0.5, Nginx, Redis, Postgresql, and PHP 7.4 in one command

```
# Run this as a root user

curl -fsSL https://raw.githubusercontent.com/ayanamitech/ubuntu-nextcloud/main/install-nextcloud.sh | sudo -E bash -
```

The command above will install all the necessary libraries & dependencies for spinning up fastest, bug free Nextcloud instance to your clean Ubuntu server.

Also, it will automate populating the DB so you don't need to enter those SQL queries while spinning up the server every time.

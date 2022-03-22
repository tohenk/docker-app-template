# Docker App Template

A docker compose template to deploy app with PHP, Apache, MySQL, MongoDB, and Nodejs.

## MySQL Database From SQL

Create a named directory under `sql` as the database name and include the corresponding
*.sql files into those directory. `init-db.sh` will pick those files and import it
upon database initialization.

## SSHD on PHP container

To enable OpenSSH Server on PHP container simply drop `id_rsa.pub` in `config/hostkey`
folder.

## SSL Certificate

SSL certificate can be drop in `config/cert`. The suggested name for certficates would
be `cert.key` and `cert.crt-combined`.

# Docker App Template

A docker compose template to deploy app with PHP, Nodejs, Apache, Nginx, MySQL, MongoDB,
and CRON.

## MySQL Database From SQL

Create a named directory under `data/sql` as the database name and include the corresponding
*.sql files into those directory. `init-db.sh` will pick those files and import it
upon database initialization.

## MySQL Database Patches SQL

To apply a SQL patch to the database, use the following directory layout:
```
data/
  patches/
    1/
      mydb/
        patch1.sql
      mydb2/
        patch1.sql
    2/
      mydb/
        patch2.sql
```
You need to restart the container to apply those patches.

## OpenSSH Server on PHP container

OpenSSH Server on PHP container is useful to perform background task using SSH, such task
then can be executed from within CRON container. To enable OpenSSH Server on PHP container
simply drop `id_rsa.pub` in `config/hostkey` folder.

## SSL Certificate

SSL certificate can be dropped in `config/cert`. The suggested name for certficates would
be `cert.key` and `cert.crt-combined`.

## Customizable Container Initialization

To perform an initialization to each container is simplified thanks to [run-script.sh](/bin/run-script.sh).
Write a script snippet and placed it in `scripts` folder then run the initialization in
container command.

```yaml
services:
  cron:
    command:
      - /bin/bash
      - '-c'
      - |
        export CRON_DIR=/cron
        export TARGET_DIR=$${CRON_DIR}
        export ENV_FILE_PATTERN=/config/*.env
        # run initialization
        run-script.sh timezone apt cron hostkey ssh mongodb-client mysql-client genenv
        # start cron
        echo "Starting cron..."
        cron -f -L 15
```

To run a script is use the following convention:

```
run-script.sh [+]script[:alias] [...]
```

|          |                                                                                                                                                                |
|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `+`      | If provided, run the script in backgroud                                                                                                                       |
| `script` | The script name found on `scripts` folder without `.sh` extension                                                                                              |
| `alias`  | Alias can be useful to avoid name collision, suppose there are `init` scripts between containers, so it can be written as `php-init:init` and `node-init:init` |

There are predefined scripts to allow the container customization as shown below.

| Script                                       | Description                                                                                                                                                        |
|----------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [apache](/scripts/apache.sh)                 | Set apache default configuration from `APACHE_APP_CONF` env also enable SSL and rewrite module                                                                     |
| [apt](/scripts/apt.sh)                       | Set Debian mirror from `APT_MIRROR` env and update APT to the latest                                                                                               |
| [cron](/scripts/cron.sh)                     | Setup CRON in the container, expects `CRON_DIR` env for location of cron files such as `crontab.prod`                                                              |
| [genenv](/scripts/genenv.sh)                 | Generate environment file from environment variables in `TARGET_DIR` env using file pattern `ENV_FILE_PATTERN` env                                                 |
| [hostkey](/scripts/hostkey.sh)               | Setup host key files `id_rsa` and `id_rsa.pub` from `config/hostkey` folder                                                                                        |
| [init-db](/scripts/init-db.sh)               | Used by MySQL container to intialize databases                                                                                                                     |
| [mongodb-client](/scripts/mongodb-client.sh) | Setup MongoDB APT repository and install MongoDB client utilities such as `mongodump`                                                                              |
| [mysql-client](/scripts/mysql-client.sh)     | Setup MySQL APT repository and install MySQL client utilities such as `mysqldump`                                                                                  |
| [npm-install](/scripts/npm-install.sh)       | Install node modules dependencies in `TARGET_DIR` env if necessary                                                                                                 |
| [patch-db](/scripts/patch-db.sh)             | Used by MySQL container to patch the databases upon container start                                                                                                |
| [php](/scripts/php.sh)                       | Perform PHP extensions bootstrapping by built and compile if necessary, default enabled extensions are `gd`, `mysqli`, `pdo_mysql`, `zip`, `mongodb`, and `xdebug` |
| [ready](/scripts/ready.sh)                   | Create `/tmp/.ready` file                                                                                                                                          |
| [ssh](/scripts/ssh.sh)                       | Setup OpenSSH Client                                                                                                                                               |
| [sshd](/scripts/sshd.sh)                     | Setup OpenSSH Server, needs `id_rsa.pub`                                                                                                                           |
| [sync-src](/scripts/sync-src.sh)             | Copy distribution source files (`/src/dist/app.tgz`) to `TARGET_DIR` env, also `COPY_FILES` env accepts additional files in `/config` to copy to target directory  |
| [timezone](/scripts/timezone.sh)             | Apply system timezone from `APP_TIMEZONE` env                                                                                                                      |

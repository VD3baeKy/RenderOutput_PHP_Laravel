#!/bin/bash
set -e

# MariaDBの初期設定（初回起動時のみ実行）
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    echo "MariaDB data directory initialized."

    # MariaDBを一時的に起動して初期ユーザーを設定
    /usr/sbin/mysqld --skip-grant-tables --bind-address=127.0.0.1 &
    MYSQL_PID=$!

    # MariaDBが起動するまで待機
    for i in {30..0}; do
        if echo 'SELECT 1' | mysql -h 127.0.0.1 --port=3306 &> /dev/null; then
            break
        fi
        echo 'MariaDB starting up...'
        sleep 1
    done
    if [ "$i" -eq 0 ]; then
        echo >&2 'MariaDB did not start up.'
        exit 1
    fi

    echo "Setting up MariaDB root password and user..."
    # rootパスワードの設定
    mysql -h 127.0.0.1 --port=3306 -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

    # データベースとユーザーの作成、権限付与
    mysql -h 127.0.0.1 --port=3306 -e "CREATE DATABASE IF NOT EXISTS \`${DB_DATABASE}\` COLLATE utf8mb4_unicode_ci;"
    mysql -h 127.0.0.1 --port=3306 -e "CREATE USER IF NOT EXISTS '${DB_USERNAME}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -h 127.0.0.1 --port=3306 -e "GRANT ALL PRIVILEGES ON \`${DB_DATABASE}\`.* TO '${DB_USERNAME}'@'localhost';"
    mysql -h 127.0.0.1 --port=3306 -e "FLUSH PRIVILEGES;"

    kill ${MYSQL_PID}
    wait ${MYSQL_PID}
    echo "MariaDB setup complete."
fi

# MariaDBのデータディレクトリの所有者をmysqlユーザーに変更（念のため）
chown -R mysql:mysql /var/lib/mysql

# Supervisorを起動
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf

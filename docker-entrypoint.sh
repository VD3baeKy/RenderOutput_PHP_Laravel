#!/bin/bash
set -ex

# MariaDBの初期設定（初回起動時のみ実行）
# /var/lib/mysql/mysql が存在しない場合、つまりデータディレクトリが空の場合に初期化を実行
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    # データディレクトリの所有者をmysqlユーザーに変更
    chown -R mysql:mysql /var/lib/mysql
    # MariaDBのデータディレクトリを初期化
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    echo "MariaDB data directory initialized."

    # MariaDBを一時的に起動して初期ユーザーを設定
    # --bind-address=127.0.0.1 は、一時起動中に外部からの接続を受け付けないようにするため
    /usr/sbin/mysqld --skip-grant-tables --bind-address=127.0.0.1 &
    MYSQL_PID=$!
    
    # MariaDBが完全に起動するまで待機（最大30秒）
    echo "Waiting for MariaDB to start up..."
    for i in {30..0}; do
        if echo 'SELECT 1' | mysql -h 127.0.0.1 --port=3306 -u root &> /dev/null; then
            break
        fi
        echo 'MariaDB is not yet ready, waiting...'
        sleep 1
    done
    if [ "$i" -eq 0 ]; then
        echo >&2 'MariaDB did not start up. Exiting.'
        exit 1
    fi
    echo "MariaDB is running."

    echo "Setting up MariaDB root password and user..."
    # rootパスワードの設定 (環境変数 MYSQL_ROOT_PASSWORD を使用)
    # デフォルトのrootユーザーは'root'@'localhost'
    mysql -h 127.0.0.1 --port=3306 -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
    
    # データベースとユーザーの作成、権限付与 (環境変数 DB_DATABASE, DB_USERNAME, DB_PASSWORD を使用)
    mysql -h 127.0.0.1 --port=3306 -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${DB_DATABASE}\` COLLATE utf8mb4_unicode_ci;"
    mysql -h 127.0.0.1 --port=3306 -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${DB_USERNAME}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -h 127.0.0.1 --port=3306 -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${DB_DATABASE}\`.* TO '${DB_USERNAME}'@'localhost';"
    mysql -h 127.0.0.1 --port=3306 -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

    # 一時的に起動したMariaDBプロセスを終了
    kill ${MYSQL_PID}
    wait ${MYSQL_PID} # プロセスが完全に終了するのを待つ
    echo "MariaDB setup complete."
else
    echo "MariaDB data directory already exists. Skipping initialization."
fi

# MariaDBのデータディレクトリの所有者をmysqlユーザーに変更（念のため。初回起動時以外も安全のため実行）
# これは初回初期化時に行われますが、念のためここに残す。
chown -R mysql:mysql /var/lib/mysql

# Supervisorを起動
# SupervisorがNginx、PHP-FPM、MariaDBを管理する
echo "Starting Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf

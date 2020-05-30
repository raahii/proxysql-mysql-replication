/* proxysql user */
CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED WITH sha256_password BY 'monitor';
/* slave user */
CREATE USER IF NOT EXISTS 'slave_user'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

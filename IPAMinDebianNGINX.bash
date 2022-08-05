# System Version: Debian 11.4.0
# Step 1: MariaDB setup
sudo apt update
sudo apt install mariadb-server mariadb-client
sudo systemctl enable mariadb
sudo systemctl start mariadb
sudo mysql_secure_installation
# Answer y for all the questions, change the root password
# Login to MariaDB:
sudo mysql -u root -p
# Excute below, replace <PASSWORD> to our phpipam password, and update it in Lastpass :
CREATE DATABASE phpipam;
GRANT ALL ON phpipam.* TO phpipam@localhost IDENTIFIED BY '<PASSWORD>';
FLUSH PRIVILEGES;
QUIT;
# <optional> Restore database if you have, replace <DATABASEBACKUPPATH> to the database backup file path:
mysql -u phpipam -p phpipam <  <DATABASEBACKUPPATH>
# Step 2: Install PHP and required modules
sudo apt update 
sudo apt -y install php php-{mysql,curl,gd,intl,pear,imap,memcache,pspell,tidy,xmlrpc,mbstring,gmp,json,xml,fpm} fping
# Step 3: Install phpIPAM
sudo apt -y install git
sudo git clone --recursive https://github.com/phpipam/phpipam.git /var/www/html/phpipam
# <optional> Copy your server’s config file to the folder if you have, or copy default config to config.php:
sudo cp <CURRENTCONFIG OR DEFAULTCONFIG>  /var/www/html/phpipam/config.php
# Step 4: Install Nginx
sudo systemctl stop apache2 && sudo systemctl disable apache2
sudo apt -y install nginx
# Copy the server block to phpipam.conf:
sudo vim /etc/nginx/conf.d/phpipam.conf

server {
    listen       80;
    # root directory
    server_name <YOURSERVERNAME>;
    index        index.php;
    root   /var/www/html/phpipam;


    location / {
            try_files $uri $uri/ /index.php$is_args$args;
        }

    location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
             fastcgi_pass   unix:/run/php/php-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_index index.php;
            include fastcgi_params;
        }

 }

sudo rm /etc/nginx/sites-enabled/*
sudo chown -R www-data:www-data /var/www/html
sudo systemctl restart nginx

# <optional, if you are using remote agents> Step 5: Grant permissions for remote agents:
# Login to MariaDB:
sudo mysql -u root -p
# For each agent, excute below, replace <PASSWORD> to our phpipam password and <AGENTIP OR HOSTNAME> to the agent’s ip or hostname:
GRANT SELECT on `phpipam`.* TO phpipam@<AGENTIP OR HOSTNAME> identified by '<PASSWORD>';
GRANT INSERT,UPDATE on `phpipam`.`ipaddresses` TO phpipam@<AGENTIP OR HOSTNAME> identified by '<PASSWORD>';
GRANT UPDATE on phpipam.scanAgents TO phpipam@<AGENTIP OR HOSTNAME> identified by '<PASSWORD>';
QUIT

# Modify the config file of MariaDB to listen to 0.0.0.0, you can also use sed to do this:
sudo vim /etc/mysql/mariadb.conf.d/50-server.cnf
# Change this line
bind-address            = 127.0.0.1
to:
bind-address            = 0.0.0.0
sudo systemctl restart mariadb
# After the steps above, you can create agents on IPAM website:
# Administration – Scan agents – Create new agent. Copy the Code, then setup the agents.
# Agent setup steps:
# Step 1: Install PHP and required modules
sudo apt update 
sudo apt -y install php php-{mysql,curl,gd,intl,pear,imap,memcache,pspell,tidy,xmlrpc,mbstring,gmp,json,xml,fpm} fping
# Step 2: Install phpIPAM agent
sudo apt -y install git
git clone --recursive https://github.com/phpipam/phpipam-agent/ phpipam-agent
# Step 3: Config phpIPAM agent

cd phpipam-agent
mv config.dist.php config.php
vim config.php
# Change the follows:
$config['key'] = "<THE KEY YOU CREATED IN THE HOST>";
$config['pingpath'] = "<fping INSTALL PATH>";
$config['db']['host'] = "<HOST IP OR HOSTNAME>";
$config['db']['pass'] = "<phpipam PASSWORD>";
# Save above settings.
# Run the following command in the agent:
php <AGENT INSTALL FOLDER>\index.php update
# If you didn’t select any subnet to be scanned by this agent in your IPAM server, it won’t print anything. If it returns any SQL error, please check host’s port listening:
sudo lsof -i -P -n | grep LISTEN
# Check if MariaDB listening to *:3306. If not check the config file MariaDB is using.
# Also need to check user’s permissions. You have to manually setup users@hostname to enable remote host access. The user phpipam@localhost will not automatically grant permissions for phpipam@remoteagent
# IPAM agent usage
# Step 1: Select subnets being scanned by agent
# In IPAM gui, find a subnet needs to be scanned by a remote agent.
# In Actions – Pencil icon (Edit subnet properties) – Check hosts status ‘YES’ – Discover new hosts ‘YES’ – Select agent <AGENT NAME>
# Then click Edit, Cancel.
# Now if you run the command:
<AGENT INSTALL FOLDER>/index.php update
# It will show the ping check result of the subnet you setup. You will also see the result from IPAM host.
# Step 2: Schedule subnet scan
# Run the following scripts from cron, the following script will automatically scan every 15 minutes, we can change the inverval:
*/15 * * * * php  <AGENT INSTALL FOLDER>/index.php update
*/15 * * * * php <AGENT INSTALL FOLDER>/index.php discover

#!/bin/bash
################################################################################
# Script for installing Odoo V10 on Ubuntu 16.04, 15.04, 14.04 (could be used for other version too)
# Modified By: Ayaz Ali Qureshi
# Organization: PerkUp
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################
 
##fixed parameters
#odoo
OE_USER="odoo10"
OE_HOME="/home/$OE_USER"
OE_SUPERADMIN="2a83151455cdc36a80dc238e1d"

#Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"

##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltox installed, for a danger note refer to 
## https://www.odoo.com/documentation/8.0/setup/install.html#deb ):
WKHTMLTOX_X64=https://downloads.wkhtmltopdf.org/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
WKHTMLTOX_X32=https://downloads.wkhtmltopdf.org/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-i386.deb

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

sudo systemctl enable postgresql
sudo systemctl start postgresql

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install wget git python-pip gdebi-core -y

echo -e "\n---- Install python packages ----"
sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil -y python-suds

echo -e "\n---- Install python libraries ----"
sudo pip install gdata psycogreen ofxparse XlsxWriter xlrd

echo -e "\n--- Install other (node) required packages"
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y build-essential
sudo apt-get install -y nodejs
sudo npm install -g less less-plugin-clean-css
sudo apt-get install python-gevent -y

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 10 ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
sudo wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
sudo echo "deb http://nightly.odoo.com/10.0/nightly/deb/ ./" > /etc/apt/sources.list.d/odoo.list
echo -e "\n---- Install Odoo Server ----"
sudo apt-get update && apt-get install odoo

echo -e "\n---- Configuring Odoo for automatic start ----"
sudo systemctl enable odoo
sudo systemctl start odoo

echo -e "\n---- Create custom module directory ----"
sudo su root -c "mkdir -p $OE_HOME/custom_addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "\n---- Configure new admin password ----"
sudo sed -i s/"; admin_passwd.*"/"admin_passwd = $OE_SUPERADMIN"/g /etc/odoo/odoo.conf

echo -e "\n---- Adding custom addon directory to odoo config ----"
sudo sed -i s/"addons_path = .*"/"addons_path = \/usr\/lib\/python2.7\/dist-packages\/odoo\/addons,\/home\/odoo\/custom_addons"/g /etc/odoo/odoo.conf

echo -e "\n---- Restart Odoo after custom addons ----"
sudo systemctl restart odoo.service

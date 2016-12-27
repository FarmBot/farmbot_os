# HOW TO CONTRIBUTE
* Fork the official [Farmbot Master branch](https://github.com/farmbot/farmbot_os/tree/master)
* set up your [development environment](#Development)
* Make your changes.
* Run tests, make sure you didn't break anything.
* pull request the official [Farmbot Master Branch](https://github.com/FarmBot/farmbot_os/pull/new/master)
* give a detailed description of what changed.


# Development
The project is developed in Elixir, and builds a full Linux operating system.
That being said, you will need Linux, or a Linux Virtual Machine to build the system. 
The following assumes you are on a Ubuntu Based distribution. Also when building code for the OS (this project)
you will NEED the rest of the stack set up locally.

## Note
if someone wants to set up a vagrant file for doing this, it would be greatly appreciated
When set up you should end up with a folder structure like this: 
```
farmbot
├── farmbot_web_api    
├── farmbot_mqtt_broker
├── farmbot_web_frontend
└── farmbot_os 
```

## Dependencies
We need quite a few dependencies to build the system.
```bash
sudo apt-get update 
sudo apt-get upgrade
sudo apt-get -y install build-essential m4 autoconf git libncurses5-dev 
```

## ASDF-VM
I use ASDF-VM to handle managing Erlang, Elixir, and Node versions.
You can substitute your own, just make sure you have the correct versions.

```bash
# For Ubuntu or other linux distros
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.2.1
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
source ~/.asdf/asdf.sh

# Erlang (this one can take a while.)
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang 19.1
asdf global erlang 19.1

# Elixir
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install elixir 1.3.2
asdf global elixir 1.3.2

# NodeJS
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install node 7.0.0
asdf global node 7.0.0
```

# Ruby
I use `rvm` to manage ruby.
```bash
rvm use 2.3.2 --default
gem install bundler
```

# The rest
```bash
# Set up directories and what not.
cd ~/
mkdir farmbot
cd farmbot

# clone all the upstream repositories.
mkdir -p api mqtt frontend os 
cd api 
git init
git remote add upstream https://github.com/FarmBot/farmbot-web-api.git
git pull upstream master

cd ../mqtt 
git init 
git remote add upstream https://github.com/FarmBot/mqtt-gateway.git
git pull upstream master

cd ../frontend 
git init 
git remote add upstream https://github.com/FarmBot/farmbot-web-frontend.git
git pull upstream master

cd ../os 
git init 
git remote add upstream https://github.com/FarmBot/farmbot_os.git
git pull upstream master
```

then make sure to add your own remote to whichever repository you plan on contributing too.
```bash 
git remote add origin https://github.com/MyCoolUserName/farmbot_os.git
```
# Common Stuff 
```bash
export IP_ADDR=<INSERT_IP_ADDRESS_HERE>
export API_HOST=$IP_ADDR
export API_PORT=3000
export MQTT_HOST=$IP_ADDR
export RAILS_ENV=development
export OS_UPDATE_SERVER=https://api.github.com/repos/farmbot/farmbot_os/releases/latest
export FW_UPDATE_SERVER=https://api.github.com/repos/Farmbot/farmbot-arduino-firmware/releases/latest
export WEB_API_URL=http://$IP_ADDR:$API_PORT
```

# Set up the API.
```bash
cd ~/farmbot/api
# pull any updates from upstream
git pull upstream master 

# Should only need to do this command once.
bundle install 

# Should only need to do this command once.
rake db:migrate
rails s -b 0.0.0.0
```

# Set up MQTT
```bash
cd ~/farmbot/mqtt 
git pull upstream master
# Should only need to do this command once.
npm install
npm start
```

# Set up the Frontend
```bash 
cd ~/farmbot/frontend
git pull upstream master 
# Should only need to do this command once.
npm install 
npm start
```

# Set up the OS 
For advanced stuff see [this](BUILDING.md)
```bash 
cd ~/farmbot/os 
git pull upstream master
MIX_ENV=prod mix do deps.get,mix farmbot.firmware
# If you want to burn the image to an sdcard:
MIX_ENV=prod bash scripts/burn.sh

# If you want to upload the build to a RUNNING bot you can do 
MIX_ENV=prod BOT_IP_ADDR=<FARMBOT_IP_ADDRESS!!!@> mix farmbot.firmware --upload
```

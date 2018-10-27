# Automated Openkore Servers Tables Update

1 – Install Ubuntu:
https://www.ubuntu.com/download/desktop

2 – Install and configure GIT
    2.1 – open terminal and install git
        sudo apt-get install git
    2.2 – in terminal configure github user
        git config --global user.name "user_name"
        git config --global user.email "email_id"
    2.3 – use terminal  to move you into a folder that you want to install openkore and automated update
        cd Desktop/
    2.4 – clone openkore project
        git clone https://www.github.com/openkore/openkore
    2.5 – clone automated update project
        git clone https://github.com/alisonrag/automated-openkore-tables-update

3 – Install Requirements
    2.1 - open terminal and check if you have c++ compiler
        sudo g++ -v
        2.1.1 if not installed, just install using the following command
            sudo apt-get install build-essential g++
    2.2 – open terminal and check if perl is installed
        perl -v
        2.2.1 – if not installed install using the command
            sudo apt-get install perl
    2.3 – install the necessary modules using the following commands
        sudo cpan Config::IniFiles
        sudo cpan YAML::Syck
    
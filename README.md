# Automated Openkore Servers Tables Update

 1 – Install Ubuntu:  
* https://www.ubuntu.com/download/desktop  
  
 2 – Install and configure GIT  
   * 2.1 – open terminal and install git  
        `sudo apt-get install git`  
   * 2.2 – in terminal configure github user  
        `sudo git config --global user.name "user_name"`  
        `sudo git config --global user.email "email_id"`  
   * 2.3 – use terminal  to move you into a folder that you want to install openkore and automated update  
        `cd Desktop/`  
   * 2.4 – clone openkore project  
        `sudo git clone https://github.com/openkore/openkore.git/`  
   * 2.5 – clone automated update project  
        `sudo git clone https://github.com/alisonrag/automated-openkore-tables-update.git/`  
  
 3 – Install Requirements  
   * 3.1 - open terminal and check if you have c++ compiler  
        `sudo g++ -v`  
        * 3.1.1 if not installed, just install using the following command  
            `sudo apt-get install build-essential g++`  
   * 3.3 – open terminal and check if perl is installed  
        `perl -v`  
        * 3.2.1 – if not installed install using the command  
            `sudo apt-get install perl`  
   * 3.3 – install the necessary modules using the following commands  
        `sudo cpan Config::IniFiles`  
        `sudo cpan YAML::Syck`  
        `sudo cpan Disassemble::X86`  
   * 3.4 – install lua 5.1 32-bits  
        `sudo apt-get install lua5.1:i386`  
   * 3.5 – install hub (git helper)  
        `sudo add-apt-repository ppa:cpick/hub`  
        `sudo apt-get update`  
        `sudo apt-get install hub`  
   * 3.6 - go to grf_extract and make the app  
    open terminal  
        * 3.6.1 - go to folder  
        `cd automated-openkore-tables-update/scripts/grf_extract`  
        * 3.6.2 - make grf_extract  
        `sudo make`  
        * 3.6.3 - give permission to execute program  
        `sudo chmod u+x grf_extract_64`  
   * 3.7 -  give chmod 777 to the project  
    open terminal  
        * 3.7.1 - go to where automated-openkore-tables-update is located  
            `cd Desktop/`  
        * 3.7.2 - give chmod 777 to automated-openkore-tables-update  
            `sudo chmod 777 -R automated-openkore-tables-update/`  

 4 - Configuration
   * 4.1 - use config/config.ini to configure

 5 - Execute
   * 5.1 - open terminal in automated-openkore-tables-update folder  and use sudo to execute
       `sudo perl main.pl`

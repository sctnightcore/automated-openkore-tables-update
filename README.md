# Automated Openkore Servers Tables Update

## 1 – Install Ubuntu:  
* https://www.ubuntu.com/download/desktop  
  
## 2 – Install and configure GIT  
    * 2.1 – open terminal and install git  
        `sudo apt-get install git`
    * 2.2 – in terminal configure github user  
        `git config --global user.name "user_name"`
        `git config --global user.email "email_id"`
    * 2.3 – use terminal  to move you into a folder that you want to install openkore and automated update  
        `cd Desktop/`
    * 2.4 – clone openkore project  
        `git clone https://www.github.com/openkore/openkore`
    * 2.5 – clone automated update project  
        `git clone https://github.com/alisonrag/automated-openkore-tables-update`

## 3 – Install Requirements  
    * 2.1 - open terminal and check if you have c++ compiler  
        `sudo g++ -v`
         * 2.1.1 if not installed, just install using the following command  
            `sudo apt-get install build-essential g++`
    * 2.2 – open terminal and check if perl is installed  
        `perl -v`
         * 2.2.1 – if not installed install using the command  
            `sudo apt-get install perl`
    * 2.3 – install the necessary modules using the following commands  
        `sudo cpan Config::IniFiles`
        `sudo cpan YAML::Syck`
    * 2.4 – install the necessary modules using the following commands  
        `sudo cpan Config::IniFiles`
     * 2.5 - go to grf_extract and make the app  
    open terminal  
         * 2.5.1 - go to folder  
        `cd automated-openkore-tables-update/scripts/grf_extract`
         * 2.5.2 - make grf_extract  
        `make`
         * 2.5.3 - give permission to execute program  
        `sudo chmod u+x grf_extract_64`
    * 2.6 -  give chmod 777 to the project  
    open terminal  
         * 2.6.1 - go to where automated-openkore-tables-update is located  
            `cd Desktop/`
         * 2.6.2 - give chmod 777 to automated-openkore-tables-update  
            `sudo chmod 777 -R automated-openkore-tables-update/`
    

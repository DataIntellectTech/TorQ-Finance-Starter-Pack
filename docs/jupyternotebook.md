This Jupyter Notebook set-up is intended for use with a linux system.   

***
## Installing a Virtual Machine   
   For this example, VMWare will be used   
   Follow the instructions [here.](https://www.vmware.com/uk/products/workstation-player/workstation-player-evaluation.html)

## Downloading Ubuntu   
   Download Ubuntu [here.](https://ubuntu.com/download/desktop)

## Installing Ubuntu on Virtual Machine   
   Follow the installation instructions for Ubuntu [here.](https://theholmesoffice.com/installing-ubuntu-in-vmware-player-on-windows/)

## Setting up Jupyter Notebooks with Python3 on Ubuntu   
 <!---
   [comment]:(Not completely correct atm)
   -->
   * Install Python3 
   For versions of Ubuntu 17.10 and above, Python3.6 is installed by default.    
   Check Python3 is installed with   
   `$ python3 --version`   
   To install Python3 for other operating systems, follow installation steps [here.](https://docs.python-guide.org/starting/installation/)   
   
   * Install appropriate Python package installer    
   Pip3 is recommended for Python package installation, it should already be installed if Python 3 >= 3.4 is installed.   
   To upgrade pip for Linux      
   `pip3 install -U pip`   
   `sudo apt install python3-pip`   
   <!---
   [comment]:(Not 100% sure if pip/pip3 is best for this set-up)
   -->
   
   * Install Jupyter   
   The following is one of the many ways to install jupyter, so feel free to install it your own way. 
  
      `$ pip3 install jupyter`     
      Add path to the `~/.bashrc` file to be able to run jupyter notebook from anywhere in terminal    
  
      `export PATH=$PATH:~/.local/bin`   
      Check jupyter notebook works    
    
      `$jupyter notebook`   
      This should open a web browser showing the Notebook Dashboard.    
      Close the page and proceed with the set-up.
***
## Installing TorQ and TorQ finance Started Pack (FSP) on Linux terminal   
* Create new directory and go into the new directory

   `$ mkdir new_directory`   
   `$ cd new_directory`   
   
* Git clone links for TorQ and TorQ FSP from github   
   This step requires `git` to be installed. 
 
   `$ git clone https://github.com/AquaQAnalytics/TorQ.git`   
   `$ git clone https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack.git`   
   
* Create new folder for your TorQ stack

   `$ mkdir deploy`   
   `$ cd deploy`   

* Within the Deploy folder, copy TorQ into deploy and then copy everything not already in TorQ from FSP

   `$ cp -r ../TorQ/* ./`   
   `$ cp -r ../TorQ-Finance-Starter-Pack/* ./`   

* Change port number in setenv.sh within the deploy folder

   - Edit KDBBASEPORT number with appropriate text editor   
   - In the line `export KDBBASEPORT=6000`, change `6000` to a different number 
   - Save edited setenv.sh file     

* **Source the setenv file**

   `$ source setenv.sh`   
   May show:Command 'curl' not found, follow the instructions to install curl   
***
## Install q   
* Download and save appropriate q package from kx downloads from [here.](https://kx.com/connect-with-us/download/)   
   A pop up will appear for opening the appropriate zip file, open the file and extract it's contents into Downloads.  
* Copy q into home from downloads, if it's not already extracted there   
   `$cp - r q /home/$USER`      
* In home directory, get appropriate library for the download   
   - Check linux version (can do this anywhere within linux terminal)     
   `$uname -m` (this gives options depending on results)   
   I.e for 32-bit download, get the 32-bit library   
    `$ sudo apt-get install libc6-i386`   
   For more information on installing q check out [Installing kdb+.](https://code.kx.com/v2/learn/)
* Check if q runs within the home directory (`$cd ~`)   
   `$ q/l32/q`   
   - Test that q is working   
   `q)til 6`    
    `0 1 2 3 4 5`   
   - exit q session   
   `q)\\`  
 
* Set alias for q (rlwrap must be installed for this step)    
   - edit the .bashrc file in your home directory    
   - Add following line to bottom of file:    
      `alias q='QHOME=~/q rlwrap -r ~/q/l32/q'`    
   - Save file and close text editor   
* Source .bashrc    
   `$ source .bashrc`   
   May show ```bash:need:not found / bash:alias:to:not found/bash:alias:enable:not found```, but you should be able to type q anywhere in the linux terminal and a q session will open up.   
   May also show `Command 'rlwrap' not found`, follow the instructions to install rlwrap
***
## Install modules for Jupyter Notebook  
  As there are a number of ways for installing python modules, there is a `jnbrequirements.txt` file provided which details the required modules for this notebook to run.   
  It is recommended to run the following   
  `pip3 install -U pip`   
  `sudo python3 -m pip install --force-reinstall pip==9.0.1`   
  `pip3 install -r jnbrequirements.txt --user`   
   As Python modules are frequently modified, there is no guarantee that the module versions used at the time jnbrequirements.txt was written will work at a later time.    
***
## User Credentials   
   Open the `credentials.csv` and add in your host, username and password   
   Note your host, username and password must be **comma separated**   
i.e host,username,password   
    localhost,admin,admin 
***
## Setting up routine Jupyter Notebook e-mails   

   To set up the conversion of Jupyter Notebooks to HTML and send them to a specified e-mail(s)   
   - Edit the `JUPYTEREMAIL` and `JUPYTERLOC` path variables in the `jupyterrun.sh` script            
   - To find where the jupyter-nbconvert command is run from, run `$ which jupyter-nbconvert` from the command line, copy the output and set is as the `JUPYTERLOC` variable   
   The path to `jupyter-nbconvert` needs to be manually added, as the location of the file may change based on what installer is used  
   Mailutils will also have to be installed, to do this run   
   `$ apt-get install mailutils`   
   
   - Bash the `jupyterrun.sh` script      
   
   If the user agrees to setting up a cronjob, an e-mail containing the HTML version of the notebook checks, will be sent everyday at 9am.
   For more information on how to set up crontabs, check out: [This link.](https://crontab.guru/)   
   A `no crontab for test1` output may show, in this case type `$ crontab -e` and select an editor. The cronjob should appear when the editor opens. Save and exit the file.
***
## Running Jupyter Notebooks Manually
To run Jupyter Notebooks manually use   
   `$ jupyter-notebook`     
   
   The notebook will automatically choose a free port number or you can run      
   `$ jupyter-notebook --port xxxx`   
   Replace xxxx with a port number of your choice 
***
## Adding more Jupyter Notebook checks for your processes   
   To add additional checks in the notebook for processes other than tickerplant1, rdb1 and hdb1, copy the appropriate code and change the names of the processes   
   For example:   Adding an additional rdb check   
   - Reveal the hidden code with the button at the top of the notebook   
   - Under `RDB Results` heading, copy the code in the cell and paste to a new cell   
![Change for user Processes](https://i.paste.pics/95c50f06ffb9431ab96876b3c7df5fcf.png)
   - Change `rdb1` in the yellow boxes to your process name and run the cell (SHIFT+ENTER) 

## Troubleshooting
- When installing Ubuntu in VM, there may be an error with the Intel VT/AMD V virtualisation in BIOS
   Follow instructions [here](https://docs.fedoraproject.org/en-US/Fedora/13/html/Virtualization_Guide/sect-Virtualization-Troubleshooting-Enabling_Intel_VT_and_AMD_V_virtualization_hardware_extensions_in_BIOS.html
) to enable this virtualisation   

- When setting an alias for q rlwrap must be downloaded   
   Check if rlwrap is downloaded with:    
   `$rlwrap -v`   
   If rlwrap is installed, rlwrap followed by a version number should be returned   
   If rlwrap is not installed run:   
   `$ sudo apt install rlwrap`   

- When running `. torq.sh summary`, a nohup Exit 127 error may show.   
   In the home directory (cd ~), edit the `./.profile` file and add the following to the end of the file and save   
   `export PATH=$PATH:"~/q/l32/q"`   
   source the .profile file   
   `$ source .profile`   

   Edit the `/etc/environment file`, by adding the appropriate path to the q/l32/q file and save   
   `:/path/to/q/l32/"`   
   Source the /etc/environment file   
   `$ source /etc/environment`   

- If port numbers aren't showing when running . torq.sh summary   
   Install netstat with:   
   `$apt install net-tools`   

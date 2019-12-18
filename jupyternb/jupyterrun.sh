#!/bin/bash

#must source setenv.sh from TORQHOME as setenv uses dirpath
cd ..
source setenv.sh
#check TORQHOME is set correctly - should point to /path/to/TorQ
echo $TORQHOME

#set TORQJUPYTER variable path
TORQJUPYTER=${TORQHOME}/jupyternb

#set JNBCRONSCRIPT variable
JNBCRONSCRIPT=${TORQJUPYTER}/jnbcronjob.sh

#if JNBCRONSCRIPT does not exist, create empty file  
if [[ ! -f ${JNBCRONSCRIPT} ]];then
	touch ${JNBCRONSCRIPT}
fi

#set jupyter notebook variable
JNOTEBOOK=${TORQJUPYTER}/jnbchecks.ipynb

#set user email variable
JUPYTEREMAIL="putyouremailhere@example.com"

#set variable for jupyter-nbconvert command path
JUPYTERLOC=/home/$USER/.local/bin/jupyter-nbconvert

#set variable for HTML version of jupyter notebook
JUPYTERHTML=${TORQJUPYTER}/jnbchecks.html

#Create script to be run by cron job
#this generates the commands to execute the notebook, 
#convert to html and mail to the required user email
echo "#!/bin/bash

#Check TORQHOME is set in the correct directory
echo $TORQHOME

#Convert jupyter notebook to HTML version
${JUPYTERLOC} --execute --to html ${JNOTEBOOK}

#Email HTML version of notebook to user email
echo \"New Jupyter Notebook Generated\" | mail -A ${JUPYTERHTML} -s \"New Jupyter Notebook Generated\" ${JUPYTEREMAIL}

#Remove most recent notebook, so previous notebooks are not sent
rm ${JUPYTERHTML}" > ${JNBCRONSCRIPT}

#generate the line to be run in crontab itself
if crontab -l | grep -q 'jnbcron';then
        echo "Crontab exists"
else
        echo "Crontab does not exist. Creating crontab..."
        (crontab -l; echo -e " BASH=/bin/bash\n TORQHOME=${TORQHOME}\n */5 * * * * cd ${TORQHOME}; bash ${JNBCRONSCRIPT}") | crontab -

fi


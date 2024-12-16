#!/bin/bash

#set user email variable
JUPYTEREMAIL="putyouremailhere@example.com"

#set variable for jupyter-nbconvert command path
JUPYTERLOC=$HOME/jupyter/jupyter_torq/bin/jupyter-nbconvert

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

#set variable for HTML version of jupyter notebook
JUPYTERHTML=${TORQJUPYTER}/jnbchecks.html

#Create script to be run by cron job
#this generates the commands to execute the notebook, 
#convert to html and mail to the required user email
echo "#!/bin/bash

#Convert jupyter notebook to HTML version
${JUPYTERLOC} --execute --to html ${JNOTEBOOK}

#Email HTML version of notebook to user email
echo \"New Jupyter Notebook Generated\" | mail -A ${JUPYTERHTML} -s \"New Jupyter Notebook Generated\" ${JUPYTEREMAIL}

#Remove most recent notebook, so previous notebooks are not sent
rm ${JUPYTERHTML}" > ${JNBCRONSCRIPT}

#User prompt to whether they wish to create a crontab or schedule it themselves
read -p "Would you like to create a crontab job to e-mail the notebook.html everyday at 9 [y/n]?" answer

if [[ "$answer" = "y" ]] ; then
        #generate the line to be run in crontab itself
        if crontab -l | grep -q 'jnbcron';then
                echo "Crontab exists"
        else
                echo "Crontab does not exist. Creating crontab..."
                (crontab -l; echo -e " BASH=/bin/bash\n TORQHOME=${TORQHOME}\n * 9 * * * cd ${TORQHOME}; bash ${JNBCRONSCRIPT}") | crontab -
        fi
else
        echo "User has decided not to create a crontab"

fi


#!/bin/bash


# ---------- Feature 2: Run ----------
run_app() {
    read -p "Enter your project name: " projectName
    project_dir= "attendance_tracker_${projectName}"

if [ -d "$project_dir" ];then
     echo "Project not found, deploy it first"
        return
fi

starting _dir=$(pwd)

cd "$project_dir"

python3 attendace_checker.py

cd "$starting_dir"

echo "Session Ended!!"

}


# ---------- Feature 1: Deploy ----------

deploy_app() {
#---------PRE-FLIGHT CHECKS---------

  #------test 1:python--------
   if command -v python3  > /dev/null 2>&1
then 
    echo "Python 3 is installed."
else
    echo "Python not installe "
   fi
  #------test 2 :zip-------
   if command -v zip  > /dev/null 2>&1
then  
    echo "zip is installed." 
else 
    echo "zip not installe " 
   fi 


#------NAMING THE PROJECT-------
read -p "Enter project name: " projectName
project_dir="attendance_tracker_${projectName}"

if [ -d "$project_dir" ];then
   read -p "Exists, can we Overwrite?(y/n)" conf
 
if [ "$conf" = "y" ];then
      rm -rf "$project_dir"
      echo "Old project removed — redeploying..."
 elif [ "$conf" = "n" ];then 
      echo "Aborted" 
 return

 else
      echo "Invalid answer!!"
 return 

fi 
fi



}
 deploy_app

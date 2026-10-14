#!/bin/bash

#-----------INTERRUPT HANDLER----------
cleanup_interrupt() {
  #1.blankline
  echo ""
  echo "Deployment interrupted! Saving current state__"
  #2.Guard: check if the directory exists before zipping/removing
if  [ -d "$project_dir" ];then
  #3.creating the archive from the folder
    zip -r "${project_dir}_archive.zip" "$project_dir" > /dev/null 2>&1
  #4.Clean up workspace clutter by removing the half-made folder
    rm -rf "$project_dir"
  #5.Echo a confirmation of what was saved and where
    echo "Saved partial project to ${project_dir}_archive.zip and cleaned workspace."

else
  #6.Fallback if interrupted before folder creation
    echo "Nothing was created yet — nothing to archive."
fi
  #7.Exit with Unix status code 130 (SIGINT / Ctrl+C)
  exit 130
}


# ---------- Feature 2: Run()----------
run_app() {
    read -p "Enter your project name: " projectName
    project_dir= "attendance_tracker_${projectName}"

if [ ! -d "$project_dir" ];then
     echo "Project not found, deploy it first"
        return
fi

starting _dir=$(pwd)

cd "$project_dir"

python3 attendace_checker.py

cd "$starting_dir"

echo "Session Ended!!"

}


# ---------- Feature 1: Deploy() ----------

deploy_app() {
#---------PRE-FLIGHT CHECKS---------

  #------test 1:python--------
   if command -v python3  > /dev/null 2>&1
then 
    echo "Python 3 is installed."
else
    echo "Python not installed "   
exit 1
fi
  #------test 2 :zip-------
   if command -v zip  > /dev/null 2>&1
then  
    echo "zip is installed." 
else 
    echo "zip not installe " 
exit 1  
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


#--------the trap----------------
trap 'cleanup_interrupt' INT TSTP
#---------------------------------

#---------structure creation-----

mkdir -p "$project_dir/Helpers"

#---------populating files------- 








}
 deploy_app

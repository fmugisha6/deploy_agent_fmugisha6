#!/bin/bash

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


deploy_app() {




}

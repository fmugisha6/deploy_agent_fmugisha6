#!/bin/bash

#-------Global so the interrupt handler can always see it (avoids unbound-variable surprises)------
project_dir=""

#------ Arrays holding sample student profiles for the dynamic Part E Option B roster setup-----
SAMPLE_NAMES=("Alice Johnson" "Bob Smith" "Charlie Brown" "Diana Prince" "Evan Wright")
SAMPLE_EMAILS=("alice@example.com" "bob@example.com" "charlie@example.com" "diana@example.com" "evan@example.com")

#-----------INTERRUPT HANDLER----------
#--- Runs only when Ctrl+C (INT) or Ctrl+Z (TSTP) hits during deployment---

cleanup_interrupt() {
  #1.blankline
     echo ""
     echo "Deployment interrupted! Saving current state.."
  #2.Guard: check if the directory exists before zipping/removing
if  [ -d "$project_dir" ];then
  #3.creating the archive from the folder
     zip -r "${project_dir}_archive.zip" "$project_dir" > /dev/null 2>&1 &&
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

#----HELPER: abort_deploy — rollback for validation failures mid-deployment-----
abort_deploy() {
  echo "[ABORT] Rolling back incomplete deployment."
  [ -n "$project_dir" ] && rm -rf "$project_dir"
  trap - INT TSTP
}


# ---------- Feature 1: Deploy() ----------

deploy_app() {
#---------PRE-FLIGHT CHECKS---------

  #------test 1:python--------
   if command -v python3  > /dev/null 2>&1
then 
    echo "Python 3 is installed."
else
    echo "Python not installed " exit 1
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
     if [ ! -d "templates" ] || [ ! -f "templates/attendance_checker.py" ] || [ ! -f "templates/config.json" ]; then
        echo "[ERROR] Base template components are missing." >&2
        abort_deploy
        return 1
     fi


cp templates/attendance_checker.py "$project_dir/"
cp templates/config.json "$project_dir/Helpers/"

read -p "Roster: (A) copy from template or (B) generate fresh? (A/B): " roster_choice

    if [[ "$roster_choice" == "A" || "$roster_choice" == "a" ]]; then
        # FIX: option A reads templates/assets.csv, so it must be checked too
        if [ ! -f "templates/assets.csv" ]; then
            echo "[ERROR] templates/assets.csv is missing." >&2
            abort_deploy
            return 1
        fi
        read -p "how many students?: " n
        # FIX: n feeds arithmetic $((n + 1)) — non-numeric input crashes bash
        if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ]; then
            echo "[ERROR] Student count must be a positive integer." >&2
            abort_deploy
            return 1
        fi
        local target_lines=$((n + 1))
        # 11. Extract header + n rows from sample source file
        head -n "$target_lines" templates/assets.csv > "$project_dir/Helpers/assets.csv"

    elif [[ "$roster_choice" == "B" || "$roster_choice" == "b" ]]; then
        read -p "how many students?: " n
        if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ]; then
            echo "[ERROR] Student count must be a positive integer." >&2
            abort_deploy
            return 1
        fi
        # FIX: only 5 sample profiles exist — cap instead of silently truncating
        if [ "$n" -gt "${#SAMPLE_NAMES[@]}" ]; then
            echo "[NOTICE] Only ${#SAMPLE_NAMES[@]} sample profiles exist; roster capped at ${#SAMPLE_NAMES[@]}."
            n="${#SAMPLE_NAMES[@]}"
        fi
        echo "Email,Names,Attendance Count,Absence Count" > "$project_dir/Helpers/assets.csv"
        # 12. Loop n times over arrays to append data rows with 0,0 counts
        for ((i=0; i<n; i++)); do
            echo "${SAMPLE_EMAILS[i]},${SAMPLE_NAMES[i]},0,0" >> "$project_dir/Helpers/assets.csv"
        done
        # 13. Edit config total_sessions to 1 using inline sed pattern target matching
        sed -i 's/"total_sessions": [0-9]*/"total_sessions": 1/' "$project_dir/Helpers/config.json"

    else
        # FIX: restored from your original screenshot version — the attached
        # draft dropped this branch and deployed with NO roster file at all
        echo "[ERROR] Invalid option, aborting."
        abort_deploy
        return 1
    fi 

#--------------------PERMISSIONS-------------------------------------
#Permissions: lock down configuration and make python executable
   chmod +x "$project_dir/attendance_checker.py"
   chmod 600 "$project_dir/Helpers/config.json"
   echo "[SUCCESS] Permissions set: Script (+x) and Config (600 owner-only)."
#--------------------Threshold update offer--------------------------------
#Threshold update offer: validate that entry is purely digits
    read -p "Update thresholds? (y/n): " update_switch
   if [[ "$update_switch" == "y" || "$update_switch" == "Y" ]]; then
        read -p "Enter new warning (default 75): " custom_warn
        read -p "Enter new failure (default 50): " custom_fail

        [ -z "$custom_warn" ] && custom_warn=75
        [ -z "$custom_fail" ] && custom_fail=50

        if [[ "$custom_warn" =~ ^[0-9]+$ && "$custom_fail" =~ ^[0-9]+$ ]]; then
            sed -i "s/\"warning\": [0-9]*/\"warning\": $custom_warn/" "$project_dir/Helpers/config.json"
            sed -i "s/\"failure\": [0-9]*/\"failure\": $custom_fail/" "$project_dir/Helpers/config.json"
            echo "Updated values applied: Warning: ${custom_warn}%, Failure: ${custom_fail}%"
        else
            echo "[REJECTED] Thresholds must be numeric digits only! Default configuration saved."
        fi
    fi

#-----------------------Disarm the trap------------------------------
#Disarm the trap: seatbelt off since deploy succeeded safely
    trap - INT TSTP
    echo "Deployment complete"
#-----------------------Verify by running-----------------------------
#Verify by running: pass directory variable directly to execute app
    run_app "$project_dir"



}
 deploy_app


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

#------------------------------------Feature 3:archive_logs()---------------------------

archive_logs() {
    read -p "Enter project name: " check_suffix
    local target_dir="attendance_tracker_${check_suffix}"

    if [ ! -d "$target_dir" ]; then
        echo "[ERROR] project directory not found" >&2
        return 1
    fi

#Capture the timestamp exactly ONCE so both files share it
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$target_dir/archives/attendance"
    mkdir -p "$target_dir/archives/absent"

    if [ -f "$target_dir/reports/attendance.log" ]; then
        cp "$target_dir/reports/attendance.log" "$target_dir/archives/attendance/attendance_${timestamp}.log"
        echo "Archived attendance log to: $target_dir/archives/attendance/attendance_${timestamp}.log"
    else
        echo "no attendance.log to archive"
    fi

# Handle absent log files politely if nobody was recorded absent
    if [ -f "$target_dir/reports/absent.log" ]; then
        cp "$target_dir/reports/absent.log" "$target_dir/archives/absent/absent_${timestamp}.log"
        echo "Archived absent log to: $target_dir/archives/absent/absent_${timestamp}.log"
    else
        echo "no absent.log to archive"
    fi
}




#----------------------------------MENU----------------------------------------------

#Asks what the user wants and sends them to the right office.

while true; do
    echo ""
    echo "------------------------------------------"
    echo "     AUTOMATED DEPLOY AGENT CONTROL  "
    echo "------------------------------------------"
    echo " 1) Deploy Application Instance"
    echo " 2) Run Active Project Tracking Engine"
    echo " 3) Archive Active Project Log Files"
    echo " 4) Terminate Script Program Session"
    echo "------------------------------------------"
    read -p "Select choice option (1-4): " main_choice

    case "$main_choice" in
        1) deploy_app ;;
        2) run_app "" ;;
        3) archive_logs ;;
        4) echo "Exiting agent interface session. Goodbye!"; exit 0 ;;
        *) echo "invalid option" ;;
    esac
done

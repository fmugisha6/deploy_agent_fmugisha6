# Automated Attendance Tracker App

A shell script (`deploy_agent.sh`) that automates provisioning, execution, threshold configuration, and log archiving for Attendance Tracking application instances.

---

## Environment Prerequisites & Installation

Ensure your Linux/Unix environment meets the necessary system requirements before running the agent:

* **Interpreter:** Bash shell (`bash`)
* **System Utilities:** `python3` and `zip`
* **Source Templates:** A `templates/` directory containing:
  * `templates/attendance_checker.py`
  * `templates/config.json`
  * `templates/assets.csv` (required for roster Option A)

Grant execution permissions to the script before launching:
```bash
chmod +x deploy_agent.sh
```

---

## 1. How to Run the Script & Select a Feature

Launch the management control pool directly from your terminal:

```bash
./deploy_agent.sh
```

Upon execution, the script presents an interactive main menu:

```text
------------------------------------------
     AUTOMATED DEPLOY AGENT CONTROL  
------------------------------------------
 1) Deploy Application Instance
 2) Run Active Project Tracking Engine
 3) Archive Active Project Log Files
 4) Terminate Script Program Session
------------------------------------------
```

Select a feature by entering the corresponding menu number (`1`–`4`):

* **Option 1 (Deploy Application Instance):**
  1. Executes environment pre-flight checks for `python3` and `zip`.
  2. Prompts for a project name (creating a workspace directory formatted as `attendance_tracker_<projectName>`).
  3. Checks for existing folders and prompts for overwrite confirmation (`y`/`n`).
  4. Arms signal traps (`INT` / `TSTP`) to handle sudden cancellation safely.
  5. Provisions folder structures (`Helpers/`) and populates application files (`attendance_checker.py`, `Helpers/config.json`).
  6. Configures the student roster (Template Copy or Fresh Generation).
  7. Applies strict permissions (`+x` on python script, `600` on config file).
  8. Offers custom warning and failure threshold updates.
  9. Disarms signal traps and automatically invokes the tracking engine (`run_app`).

* **Option 2 (Run Active Project Tracking Engine):**
  1. Prompts for the project name suffix if not provided.
  2. Validates project directory existence.
  3. Navigates into the workspace (`attendance_tracker_<projectName>`), executes `python3 attendance_checker.py`, and safely returns to the root directory upon completion.

* **Option 3 (Archive Active Project Log Files):**
  1. Prompts for the target project name suffix.
  2. Generates a unified date-time timestamp.
  3. Moves existing report logs into isolated timestamped archive folders.

* **Option 4 (Terminate Script Program Session):**
  1. Displays a goodbye message and exits the program cleanly with code `0`.

---

## 2. How the Threshold Update Works

During the deployment sequence (Option 1), the agent provides an interactive step to customize attendance warning and failure thresholds:

1. **User Prompt & Defaults:**
   * Prompts the user: `Update thresholds? (y/n):`
   * If accepted, prompts for new warning and failure percentages.
   * Leaving inputs blank automatically falls back to system defaults (**Warning: 75%**, **Failure: 50%**).

2. **Regex Input Validation:**
   * Inputs are validated against the numerical regular expression `^[0-9]+$`.
   * Non-numeric values (e.g., negative numbers, letters, symbols) trigger a `[REJECTED]` alert, preserving default threshold settings in the configuration file.

3. **Inline Stream Modification (`sed`):**
   * Validated integers are written into `Helpers/config.json` via stream editing:
     ```bash
     sed -i "s/\"warning\": [0-9]*/\"warning\": $custom_warn/" "$project_dir/Helpers/config.json"
     sed -i "s/\"failure\": [0-9]*/\"failure\": $custom_fail/" "$project_dir/Helpers/config.json"
     ```

---

## 3. How Log Archiving Works

The `archive_logs` routine (Option 3) handles historical record preservation:

### Directory Structure & Timestamp Generation
* **Single Timestamp Capture:** Generates a unified timestamp string formatted as `YYYYMMDD_HHMMSS` using `date +%Y%m%d_%H%M%S` (ensuring both attendance and absence log copies share the exact same timestamp).
* **Directory Creation:** Ensures the destination directories exist before copying:
  * `<project_dir>/archives/attendance/`
  * `<project_dir>/archives/absent/`

### File Processing Logic
* **Attendance Log:** If `<project_dir>/reports/attendance.log` exists, it is copied to:
  `<project_dir>/archives/attendance/attendance_<timestamp>.log`
* **Absence Log:** If `<project_dir>/reports/absent.log` exists, it is copied to:
  `<project_dir>/archives/absent/absent_<timestamp>.log`
* **Missing Log Handling:** If a log file does not exist (for instance, if no students were marked absent during a session), the script displays a notification (`no absent.log to archive`) and continues execution gracefully without crashing.

---

## 4. Testing the Ctrl+C / Ctrl+Z Interrupt Path

The deployment phase implements signal trapping (`cleanup_interrupt`) to safeguard workspaces against partial file corruption if interrupted mid-process.

### Signal Trapping Mechanism
* **Trapped Signals:** `SIGINT` (`Ctrl+C`) and `SIGTSTP` (`Ctrl+Z`).
* **Trapping Command:** `trap 'cleanup_interrupt' INT TSTP`.
* **Exit Code:** Exits with standard Unix signal termination status `130`.

### Step-by-Step Interrupt Test Procedure
1. Execute `./deploy_agent.sh` and select **Option 1**.
2. Enter a temporary project name (e.g., `interrupt_test`).
3. At any subsequent prompt (e.g., roster selection or student count input), press `Ctrl+C` or `Ctrl+Z`.
4. **Expected Behavior Verification:**
   * Terminal outputs: `Deployment interrupted! Saving current state..`
   * The incomplete project folder (`attendance_tracker_interrupt_test`) is compressed into `attendance_tracker_interrupt_test_archive.zip`.
   * The uncompressed directory is deleted (`rm -rf`) to prevent workspace clutter.
   * Terminal confirms: `Saved partial project to attendance_tracker_interrupt_test_archive.zip and cleaned workspace.`
   * Verify the exit status by running `echo $?` in terminal immediately after; it will return `130`.

---

## 5. What the `.zip` Archive Contains

When an interruption occurs during deployment, `cleanup_interrupt()` preserves the exact state of the project workspace at that moment.

The created archive file is named:
```text
attendance_tracker_<projectName>_archive.zip
```

### Partial Workspace Snapshot
Depending on the exact stage at which `Ctrl+C` or `Ctrl+Z` was pressed, the zip file contains:

* **Interrupted during Roster Selection:**
  * Root folder: `attendance_tracker_<projectName>/`
  * `attendance_checker.py`
  * `Helpers/` subdirectory
  * `Helpers/config.json`
* **Interrupted during Roster Generation:**
  * All files listed above.
  * A partially generated or complete `Helpers/assets.csv`.

*Note: Once zipped, the original uncompressed folder is automatically removed to keep your workspace clean.*

---

## 6. How the Deployed Application Structure Was Tested

Deployment stability and script functionality were validated through systematic end-to-end testing:

### 1. File & Directory Layout Verification
Executed Option 1 with project name `demo_app` and verified structure creation via `tree` / `ls -la`:
```text
attendance_tracker_demo_app/
├── attendance_checker.py
└── Helpers/
    ├── assets.csv
    └── config.json
```

### 2. Permissions Verification
Verified security configurations using `ls -l attendance_tracker_demo_app/` and `ls -l attendance_tracker_demo_app/Helpers/`:
* `attendance_checker.py`: Has executable rights (`-rwxr-xr-x` / `+x`).
* `Helpers/config.json`: Restricted to owner-only read/write (`-rw-------` / `chmod 600`).

### 3. Roster Selection Verification
* **Option A (Template Copy):** Tested with $N=3$. Verified that `Helpers/assets.csv` contained headers plus exactly 3 student rows extracted from `templates/assets.csv`.
* **Option B (Fresh Generation):** Tested with $N=10$. Verified that the student count was correctly capped at 5 (matching sample array size), initial counts were formatted as `0,0`, and `total_sessions` was updated to `1` in `Helpers/config.json` via `sed`.

### 4. Integration & Archiving Flow Verification
* **Execution Test:** Launched **Option 2**, verified directory context shift into `attendance_tracker_demo_app/`, confirmed Python application execution, and verified return to the root working directory upon exiting.
* **Archiving Test:** Ran the application to generate log files inside `reports/`, then invoked **Option 3** (`archive_logs`). Verified that logs were copied to `archives/attendance/attendance_<YYYYMMDD_HHMMSS>.log` and `archives/absent/absent_<YYYYMMDD_HHMMSS>.log` with identical timestamp signatures.

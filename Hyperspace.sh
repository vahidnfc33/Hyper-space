#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/Hyperspace.sh"

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "Script written by Big Gambling Community, Twitter: @ferdie_jhovie, free and open source. Do not trust paid services."
        echo "If you have any issues, contact Twitter. Only one account exists."
        echo "================================================================"
        echo "To exit the script, press Ctrl + C."
        echo "Please select an option:"
        echo "1. Deploy Hyperspace Node"
        echo "2. View Logs"
        echo "3. View Points"
        echo "4. Delete Node (Stop Node)"
        echo "5. Exit Script"
        echo "================================================================"
        read -p "Enter your choice (1/2/3/4/5): " choice

        case $choice in
            1)  deploy_hyperspace_node ;;
            2)  view_logs ;; 
            3)  view_points ;;
            4)  delete_node ;;
            5)  exit_script ;;
            *)  echo "Invalid choice, please try again!"; sleep 2 ;;
        esac
    done
}

# Deploy Hyperspace Node
function deploy_hyperspace_node() {
    echo "Executing installation command: curl https://download.hyper.space/api/install | bash"
    curl https://download.hyper.space/api/install | bash

    NEW_PATH=$(bash -c 'source /root/.bashrc && echo $PATH')
    export PATH="$NEW_PATH"

    if ! command -v aios-cli &> /dev/null; then
        echo "aios-cli command not found, retrying..."
        sleep 3
        export PATH="$PATH:/root/.local/bin"
        if ! command -v aios-cli &> /dev/null; then
            echo "aios-cli command could not be found. Please manually run 'source /root/.bashrc' and try again."
            read -n 1 -s -r -p "Press any key to return to the main menu..."
            return
        fi
    fi

    read -p "Enter screen name (default: hyper): " screen_name
    screen_name=${screen_name:-hyper}
    echo "Using screen name: $screen_name"

    echo "Checking and cleaning existing '$screen_name' screen sessions..."
    screen -ls | grep "$screen_name" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Existing '$screen_name' screen session found. Stopping and deleting..."
        screen -S "$screen_name" -X quit
        sleep 2
    else
        echo "No existing '$screen_name' screen session found."
    fi

    echo "Creating a new screen session named '$screen_name'..."
    screen -S "$screen_name" -dm
    screen -S "$screen_name" -X stuff "aios-cli start\n"

    sleep 5

    echo "Ensuring environment variables are updated..."
    source /root/.bashrc
    sleep 4
    echo "Current PATH: $PATH"

    echo "Enter your private key (press Ctrl+D to finish):"
    cat > my.pem
    echo "Using my.pem to run import-keys command..."
    aios-cli hive import-keys ./my.pem
    sleep 5

    model="hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf"

    echo "Adding model via 'aios-cli models add' command..."
    while true; do
        if aios-cli models add "$model"; then
            echo "Model added and downloaded successfully!"
            break
        else
            echo "Error adding model. Retrying..."
            sleep 3
        fi
    done

    echo "Logging in and selecting tier..."
    aios-cli hive login

    echo "Select tier (1-5):"
    select tier in 1 2 3 4 5; do
        case $tier in
            1|2|3|4|5)
                echo "Selected tier $tier"
                aios-cli hive select-tier $tier
                break
                ;;
            *)
                echo "Invalid choice. Please enter a number between 1 and 5."
                ;;
        esac
    done

    aios-cli hive connect
    sleep 5

    echo "Stopping 'aios-cli start' process using 'aios-cli kill'..."
    aios-cli kill

    echo "Running 'aios-cli start --connect' in screen session '$screen_name', directing output to '/root/aios-cli.log'..."
    screen -S "$screen_name" -X stuff "aios-cli start --connect >> /root/aios-cli.log 2>&1\n"

    echo "Hyperspace Node deployment complete. 'aios-cli start --connect' is running in the background."
    read -n 1 -s -r -p "Press any key to return to the main menu..."
    main_menu
}

# View Points
function view_points() {
    echo "Viewing points..."
    source /root/.bashrc
    aios-cli hive points
    sleep 2
}

# Delete Node (Stop Node)
function delete_node() {
    echo "Stopping node using 'aios-cli kill'..."
    aios-cli kill
    sleep 2
    echo "'aios-cli kill' executed. Node stopped."
    read -n 1 -s -r -p "Press any key to return to the main menu..."
    main_menu
}

# View Logs
function view_logs() {
    echo "Viewing logs..."
    LOG_FILE="/root/aios-cli.log"

    if [ -f "$LOG_FILE" ]; then
        echo "Displaying the last 200 lines of the log:"
        tail -n 200 "$LOG_FILE"
    else
        echo "Log file does not exist: $LOG_FILE"
    fi

    read -n 1 -s -r -p "Press any key to return to the main menu..."
    main_menu
}

# Exit Script
function exit_script() {
    echo "Exiting script..."
    exit 0
}

# Call the main menu function
main_menu

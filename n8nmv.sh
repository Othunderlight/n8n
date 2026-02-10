#!/bin/bash

# Check if a file was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    echo "Please provide a filename to move"
    exit 1
fi

# Get the file to move
FILE_NAME="$1"
SOURCE_PATH="/home/omar/Downloads/${FILE_NAME}"
DEST_BASE="/home/omar/Desktop/foss/n8n/workflows"

# Check if source file exists
if [ ! -f "$SOURCE_PATH" ]; then
    echo "Error: File '$SOURCE_PATH' does not exist!"
    exit 1
fi

# Function to display folder selection
select_folder() {
    local current_path="$1"

    # Clear global arrays
    dir_names=()
    dirs=()

    # Add "Move here" option
    dir_names+=("📁 Move here (current folder)")
    dirs+=("$current_path")

    # Add "Go back" option if not at base directory
    if [ "$current_path" != "$DEST_BASE" ]; then
        dir_names+=("↩️  Go back to parent folder")
        dirs+=("$(dirname "$current_path")")
    fi

    # Find all directories in current path
    while IFS= read -r dir; do
        dir_names+=("📁 $(basename "$dir")")
        dirs+=("$dir")
    done < <(find "$current_path" -maxdepth 1 -type d ! -path "$current_path" | sort)

    # Display menu
    clear
    echo "Moving: $FILE_NAME"
    echo "Current location: $current_path"
    echo "========================================"

    for i in "${!dir_names[@]}"; do
        if [ $i -eq $selected ]; then
            echo "> ${dir_names[$i]}"
        else
            echo "  ${dir_names[$i]}"
        fi
    done

    echo "========================================"
    echo "Use ↑ ↓ arrows to navigate, Enter to select"
    echo "ESC to cancel"
}

# Main interactive loop
current_path="$DEST_BASE"
selected=0
key=""
declare -a dir_names
declare -a dirs

# Initial display
select_folder "$current_path"

while true; do
    # Read single character (including arrows)
    read -rsn1 key

    case "$key" in
        $'\x1b')  # ESC key
            read -rsn2 -t 0.1 key2  # Read the rest of escape sequence
            if [[ "$key2" == "[A" ]]; then  # Up arrow
                if [ ${#dir_names[@]} -gt 0 ]; then
                    selected=$(( (selected - 1 + ${#dir_names[@]}) % ${#dir_names[@]} ))
                fi
            elif [[ "$key2" == "[B" ]]; then  # Down arrow
                if [ ${#dir_names[@]} -gt 0 ]; then
                    selected=$(( (selected + 1) % ${#dir_names[@]} ))
                fi
            elif [[ -z "$key2" ]]; then  # ESC alone - cancel
                echo -e "\nOperation cancelled."
                exit 0
            fi

            # Redisplay menu after arrow key press
            select_folder "$current_path"
            ;;
        "")  # Enter key
            if [ ${#dir_names[@]} -eq 0 ]; then
                continue
            fi

            selected_path="${dirs[$selected]}"

            # If "Move here" was selected
            if [ $selected -eq 0 ]; then
                echo -e "\nMoving '$FILE_NAME' to: $current_path"
                mv "$SOURCE_PATH" "$current_path/"
                echo "File moved successfully!"
                exit 0
            fi

            # If "Go back" was selected
            if [ $selected -eq 1 ] && [ "$current_path" != "$DEST_BASE" ]; then
                current_path="$selected_path"
                selected=0
                select_folder "$current_path"
                continue
            fi

            # Navigate into selected directory
            current_path="$selected_path"
            selected=0
            select_folder "$current_path"
            ;;
        q|Q)  # Quit
            echo -e "\nOperation cancelled."
            exit 0
            ;;
    esac
done

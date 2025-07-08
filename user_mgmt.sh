#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    whiptail --title "Permission Denied" --msgbox "You must run this script as root." 8 45
    exit 1
fi

# Functions
add_user() {
    USERNAME=$(whiptail --inputbox "Enter new username:" 8 40 3>&1 1>&2 2>&3) || return
    if id "$USERNAME" &>/dev/null; then
        whiptail --msgbox "User already exists!" 8 40
        return
    fi

    COMMENT=$(whiptail --inputbox "Enter full name or comment:" 8 40 3>&1 1>&2 2>&3) || return
    HOME_DIR=$(whiptail --inputbox "Enter home directory (leave blank for default):" 8 50 3>&1 1>&2 2>&3)
    SHELL=$(whiptail --inputbox "Enter login shell (e.g. /bin/bash):" 8 50 3>&1 1>&2 2>&3)
    
    PASSWORD1=$(whiptail --passwordbox "Enter password:" 8 40 3>&1 1>&2 2>&3) || return
    PASSWORD2=$(whiptail --passwordbox "Confirm password:" 8 40 3>&1 1>&2 2>&3) || return

    if [[ "$PASSWORD1" != "$PASSWORD2" ]]; then
        whiptail --msgbox "Passwords do not match!" 8 40
        return
    fi

    useradd -c "$COMMENT" -m ${HOME_DIR:+-d "$HOME_DIR"} ${SHELL:+-s "$SHELL"} "$USERNAME"
    echo "$USERNAME:$PASSWORD1" | chpasswd

    if [[ $? -eq 0 ]]; then
        whiptail --msgbox "User $USERNAME added successfully." 8 45
    else
        whiptail --msgbox "Failed to add user." 8 40
    fi
}

delete_user() {
    USERNAME=$(whiptail --inputbox "Enter the username to delete:" 8 40 3>&1 1>&2 2>&3) || return
    userdel -r "$USERNAME" && \
    whiptail --msgbox "User deleted." 8 30 || \
    whiptail --msgbox "Failed to delete user." 8 40
}

disable_user() {
    USERNAME=$(whiptail --inputbox "Enter the username to disable:" 8 50 3>&1 1>&2 2>&3) || return
    usermod -L "$USERNAME" && \
    whiptail --msgbox "User $USERNAME disabled." 8 45 || \
    whiptail --msgbox "Failed to disable user." 8 40
}

modify_user() {
    USERNAME=$(whiptail --inputbox "Enter the username to modify:" 8 50 3>&1 1>&2 2>&3) || return
    COMMENT=$(whiptail --inputbox "Enter new full name or comment:" 8 50 3>&1 1>&2 2>&3)
    HOME_DIR=$(whiptail --inputbox "Enter new home directory (leave blank to skip):" 8 60 3>&1 1>&2 2>&3)
    SHELL=$(whiptail --inputbox "Enter new shell (leave blank to skip):" 8 50 3>&1 1>&2 2>&3)

    [[ -n "$COMMENT" ]] && usermod -c "$COMMENT" "$USERNAME"
    [[ -n "$HOME_DIR" ]] && usermod -d "$HOME_DIR" -m "$USERNAME"
    [[ -n "$SHELL" ]] && usermod -s "$SHELL" "$USERNAME"

    whiptail --msgbox "User $USERNAME modified." 8 40
}

add_group() {
    GROUPNAME=$(whiptail --inputbox "Enter group name to add:" 8 40 3>&1 1>&2 2>&3) || return
    groupadd "$GROUPNAME" && \
    whiptail --msgbox "Group $GROUPNAME added." 8 40 || \
    whiptail --msgbox "Failed to add group." 8 40
}

delete_group() {
    GROUPNAME=$(whiptail --inputbox "Enter group name to delete:" 8 40 3>&1 1>&2 2>&3) || return
    groupdel "$GROUPNAME" && \
    whiptail --msgbox "Group $GROUPNAME deleted." 8 40 || \
    whiptail --msgbox "Failed to delete group." 8 40
}

list_users_groups() {
    OUTPUT=$(mktemp)
    echo "=== Users ===" > "$OUTPUT"
    cut -d: -f1 /etc/passwd >> "$OUTPUT"
    echo -e "\n=== Groups ===" >> "$OUTPUT"
    cut -d: -f1 /etc/group >> "$OUTPUT"
    whiptail --textbox "$OUTPUT" 20 60
    rm -f "$OUTPUT"
}

# Main Menu
while true; do
    OPTION=$(whiptail --title "User & Group Management" --menu "Choose an action:" 20 60 10 \
        1 "Add User" \
        2 "Modify User" \
        3 "Delete User" \
        4 "Disable User" \
        5 "Add Group" \
        6 "Delete Group" \
        7 "List Users & Groups" \
        8 "Exit" 3>&1 1>&2 2>&3)

    case $OPTION in
        1) add_user ;;
        2) modify_user ;;
        3) delete_user ;;
        4) disable_user ;;
        5) add_group ;;
        6) delete_group ;;
        7) list_users_groups ;;
        8) exit 0 ;;
        *) break ;;
    esac
done

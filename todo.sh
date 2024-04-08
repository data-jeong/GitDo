#!/bin/bash

# TODO 파일이 저장될 폴더 지정
TODO_DIR="$(pwd)/todos"
mkdir -p "$TODO_DIR" # 폴더가 없으면 생성

# 현재 날짜와 입력 날짜 비교 함수
validate_date() {
    if [[ "$1" < $(date +%Y-%m-%d) ]]; then
        echo "Error: Cannot add TODOs for past dates."
        exit 1
    fi
}

# 날짜의 TODO 리스트 확인
function show_todos() {
    DATE=${1:-$(date +%Y-%m-%d)}
    TODO_FILE="$TODO_DIR/todo_$DATE.md"
    if [ -f "$TODO_FILE" ]; then
        echo "TODO List for $DATE:"
        cat "$TODO_FILE"
    else
        echo "No TODO items for $DATE."
    fi
    echo "" # 한 줄 뛰우기
}

# 사용자 입력 확인
function prompt_for_input() {
    local prompt="$1"
    local input
    read -p "$prompt" input
    if [[ -z "$input" ]]; then
        echo "Input cannot be empty. Please try again."
        prompt_for_input "$prompt"
    else
        echo "$input"
    fi
}

# TODO 항목 추가
function add_todo() {
    validate_date "$1"
    TODO_FILE="$TODO_DIR/todo_$1.md"
    echo "- [ ] $2" >> "$TODO_FILE"
    echo "Added to $1: $2"
}

# TODO 항목 제거
function remove_todo() {
    DATE=$1
    TODO_FILE="$TODO_DIR/todo_$DATE.md"
    ITEM_PATTERN=$(printf "%s\n" "$2" | sed 's/[][\/.^$*]/\\&/g') # 사용자 입력을 정규 표현식에 안전하게 사용
    if [[ "$OSTYPE" == "darwin"* ]]; then
        LC_ALL=C sed -i '' "/- \[ \] $ITEM_PATTERN/d" "$TODO_FILE" # macOS에서 LC_ALL=C 설정
    else
        LC_ALL=C sed -i "/- \[ \] $ITEM_PATTERN/d" "$TODO_FILE" # 다른 시스템에서 LC_ALL=C 설정
    fi
    echo "Removed: $2"
}

# TODO 항목 완료 및 커밋 메시지 추가, 그리고 Git 커밋 및 푸시
function complete_todo() {
    DATE=$1
    TODO_FILE="$TODO_DIR/todo_$DATE.md"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/- \[ \] $2/- \[x\] $2/" "$TODO_FILE"
    else
        sed -i "s/- \[ \] $2/- \[x\] $2/" "$TODO_FILE"
    fi
    # 커밋 메시지 입력 받기
    commit_message=$(prompt_for_input "Enter commit message for '$2': ")
    echo "Commit for '$2': $commit_message" >> "$TODO_FILE"
    echo "Completed: $2 with commit message: $commit_message"
    # Git 커밋 및 푸시
    git add "$TODO_FILE"
    git commit -m "Completed TODO: $2. $commit_message"
    git push
}

# TODO 항목 수정
function modify_todo() {
    DATE=$1
    TODO_FILE="$TODO_DIR/todo_$DATE.md"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/- \[ \] $2/- \[ \] $3/" "$TODO_FILE"
    else
        sed -i "s/- \[ \] $2/- \[ \] $3/" "$TODO_FILE"
    fi
    echo "Modified: $2 to $3"
}

# 명령에 대한 사용자 입력 처리
function handle_command_input() {
    local command=$1
    echo "Enter date (YYYY-MM-DD, default: today):"
    read date
    DATE=${date:-$(date +%Y-%m-%d)}
    validate_date "$DATE"
    show_todos "$DATE"
    case "$command" in
        2) # add
            item=$(prompt_for_input "Enter TODO item to add: ")
            add_todo "$DATE" "$item"
            ;;
        3) # remove
            item=$(prompt_for_input "Enter TODO item to remove: ")
            remove_todo "$DATE" "$item"
            ;;
        4) # complete
            item=$(prompt_for_input "Enter TODO item to mark as completed: ")
            complete_todo "$DATE" "$item"
            ;;
        5) # modify
            old_item=$(prompt_for_input "Enter old TODO item: ")
            new_item=$(prompt_for_input "Enter new TODO item: ")
            modify_todo "$DATE" "$old_item" "$new_item"
            ;;
    esac
    echo "Press enter to return to the menu..."
    read
    clear
}

# 메뉴 디스플레이 및 사용자 입력 처리
function display_menu() {
    clear # 이전 내용을 지우고 메뉴 시작
    echo "----------------"
    echo "TODO Manager"
    echo "Select command:"
    echo "1) list - List all TODOs for a date"
    echo "2) add - Add a TODO item"
    echo "3) remove - Remove a TODO item"
    echo "4) complete - Mark a TODO as completed"
    echo "5) modify - Modify an existing TODO"
    echo "6) clear - Clear the screen and show menu"
    echo "7) exit - Exit the program"
    echo "----------------"
    read_choice_and_handle
}

function read_choice_and_handle() {
    read -p "Enter your choice: " choice
    case "$choice" in
        1)
            show_todos "$(date +%Y-%m-%d)"
            ;;
        2|3|4|5)
            handle_command_input "$choice"
            ;;
        6)
            clear
            ;;
        7)
            echo "Exiting TODO Manager..."
            exit 0
            ;;
        *)
            echo "Invalid choice, please try again."
            ;;
    esac
    echo "Press enter to return to the menu..."
    read
}

# 메인 로직
while true; do
    display_menu
done

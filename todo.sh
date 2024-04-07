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
}

# 사용자 입력 확인
function prompt_for_input() {
    local prompt=$1
    local input
    while true; do
        read -p "$prompt" input
        if [[ -z "$input" ]]; then
            echo "Input cannot be empty. Please try again."
        else
            echo "$input"
            break
        fi
    done
}

# 명령에 대한 사용자 입력 처리
function handle_command_input() {
    local command=$1
    echo "Enter date (YYYY-MM-DD, default: today):"
    read date
    DATE=${date:-$(date +%Y-%m-%d)}
    show_todos "$DATE"
    case "$command" in
        add)
            local item=$(prompt_for_input "Enter TODO item: ")
            add_todo "$DATE" "$item"
            ;;
        remove)
            local item=$(prompt_for_input "Enter TODO item to remove: ")
            remove_todo "$DATE" "$item"
            ;;
        complete)
            local item=$(prompt_for_input "Enter TODO item to complete: ")
            complete_todo "$DATE" "$item"
            ;;
        modify)
            local old_item=$(prompt_for_input "Enter old TODO item: ")
            local new_item=$(prompt_for_input "Enter new TODO item: ")
            modify_todo "$DATE" "$old_item" "$new_item"
            ;;
    esac
    return_to_menu_after_action
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
    DATE=${1:-$(date +%Y-%m-%d)}
    TODO_FILE="$TODO_DIR/todo_$DATE.md"
    sed -i '' "/- \[ \] $2/d" "$TODO_FILE" && echo "Removed: $2"
}

# TODO 항목 완료
function complete_todo() {
    DATE=${1:-$(date +%Y-%m-%d)}
    TODO_FILE="$TODO_DIR/todo_$DATE.md"
    sed -i '' "s/- \[ \] $2/- \[x\] $2/" "$TODO_FILE" && echo "Completed: $2"
    local commit_message=$(prompt_for_input "Enter commit message for completing '$2': ")
    git_commit_and_push "$commit_message"
}

# TODO 항목 수정
function modify_todo() {
    DATE=${1:-$(date +%Y-%m-%d)}
    TODO_FILE="$TODO_DIR/todo_$DATE.md"
    sed -i '' "s/- \[ \] $2/- \[ \] $3/" "$TODO_FILE" && echo "Modified: $2 to $3"
}

# 명령 수행 후 메인 메뉴로 돌아가기
function return_to_menu_after_action() {
    echo "Press enter to continue..."
    read
    clear
    display_menu
}

# Git 커밋 및 푸시
function git_commit_and_push() {
    local message="$1"
    git add "$TODO_FILE"
    git commit -m "$message"
    git push
    echo "Changes committed and pushed to Git."
}

# Interactive 모드와 메뉴 디스플레이
function display_menu() {
    clear
    echo "----------------"
    echo "TODO Manager"
    echo "Select command:"
    echo "1) list - List all TODOs for a date"
    echo "2) add - Add a TODO item"
    echo "3) remove - Remove a TODO item"
    echo "4) complete - Mark a TODO as completed"
    echo "5) modify - Modify an existing TODO"
    echo "6) clear - Clear the screen"
    echo "7) exit - Exit the program"
    echo "----------------"
}

function interactive_mode() {
    display_menu
    while true; do
        read -p "Enter your choice: " choice
        case "$choice" in
            1)
                show_todos_then_clear "$(date +%Y-%m-%d)"
                ;;
            2|3|4|5)
                handle_command_input "$choice"
                ;;
            6)
                clear
                display_menu
                ;;
            7)
                echo "Exiting TODO Manager..."
                exit 0
                ;;
            *)
                echo "Invalid choice, please try again."
                display_menu
                ;;
        esac
    done
}

# 메인 로직
if [ $# -eq 0 ]; then
    interactive_mode
else
    echo "Interactive mode only. Please run without arguments."
    exit 1
fi


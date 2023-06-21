#!/usr/bin/bash

c() { [ $# == 0 ] && printf "\e[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\e[\1m/g'; }
cecho() { echo -e "$(c $1)${2}\e[0m"; }

function emoji(){

    local emoji=""

    if [ ! "x$1" == "x" ]; then
        # set emoji
        case $1 in

        note|n) emoji="🛑" ;;
        up|u) emoji="👆" ;;
        down|d) emoji="👇" ;;
        left|l) emoji="👈" ;;
        right|r) emoji="👉" ;;
        hi) emoji="🖐️" ;;
        horns|h) emoji="🤘" ;;
        fist|f) emoji="✊" ;;
        thumbs_up|tu) emoji="👍" ;;
        thumbs_down|td) emoji="👎" ;;        
        tick|t) emoji="✔" ;;
        cross) emoji="✗" ;;
        *) emoji="" ;;

        esac
    fi

    echo "$emoji"
}

function note() {

    local text=$1
    local emoji=$2
    emoji=$(emoji "$emoji")    

    echo -e " $(c sY)$emoji NOTE:$(c 0) $(c iY)$text$(c 0)"

}

echo
echo ' >> Downloading script to "~/.local/bin/poetry-project"'

curl -s -q "https://raw.githubusercontent.com/mugendi/poetry-project-scaffold/master/poetry-project.sh"  >> ~/.local/bin/poetry-project

echo
echo " >> Making script executable.."

# make script executable
chmod +x ~/.local/bin/poetry-project

echo
note "Done!
         You can now run command $(c Bs)'poetry-project'$(c 0) " "tick"

echo




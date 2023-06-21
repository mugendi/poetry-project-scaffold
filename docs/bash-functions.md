<!--
 Copyright (c) 2023 Anthony Mugendi
 
 This software is released under the MIT License.
 https://opensource.org/licenses/MIT
-->

# What are these?

These are a few of the methods in [poetry-project.sh](../poetry-project.sh) that I wanted to document for posterity.

They certainly are not all the methods in that script, but rather the one's I felt the need to document.

## Fetching a file and Replacing all contents

```bash

# trap for errors we throw
trap 'echo >&2 "$_  Line: $LINENO"; exit $LINENO;' ERR
# to throw any error, simply write it to stderr
# printf '%s\n' "My Error" >&2  # write error message to 

# replace text str with another
# takes txt match replacement
function replace_text() {
    local txt="$1"
    local match="$2"
    local replacement="$3"
    # echo $match
    txt=$(awk -v p1="$replacement" "{gsub(\"_${match}_\",p1); print}" <<<$txt)
    echo "$txt"
}

# replace multiple occurences of text
# takes txt replacemrnt dict
# Where replacement dict looks somewhat like:
#   declare -A project=(
#       [_project_name_]="awesome_project"
#       [_author_]="Nguru Mugendi"
#       [_current_year_]=2013
#   )
function replace_all() {
    local txt=$1
    local -n array=$2

    for i in "${!array[@]}"; do
        # echo "${i} => ${array[$i]}"
        txt=$(replace_text "${txt}" "${i}" "${array[$i]}")
        # echo "$txt" | grep "${array[$i]}"
    done

    echo "$txt"
}


# fetches a file from the github repo using curl
function fetch_file() {
    timestamp=$(date +"%s.%3N")
    # make raw content path
    # add timestamp to force fresh fetches
    # https://raw.githubusercontent.com/mugendi/poetry-project-scaffold/master
    content_url="https://raw.githubusercontent.com/mugendi/poetry-project-scaffold/master/${1}?t={timestamp}"

    # attempt to get file
    txt=$(curl -s -H 'Cache-Control: no-cache'  -H 'Pragma: no-cache' "$content_url")

    # if nothing then throw
    if [ "x$txt" == "x" ]; then
        printf '%s\n' "Could not fecth file '${1}'. Ensure it is committed & pushed." >&2  # write error message to stderr
        exit 1 
    fi

    echo "$txt"
}

```

```bash 
# fetch file into txt var
txt=$(fetch_file "samples/mkdocs.yml")

# some vars
author="Anthony Mugz"
project_name="test_project"
# replacement dict
declare -A project=(
    [_project_name_]=$project_name
    [_author_]=$author
    [_current_year_]=$current_year
)

# replace all and write new file
replace_all "$txt" project >tests/mkdocs.yml
```

## Ensure Variable has value

```bash
# check if an existing variable contains a value
# if not, return default value
# if no default, throw an error
function ensure_var() {
    local var="$1"
    local default="$2"
    local var_name="$3"

    if [ "x$var" == "x" ]; then

        if [ "x$default" == "x" ]; then
            printf '%s\n' "Variable '${var_name}' cannot be empty! Exiting... Try again." >&2 # write error message to stderr
            exit 1
        else
            echo "${default}"
        fi
    fi

    echo "${var}"
}

```

```bash
test_var=""
test_var=$(ensure_var "$test_var" "default value" "test_var")
echo $test_var
# => default value
```

## Use Which to ensure a command exists
```bash

# check if 'which cmd' runs without error
# this function is used to check if certain commands/tools are installed
function ensure_which() {
    local cmd="$1"
    local test=$(which $cmd)

    if [ "x$test" == "x" ]; then
        printf '%s\n' "Command '${cmd}' does not exist. Please first install it." >&2 # write error message to stderr
        exit 1
    fi

    echo $test
}


ensure_which "git"
```

## Text Formatting & Colors

```bash
# replace all spaces with underscores
function snake_case() {
    local str="$1"
    echo "${str// /_}"
}

spaced_text="this is my   text"
underscored_text=$(snake_case "$spaced_text")
echo $underscored_text
# => this_is_my___text
```

```bash
#  Bash Colors
#  Read more from https://github.com/ppo/bash-colors
c() { [ $# == 0 ] && printf "\e[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\e[\1m/g'; }
cecho() { echo -e "$(c $1)${2}\e[0m"; }
```

## User Inputs

```bash
# ask user the yes/no question "Is that okay?"
# read their input and return if yes or exit if no
function is_that_ok() {
    input_q "Is that okay?" "(y/n)" "[y]"

    y_n=$(read_input "yes")

    y_n=$(echo $y_n | tr '[:upper:]' '[:lower:]')
    y_n=${y_n:0:1}

    case $y_n in
    n)
        log "" "" "Okay. Exiting Now. Please try again."
        exit
        ;;
    esac
}

# usage, 
is_that_ok
```

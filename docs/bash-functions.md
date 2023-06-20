<!--
 Copyright (c) 2023 Anthony Mugendi
 
 This software is released under the MIT License.
 https://opensource.org/licenses/MIT
-->


# Fetching a file and Replacing all contents

```bash

# trap for errors we throw
trap 'echo >&2 "$_  Line: $LINENO"; exit $LINENO;' ERR
# to throw any error, simply write it to stderr
# printf '%s\n' "My Error" >&2  # write error message to 

# replace text str with another
# takes txt match replacement
function replace-text() {
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
function replace-all() {
    local txt=$1
    local -n array=$2

    for i in "${!array[@]}"; do
        # echo "${i} => ${array[$i]}"
        txt=$(replace-text "${txt}" "${i}" "${array[$i]}")
        # echo "$txt" | grep "${array[$i]}"
    done

    echo "$txt"
}


# fetches a file from the github repo using curl
function fetch-file() {
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
txt=$(fetch-file "samples/mkdocs.yml")

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
replace-all "$txt" project >tests/mkdocs.yml
```

# Ensure Variable has value

```bash
# check if an existing variable contains a value
# if not, return default value 
# if no default, throw an error
function ensure-var() {    
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

test_var=""
test_var=$(ensure-var "$test_var" "default value" "test_var")
echo $test_var
# => default value
```
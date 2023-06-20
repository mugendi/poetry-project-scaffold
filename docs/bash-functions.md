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
#   declare -A company=(
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

# fetches a file from the github repo using wget
function fetch-file() {
    # make raw content path
    content_url="https://github.com/mugendi/poetry-project-scaffold/raw/master/${1}"

    # attempt to get file
    txt=$(wget -qO- $content_url)

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
declare -A company=(
    [_project_name_]=$project_name
    [_author_]=$author
    [_current_year_]=$current_year
)

# replace all and write new file
replace-all "$txt" company >tests/mkdocs.yml
```
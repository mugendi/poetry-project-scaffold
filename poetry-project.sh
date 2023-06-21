#!/usr/bin/bash

# BASED ON
# 1. https://medium.com/mlearning-ai/how-to-start-any-professional-python-package-project-9f66538ebc2

# trap for errors we throw
trap 'echo >&2 "$_  Line: $LINENO"; exit $LINENO;' ERR
# to throw any error, simply write it to stderr
# printf '%s\n' "My Error" >&2  # write error message to stderr
# exit

# some defaults

# Terminal Size
lines=$(tput lines)
columns=$(tput cols)
format_line_length=90

# ************************************************************************************
# parse & check our command args
new_project=true
src_layout=false
default_inputs=false

while getopts 'isy' opt; do
    case $opt in
    # similar to poetry
    i) new_project=false ;;
    # use src layout
    s) src_layout=true ;;
    # answer yes to inputs and thus use defaults
    y) default_inputs=true ;;
    *)
        echo 'Error in command line parsing. Expects -i/-y/-s' >&2
        exit 1
        ;;

    esac
done

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function dedent() {
    local -n reference="$1"
    reference="$(echo "$reference" | sed 's/^[[:space:]]*//')"
}

function log_multi() {
    dedent $1
    printf "$1"
}

function border() {
    local str="$*" # Put all arguments into single string
    local len=${#str}
    local i
    for ((i = 0; i < len + 4; ++i)); do
        printf '-'
    done
    printf "\n| $str |\n"
    for ((i = 0; i < len + 4; ++i)); do
        printf '-'
    done
    echo
}

function line() {
    for ((i = 0; i < columns - 1; ++i)); do
        printf "$1"
    done
    echo
}

# Replace the line of the given line number with the given replacement in the given file.
function replace_line_in_file() {
    local file="$1"
    local line_num="$2"
    local replacement="$3"

    # Escape backslash, forward slash and ampersand for use as a sed replacement.
    replacement_escaped=$(echo "$replacement" | sed -e 's/[\/&]/\\&/g')
    # echo $line_num $replacement_escaped

    sed -i "${line_num}s/.*/$replacement_escaped\n/" "$file"
}

function replace_above_section() {

    local file="$1"
    local section="$2"
    local replacement="$3"

    # get line above section given
    local dependencies_line=$(cat -n $file | grep "$section" | awk '{ print $1}')
    dependencies_line="$(($dependencies_line - 1))"

    if ((dependencies_line > 0)); then
        replace_line_in_file $file $dependencies_line $replacement
    fi

}

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
    txt=$(curl -s -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "$content_url")

    # if nothing then throw
    if [ "x$txt" == "x" ]; then
        printf '%s\n' "Could not fecth file '${1}'. Ensure it is committed & pushed." >&2 # write error message to stderr
        exit 1
    fi

    echo "$txt"
}

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

# replace all spaces with underscores
function snake_case() {
    local str="$1"
    echo "${str// /_}"
}

function input_q() {
    log "$(c s)$1$(c 0) $2 $3$4"
}

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

function read_input() {
    if ! $default_inputs; then
        read input_val
        echo "$input_val"
    fi
}

# Bash Colors
#  https://github.com/ppo/bash-colors
c() { [ $# == 0 ] && printf "\e[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\e[\1m/g'; }
cecho() { echo -e "$(c $1)${2}\e[0m"; }

#  ┌───────┬────────────────┬─────────────────┐   ┌───────┬─────────────────┬───────┐
#  │ Fg/Bg │ Color          │ Octal           │   │ Code  │ Style           │ Octal │
#  ├───────┼────────────────┼─────────────────┤   ├───────┼─────────────────┼───────┤
#  │  K/k  │ Black          │ \e[ + 3/4  + 0m │   │  s/S  │ Bold (strong)   │ \e[1m │
#  │  R/r  │ Red            │ \e[ + 3/4  + 1m │   │  d/D  │ Dim             │ \e[2m │
#  │  G/g  │ Green          │ \e[ + 3/4  + 2m │   │  i/I  │ Italic          │ \e[3m │
#  │  Y/y  │ Yellow         │ \e[ + 3/4  + 3m │   │  u/U  │ Underline       │ \e[4m │
#  │  B/b  │ Blue           │ \e[ + 3/4  + 4m │   │  f/F  │ Blink (flash)   │ \e[5m │
#  │  M/m  │ Magenta        │ \e[ + 3/4  + 5m │   │  n/N  │ Negative        │ \e[7m │
#  │  C/c  │ Cyan           │ \e[ + 3/4  + 6m │   │  h/H  │ Hidden          │ \e[8m │
#  │  W/w  │ White          │ \e[ + 3/4  + 7m │   │  t/T  │ Strikethrough   │ \e[9m │
#  ├───────┴────────────────┴─────────────────┤   ├───────┼─────────────────┼───────┤
#  │  High intensity        │ \e[ + 9/10 + *m │   │   0   │ Reset           │ \e[0m │
#  └────────────────────────┴─────────────────┘   └───────┴─────────────────┴───────┘

#  Usage
#  printf "$(c sW)Bold white$(c) and normal"
#  echo -e "Normal text… $(c sRy)BOLD red text on yellow background… $(c w)now on white background… $(c 0u) reset and underline… $(c) and back to normal."
#  cecho Wb "White text on blue background"

function log() {
    # echo
    echo -e " $1$(c G)$2$(c 0)$(c R)$3$(c 0)"
}

function section() {

    echo
    line "$(c C)-$(c 0)"
    log_multi "    
 SECTION : $(c s)$1$(c)
$(c di)           $2$(c 0)
"
    line "$(c Cd)-$(c 0)"
}

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

    local text=$(ensure_var "$1" "NO TEXT ENTERED!!!")
    local emoji=$(ensure_var "$2" "note")
    emoji=$(emoji "$emoji")    

    log "$(c sY)$emoji NOTE:$(c 0) $(c iY)$text$(c 0)"

}




# ************************************************************************************

# ensuring requirements are met
section "System Requirements" "Ensuring all needed requirements (git, python>3.9, poetry e.t.c) are met/installed."

# ensure we can run important commands
# head
which_head=$(ensure_which "head")
# grep
which_grep=$(ensure_which "grep")
# curl
which_curl=$(ensure_which "curl")
# wget
which_wget=$(ensure_which "wget")
# awk
which_awk=$(ensure_which "awk")
# git
which_git=$(ensure_which "git")
# python
which_python=$(ensure_which "python3")
# poetry
which_poetry=$(ensure_which "poetry")

# Some defaults & variables
current_year=$(date +%Y)
default_user=$(git config user.name)
default_email=$(git config user.email)
default_version="0.1.0"
default_project_name="poetry_project"
default_version="0.1.0"

# Get Python Version
python_version=$($which_python --version | awk '{print $2}')
python_version=${python_version:0:3}

# Ensure we are on version 3.9 and upwards...
if [ $(version $python_version) -lt $(version "3.8.1") ]; then
    log "" "" "You are running Python $python_version on $OS"
    log "" "" "You need at least version 3.8.1 to use flake8. Exiting..."
    exit
fi

log "All requirements have been satisfied ✔ " "
   - $(grep --version | head -n 1)
   - $(awk --version | head -n 1)
   - $(head --version | head -n 1)
   - $(wget --version | head -n 1)
   - $(curl --version | head -n 1 | awk '{print $1 " " $2}')
   - $(git --version)
   - $($which_python --version)
   - $(poetry --version)"

# ************************************************************************************

section "Defining Project" "Set your project details"

# Author Details
input_q "Enter Your Name" "[$default_user]:"
author=$(read_input)

author=$(ensure_var "$author" "$default_user" "name")
email=$(ensure_var "$default_email" "<email>" "email")

# Project Details
input_q "Project Name" "[$default_project_name]:"
project_name=$(read_input)
project_name=$(ensure_var "$project_name" "$default_project_name" "Project Name")
# project name should have no spaces
project_name=$(snake_case "$project_name")

input_q "Project Version" "[$default_version]:"
project_version=$(read_input)
project_version=$(ensure_var "$project_version" "$default_version" "Project Name")

# Show project summary and ask to continue
log "Awesome! Project details below will be used: \n" "\tAuthor: $(c Ws)$author$(c 0G), Project: $(c Ws)$project_name$(c 0G), Version: $(c Ws)$project_version$(c 0)\n"

is_that_ok


# ************************************************************************************

# now create new poetry project or convert existing
section "Project Initialization" "Setting up project: 
           - Updates configs
           - Initializes git
           - Creates virtual environment
           "

if $new_project; then
    if $src_layout; then
        log ">> Creating new poetry project (src layout) ~ " "poetry new --src ${project_name}"
        poetry new --src "$project_name"
    else
        log ">> Creating new poetry project (pkg_name layout) ~ " "poetry new ${project_name}"
        poetry new "$project_name"
    fi

fi

# now get into project dir
work_in_project_dir() {

    # replacement dict
    declare -A replacements=(
        [_project_name_]=$project_name
        [_author_]=$author
        [_current_year_]=$current_year
        [_python_version_str_]="python${python_version}"
    )

    function fetch_and_replace() {
        txt=$(fetch_file $1)
        replace_all "$txt" replacements >$2
    }

    if $new_project; then
        # cd into project dir
        cd "$project_name"
    else
        # we assume we are already in directory
        # ask user first
        log "We will init poetry in current dir: " "$(pwd)\n"
        is_that_ok

        # init poetry
        if $src_layout; then
            log ">> Initializing poetry project (src layout) ~ " "poetry init --src"
            poetry init --src
        else
            log ">> Creating new poetry project (pkg_name layout) ~ " "poetry init"
            poetry init
        fi

    fi

    # ************************************************************************************

    # Update pyproject.toml
    echo
    log ">> Updating pyproject.toml ~ " ">> pyproject.toml"
    replace_above_section "pyproject.toml" "tool.poetry.dependencies" '#https://github.com/python-poetry/poetry/blob/master/pyproject.toml'
    replace_above_section "pyproject.toml" "tool.poetry.dependencies" '#https://gist.github.com/nazrulworld/3800c84e28dc464b2b30cec8bc1287fc'
    replace_above_section "pyproject.toml" "tool.poetry.dependencies" 'classifiers=[]'
    replace_above_section "pyproject.toml" "tool.poetry.dependencies" 'keywords=[]'
    replace_above_section "pyproject.toml" "tool.poetry.dependencies" 'maintainers=[]'

    replace_above_section "pyproject.toml" "tool.poetry.dependencies" '#license="MIT"'
    replace_above_section "pyproject.toml" "tool.poetry.dependencies" '#homepage="https://docs/"'
    replace_above_section "pyproject.toml" "tool.poetry.dependencies" '#repository="https://repo/"'

    # add black
    fetch_file "samples/pyproject-extras.toml" >>pyproject.toml

    # make git...
    echo
    log ">> Initializing git ... ~ " "git init"
    git init

    # adding python git ignore
    echo
    git_ignore_url="https://www.toptal.com/developers/gitignore/api/python?format=lines"
    log ">> Adding python .gitignore from gitignore.io ~ " "wget $git_ignore_url"
    wget $git_ignore_url -q -O .gitignore

    # because packages like flint8 sometimes instsits on version 3.8
    sed -i "s/python = \"^3.8\"/python = \"^$python_version\"/" ./pyproject.toml

    # create virtual environment
    echo
    log ">> Creating virtual environment with venv ~ " "python -m venv env"
    $which_python -m venv env

    # activate local environment
    echo
    log ">> Activating local environment ~ " "source env/bin/activate"
    source env/bin/activate


    # ************************************************************************************

    section "Installing Dependencies" "Installing all important dependecies such as flake8, pytest, mkdocs and more.."

    # install dependecies
    echo
    log ">> Installing test dependencies... ~ " "poetry addpytest flake8 --group test"
    poetry add pytest flake8 --group test

    echo
    log ">> Installing dev dependecies... ~ " "poetry add black isort --group dev"
    poetry add black isort --group dev

    # ************************************************************************************

    section "Preparing for Tests" "- Configures flake8, isort & black, 
           - Creates dummy test file
           - Performs tests & linting via pytest, isort, black and flake8"

    log ">> Creating .flake8 file ~ " "> .flake8"
    fetch_and_replace "samples/.flake8" ".flake8"

    echo
    log ">> Creating dummy test file ~ " "> ./tests/test_dummy.py"
    dummy_test_text=$(fetch_file "samples/test_dummy.py")
    echo "$dummy_test_text" >"./tests/test_dummy.py"

    echo
    log ">> Running pytest ~ " "poetry run pytest -v"
    poetry run pytest -v

    echo
    log ">> Running isort ~ " "poetry run isort tests/"
    poetry run isort tests/

    echo
    log ">> Running black formatter ~ " "poetry run black tests/"
    poetry run black tests/

    echo
    log ">> Running flake8 ~ " "poetry run flake8 tests/"
    poetry run flake8 tests/

    echo
    log "" "Dummy test file was:"
    # show results
    echo -e "___________________\n\n$dummy_test_text\n___________________"

    echo
    log "" "Dummy test file now formatted to:"
    formatted_dummy_test_text=$(cat ./tests/test_dummy.py)
    echo -e "___________________\n\n$formatted_dummy_test_text\n___________________"

    echo
    note "You note a difference in the original and formatted dummy test files.
       This is because black & isort have done their magic 🪄" "up"

    # ************************************************************************************

    section "Setting up a test automation" "Creating git hooks to automate testing and standardize code styling"

    log ">> Creating pre-commit-hook file ~ " ".pre-commit-config.yaml"
    fetch_and_replace "samples/.pre-commit-config.yaml" ".pre-commit-config.yaml"

    echo
    log ">> Installing pre-commit dependecies ~ " "poetry add pre-commit --group dev"
    poetry add pre-commit --group dev

    echo
    log ">> Running pre-commit install ~ " "poetry run pre-commit install"
    poetry run pre-commit install

    echo
    log ">> Running pre-commit autoupdate ~ " "poetry run pre-commit autoupdate"
    # poetry run pre-commit autoupdate

    echo
    log ">> Running pre-commit run --all-files ~ " "poetry run pre-commit run --all-files"
    # because first run results in an error, we want to add || true
    poetry run pre-commit run --all-files || true

    # test commit
    echo
    log ">> Running test commit ~ " "git add tests/test_dummy.py && git commit -m 'Commiting dummy test'"

    git add tests/test_dummy.py
    git commit -m "Commiting dummy test" || true

    echo
    log ">> Checking git status ~ " "git status -s tests/"
    echo
    git status -s tests/

    echo
    note "You should see:
       $(c sG)A$(c 0) $(c sW)tests/test_dummy.py$(c 0) 
       $(c iY)Since commit should have failed because flake8 tests fail. Error Code $(c sR)F401. $(c 0)" "up"

    echo
    log ">> Removing Dummy Test ~ " "rm ./tests/test_dummy.py"
    rm ./tests/test_dummy.py

    # ************************************************************************************

    section "Setting up documentation" "- Configures flake8, isort & black, 
           - Installs dependencies needed
           - Creates mkdocs.yml with mkdocs, themes & plugins configurations
           - Initializes mkdocs to generate docs folder
           - Creates placeholder README.md
           - Creates initial index.md in ./docs folder"

    log ">> Installing docs dependencies ~ " "poetry add mkdocs mkdocstrings mkdocstrings-python mkdocs-ansible markdown-include --group doc"
    poetry add mkdocs mkdocstrings mkdocstrings-python mkdocs-ansible markdown-include --group doc

    echo
    log ">> Creating mkdocs.yml ~ " "> mkdocs.yml"
    fetch_and_replace "samples/mkdocs.yml" "mkdocs.yml"

    # create readme
    echo
    log ">> Creating README.md ~ " "> README.md"
    fetch_and_replace "samples/README.md" "README.md"

    # create index docs file
    echo
    log ">> Creating docs/index.md ~ " "> docs/index.md"
    mkdir docs
    fetch_and_replace "samples/index.md" "docs/index.md"

    echo
    log "" "Finished setting up $poetry_project! Go through the logs $(emoji "up") to check for any warnings or errors."

    echo 
    note "Remember to update $(c Bs)'./poetry_project/pyproject.toml$(c 0Yi) and:$(c Wi)
         - Add $(c  s)'keywords'$(c 0Wi)
         - Add $(c  s)'classifiers'$(c 0Wi) see: $(c Bu)https://gist.github.com/nazrulworld/3800c84e28dc464b2b30cec8bc1287fc$(c 0Wi) 
         - Select correct $(c  s)'license'$(c 0Wi)
         - Edit $(c  s)'homepage'$(c 0Wi) and $(c  s)'repository'$(c 0Wi) values
         $(c 0)"

    echo
    note "For documentation, you can now:
         $(c W)- Build docs with >> $(c Bs)mkdocs build$(c 0)
         $(c Wi)- Serve docs with >> $(c Bs)mkdocs serve$(c 0)
         $(c Wi)- Deploy docs with >> $(c Bs)mkdocs gh-deploy$(c 0)" "tick"

    echo

}

work_in_project_dir

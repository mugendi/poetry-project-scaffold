#!/usr/bin/bash

# BASED ON
# 1. https://medium.com/mlearning-ai/how-to-start-any-professional-python-package-project-9f66538ebc2

# trap for errors we throw
trap 'echo >&2 "$_  Line: $LINENO"; exit $LINENO;' ERR
# to throw any error, simply write it to stderr
# printf '%s\n' "My Error" >&2  # write error message to stderr
# exit

unameOut=$(uname -a)
case "${unameOut}" in
*Microsoft*) OS="WSL" ;;  #must be first since Windows subsystem for linux will have Linux in the name too
*microsoft*) OS="WSL2" ;; #WARNING: My v2 uses ubuntu 20.4 at the moment slightly different name may not always work
Linux*) OS="Linux" ;;
Darwin*) OS="Mac" ;;
CYGWIN*) OS="Cygwin" ;;
MINGW*) OS="Windows" ;;
*Msys) OS="Windows" ;;
*) OS="UNKNOWN:${unameOut}" ;;
esac

# Color Values
RED="\e[31m"
GREEN="\e[32m"
BOLDGREEN="\e[1;${GREEN}m"
ITALICRED="\e[3;${RED}m"
WHITE="\e[97m"
ENDCOLOR="\e[0m"
DIM="\e[2m"

# Terminal Size
lines=$(tput lines)
columns=$(tput cols)
current_year=$(date +%Y)

format_line_length=90

function log() {
    # echo
    echo -e "$1${GREEN}${2}${ENDCOLOR}${RED}$3${ENDCOLOR}"
}

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

function section() {
    echo
    echo
    line "${WHITE}░${ENDCOLOR}"
    log_multi "    
SECTION : ${GREEN}$1${ENDCOLOR}
${DIM}$2${ENDCOLOR}
"
    line "${DIM}-${ENDCOLOR}"
}

# Replace the line of the given line number with the given replacement in the given file.
function replace-line-in-file() {
    local file="$1"
    local line_num="$2"
    local replacement="$3"

    # Escape backslash, forward slash and ampersand for use as a sed replacement.
    replacement_escaped=$(echo "$replacement" | sed -e 's/[\/&]/\\&/g')
    # echo $line_num $replacement_escaped

    sed -i "${line_num}s/.*/$replacement_escaped\n/" "$file"
}

function replace-above-section() {

    local file="$1"
    local section="$2"
    local replacement="$3"

    # get line above section given
    local dependencies_line=$(cat -n $file | grep "$section" | awk '{ print $1}')
    dependencies_line="$(($dependencies_line - 1))"

    if ((dependencies_line > 0)); then
        replace-line-in-file $file $dependencies_line $replacement
    fi

}

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
exit

# some vars
author="Anthony Mugz"
project_name="test_project"
python_version=3.9

# replacement dict
declare -A replacements=(
    [_project_name_]=$project_name
    [_author_]=$author
    [_current_year_]=$current_year
    [_python_version_str_]="python${python_version}"
)

# replace all and write new file
txt=$(fetch-file "samples/mkdocs.yml")
replace-all "$txt" replacements >tests/mkdocs.yml

txt=$(fetch-file "samples/extra.css")
replace-all "$txt" replacements >tests/extra.css

txt=$(fetch-file "samples/.flake8")
replace-all "$txt" replacements >tests/.flake8

txt=$(fetch-file "samples/.pre-commit-config.yaml")
replace-all "$txt" replacements >tests/.pre-commit-config.yaml

txt=$(fetch-file "samples/README.md")
replace-all "$txt" replacements >tests/README.md

exit

section "Defining Project" "Set your project name"

default_version="0.1.0"

# default project
if [ "x$1" == "x" ]; then
    default_project="my_poetry_project"
else
    default_project=$1
fi

echo What is your name:
read author

if [ "x$author" == "x" ]; then
    log "" "" 'You did not enter your name. Exiting. Please try again.'
    exit
fi

# input project name
echo Enter project name [$default_project]:
read project_name

if [ "x$project_name" == "x" ]; then
    log "You did not enter a project name." " Using '${default_project}'"
    project_name=$default_project
fi

echo Enter project version [$default_version]:
read version

if [ "x$version" == "x" ]; then
    log ">> Using default version '${default_version}'"
    version=$default_version
fi

# project name should have no spaces
project_name=$(echo $project_name | tr -d ' ')

# Show project summary and ask to continue
log ">> Awesome we will set up the project: " "Author: $author, Project: $project_name, Version: $version"

log ">> Is that okay? (y/n) [y] ?"
read y_n
y_n=$(echo $y_n | tr '[:upper:]' '[:lower:]')
y_n=${y_n:0:1}

case $y_n in
n)
    log "" "" "Okay. Exiting Now. Please try again."
    exit
    ;;
esac

section "Checking Requirements" "Ensures supported versions of Python and Poetry are installed. "

# check python version
log ">> Checking Python version ~ " "python -c 'import platform; print(platform.python_version())"

# https://stackoverflow.com/a/67890569/1462634
python_version=$(python -c 'import platform; print(platform.python_version())')
python_version=${python_version:0:3}

# Ensure we are on version 3.9 and upwards...
if [ $(version $python_version) -lt $(version "3.8.1") ]; then
    log "" "" "You are running Python $python_version on $OS"
    log "" "" "You need at least version 3.8.1 to use flake8. Exiting..."
    exit
fi

# ensure poetry is installed
log ">> Ensuring poetry is installed ~ " "command -v poetry"
if ! [ -x "$(command -v poetry)" ]; then

    log '' '' 'poetry is not installed. Do you want to install with `pip install -U poetry` (y/n) [y] ?'
    read i_poetry
    i_poetry=$(echo $i_poetry | tr '[:upper:]' '[:lower:]')
    i_poetry=${i_poetry:0:1}

    case $i_poetry in
    y)
        pip install -U poetry
        ;;
    *)
        log "Okay, first install poetry then try again. Exiting Now..."
        exit
        ;;
    esac
fi

log "" "All Good! You are running Python $python_version on $OS and Poetry is installed"

section "Initializing Project" "Creates project, creates and activates virtual environment, generates required config files"

echo
# Initialize project
log ">> Initializing project $project_name..."

# make poetry project
poetry new "./${project_name}"

work_in_project_dir() {
    cd $1

    # make git...
    echo
    log ">> Initializing git ... ~ " "git init"
    git init
    git_ignore_url="https://www.toptal.com/developers/gitignore/api/$OS,Python?format=lines"

    log ">> Adding .gitignore from gitignore.io- > [$OS,Python] ~ " "wget $git_ignore_url -q -O .gitignore"
    wget $git_ignore_url -q -O .gitignore

    # because poetry sometimes instsits on version 3.8
    sed -i "s/python = \"^3.8\"/python = \"^$python_version\"/" ./pyproject.toml

    # make virual environment
    echo
    log ">> Creating virtual environment ~ " "python3 -m venv env"
    python3 -m venv env

    # activate local environment
    log ">> Activating local environment ~ " "source env/bin/activate"
    source env/bin/activate

    #
    log ">> Writing important pyproject.toml defaults ~ " ">>pyproject.toml"
    replace-above-section "pyproject.toml" "tool.poetry.dependencies" '#https://github.com/python-poetry/poetry/blob/master/pyproject.toml'
    replace-above-section "pyproject.toml" "tool.poetry.dependencies" '#https://gist.github.com/nazrulworld/3800c84e28dc464b2b30cec8bc1287fc'
    replace-above-section "pyproject.toml" "tool.poetry.dependencies" 'classifiers=[]'
    replace-above-section "pyproject.toml" "tool.poetry.dependencies" 'keywords=[]'
    replace-above-section "pyproject.toml" "tool.poetry.dependencies" 'maintainers=[]'

    replace-above-section "pyproject.toml" "tool.poetry.dependencies" '#license="MIT"'
    replace-above-section "pyproject.toml" "tool.poetry.dependencies" '#homepage="https://docs/"'
    replace-above-section "pyproject.toml" "tool.poetry.dependencies" '#repository="https://repo/"'

    cat <<EOT >>pyproject.toml

[tool.black]
line-length = ${format_line_length}
exclude = '''
/(
    \.git
  | \.hg
  | \.mypy_cache
  | \.tox
  | \.venv
  | _build
  | buck-out
  | build
  | dist
  | docs
)/
'''

[tool.pytest.ini_options]
addopts = "-n auto"
testpaths = ["tests"]

EOT

    log ">> Creating .flake8 file"
    # make flake8 conf file
    cat <<EOT >>.flake8
[flake8]
ignore = E203, E266, W503, F403, W293
max-line-length = ${format_line_length}
max-complexity = 10
select = B,C,E,F,W,T4,B9
per-file-ignores=
    __init__.py: F401
EOT

    section "Dependency Installation" "Installs all required dependecies"

    # install dependecies
    echo
    log ">> Installing test dependencies... ~ " "poetry addpytest flake8 --group test"
    poetry add pytest flake8 --group test

    echo
    log ">> Adding dev dependecies... ~ " "poetry add black isort --group dev"
    poetry add black isort --group dev

    section "Running Tests" "Creates dummy test file, performs tests & linting via pytest, isort, black and flake8"

    log ">> Making dummy test ~ " ">>./tests/test_one.py"
    cat <<EOT >>./tests/test_one.py

from os import path
import os
def test_dummy():
    assert 1==1

EOT

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
    log_multi "___________________

from os import path
import os
def test_dummy():
    assert 1==1
___________________

"
    echo
    log "" "Dummy test file now formatted to:"
    out=$(cat ./tests/test_one.py)
    log "___________________\n\n$out\n___________________"

    # echo
    # > .pre-commit-config.yaml

    section "Setting up a test automation" "Creating git hooks to automate testing and standardize code styling"

    echo
    log ">> Creating pre-commit-hook file ~ " ".pre-commit-config.yaml"
    cat <<EOT >>.pre-commit-config.yaml
# isort
repos:
  - repo: https://github.com/asottile/seed-isort-config
    rev: v2.2.0
    hooks:
      - id: seed-isort-config

  - repo: https://github.com/pre-commit/mirrors-isort
    rev: v5.10.1
    hooks:
      - id: isort

  # black
  - repo: https://github.com/ambv/black
    rev: 22.8.0
    hooks:
      - id: black
        args: 
          # arguments to configure black
          - --line-length=${format_line_length}
          - --include='\.pyi?$'

          # these folders wont be formatted by black
          - --exclude="""\.git |
            \.__pycache__|
            \.hg|
            \.mypy_cache|
            \.tox|
            env|
            _build|
            buck-out|
            build|
            dist|
            docs"""

        language_version: python${python_version}

  # flake8
  - repo: https://github.com/PyCQA/flake8
    rev: 5.0.4
    hooks:
      - id: flake8
        args: 
          # arguments to configure flake8
          # making isort line length compatible with black
          - "--max-line-length=${format_line_length}"
          - "--max-complexity=10"
          - "--select=B,C,E,F,W,T4,B9"

          # these are errors that will be ignored by flake8
          # check out their meaning here
          # https://flake8.pycqa.org/en/latest/user/error-codes.html
          - "--ignore=E203,E266,W503,F403,W293,W293"

EOT

    log ">> Installing pre-commit dependecies ~ " "poetry add pre-commit --group dev"
    poetry add pre-commit --group dev

    log ">> Running pre-commit install ~ " "poetry run pre-commit install"
    poetry run pre-commit install

    log ">> Running pre-commit autoupdate ~ " "poetry run pre-commit autoupdate"
    poetry run pre-commit autoupdate

    log ">> Running pre-commit run --all-files ~ " "poetry run pre-commit run --all-files"
    # because first run results in an error, we want to add || true
    poetry run pre-commit run --all-files || true

    # test commit
    log ">> Running test commit ~ " "git add tests/test_one.py && git commit -m 'Commiting dummy test'"
    git add tests/test_one.py
    git commit -m "Commiting dummy test" || true

    log ">> Removing Dummy Test ~ " "rm ./tests/test_one.py"
    rm ./tests/test_one.py

    section "Create documentation" "Creates docs folder, installs & configures mkdocs "

    log ">> Installing docs modules ~ " "poetry add mkdocs mkdocstrings mkdocstrings-python mkdocs-ansible markdown-include --group doc"
    poetry add mkdocs mkdocstrings mkdocstrings-python mkdocs-ansible markdown-include --group doc

    log ">> Creating mkdocs.yml ~ " ">>mkdocs.yml"

    cat <<EOT >>mkdocs.yml
site_name: $project_name
copyright: Copyright © $current_year $author.

# Change to correct repo details
# site_url: https://ansible-compat.readthedocs.io/ 
# repo_url: https://github.com/ansible/ansible-compat
#edit_uri: blob/main/docs/

docs_dir: docs

# navigation bar
nav: 
  - index.md

# Watch
watch:
  - mkdocs.yml
  - $project_name
  - docs

# Theme
# https://squidfunk.github.io/mkdocs-material/reference/
theme:
    name: ansible
    highlightjs: true
    features:
      - content.code.copy
      - content.action.edit
      - navigation.expand
      - navigation.sections
      - navigation.instant
      - navigation.indexes
      - navigation.tracking
      - toc.integrate


# Plugins
plugins:
  - autorefs
  - material/search
  - material/social
  - material/tags
  - mkdocstrings:
      handlers:
        python:
          import:
            - https://docs.python.org/3/objects.inv
          options:
            # heading_level: 2
            docstring_style: sphinx
            docstring_options:
              ignore_init_summary: yes

            show_submodules: yes
            docstring_section_style: list
            members_order: alphabetical
            show_category_heading: no
            # cannot merge init into class due to parse error...
            # merge_init_into_class: yes
            show_root_heading: yes
            show_signature_annotations: yes
            separate_signature: yes
            show_bases: false
 
# markdown extensions
# https://facelessuser.github.io/pymdown-extensions/#extensions
markdown_extensions:
  - markdown_include.include:
      base_path: docs
  - admonition
  - def_list
  - footnotes
  - pymdownx.saneheaders
  - pymdownx.smartsymbols
  - pymdownx.highlight:
      anchor_linenums: true
      linenums : true
      auto_title: false
  - pymdownx.inlinehilite
  - pymdownx.superfences
  - pymdownx.magiclink:
      repo_url_shortener: true
      repo_url_shorthand: true
      social_url_shorthand: true
      social_url_shortener: true
      user: facelessuser
      repo: pymdown-extensions
      normalize_issue_symbols: true
  - pymdownx.tabbed:
      alternate_style: true  
  - pymdownx.emoji
  - toc:
      toc_depth: 4
      permalink: true
  - pymdownx.superfences

EOT

    # create index docs file
    log ">> Creating docs/index.md ~ " ">>docs/index.md"
    mkdir docs

    cat <<EOT >>docs/index.md

{!../README.md!}

EOT

    log ">> Updating README.md ~ " ">>README.md"
    mkdir docs

    cat <<EOT >>README.md

# ${project_name}

Summary

## How To Use

Use \`${project_name}\` as shown below

\`\`\`python
# Code here...
import os
print(os.getcwd())
\`\`\`

## MkDocs Config

\`\`\`yaml
{!../mkdocs.yml!}
\`\`\`

## Symbols & Emoji
| Emoji | Symbols |
|---|---|
|:smile: :heart: :thumbsup: | (tm)  (c)  (r)  c/o <br/> -->  <--  <-->  =/=  +/- <br/> 1/2 1/4 1st  2nd  3rd|

EOT

    # Create/Update files
    # update pyproject.toml
    log ">> Editing pyproject.toml ~ " " >>pyproject.toml"
    cat <<EOT >>pyproject.toml
    
[tool.isort]
profile = "black"

# optional groups
[tool.poetry.group.dev]
optional = true

[tool.poetry.group.test]
optional = true

[tool.poetry.group.doc]
optional = true


EOT

    log "[!]" "You can build docs with >> " "mkdocs build"
    log "[!]" "Alternatively serve docs with >> " "mkdocs serve"
    log "[!]" "Deploy docs with >> " "mkdocs gh-deploy"
}

# we need a function in order to cd into dict
work_in_project_dir $project_name

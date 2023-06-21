#!/usr/bin/bash

# remove project if existing
rm -rf poetry_project | true

# command we want to run
# use -y to step through all inputs
cmd="bash poetry-project.sh -y"

echo "Recording ~> '$cmd'..."

# run aciinema with -c command input and -y flag to step through prompts and upload
asciinema rec -c "$cmd" assets/recording.cast --overwrite 

echo "Generating gif..."

ttygif --input  assets/recording.cast --output assets/recording.gif --fps=15 --speed .35 --theme mac

# delete cast file
rm assets/recording.cast 




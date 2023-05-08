#!/bin/bash

# This script also supports .bashrc file.

# To automatically leverage Node Version Manager (nvm) to detect and use a specific Node.js version 
# when entering a project directory, please first input version of Node.json into .nvmrc file, 
# which is located in your root project dir, and shell hooks to automate the process.

# Check for the presence of a package.json file, which is a common indicator of a Node.js project.
cd() {
  builtin cd "$@"
  [ -f "package.json" ] && nvm_auto_switch
}

nvm_auto_switch() {
  if [ -f ".nvmrc" ]; then
    nvm use
  elif [ -n "$NVM_DIR" ]; then
    nvm use default
  fi
}

# Don't forget to source ~/.bash_profile

#!/bin/bash

# To automatically leverage Node Version Manager (nvm) to detect and use a specific Node.js version 
# when entering a project directory, please first input version of Node.json into .nvmrc file, 
# which is located in your root project dir, and shell hooks to automate the process.

# Check for the presence of a package.json file, which is a common indicator of a Node.js project.
autoload -U add-zsh-hook
load-nvm-auto-switch() {
  if [ -f "package.json" ]; then
    if [ -f ".nvmrc" ]; then
      nvm use
    elif [ -n "$NVM_DIR" ]; then
      nvm use default
    fi
  fi
}
add-zsh-hook chpwd load-nvm-auto-switch

# Don't forget to source ~/.zshrc
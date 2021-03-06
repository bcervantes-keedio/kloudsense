#!/bin/bash -
#title           :ks_cli_rc
#description     :Source file for KloudSense CLI
#author          :Alejandro Villegas Lopez (avillegas@keedio.com).
#===============================================================================

KS_HOME="$( cd "$(dirname "$0")" ; pwd -P )"
source $KS_HOME/ks_shell/environment




#=============================
# Prompt
#===============================================================================
# Get the String to print the profile in bash prompt
PS1='\[\033[31m\][KShell] \[\033[33m\]\u\[\033[37m\]:\[\033[34m\]\W\[\033[36m\]$\[\033[0m\] '
export LS_COLORS="rs=0:di=38;5;27:ln=38;5;51:mh=44;38;5;15:pi=40;38;5;11:so=38;5;13:do=38;5;5:bd=48;5;232;38;5;11:cd=48;5;232;38;5;3:or=48;5;232;38;5;9:mi=05;48;5;232;38;5;15:su=48;5;196;38;5;15:sg=48;5;11;38;5;16:ca=48;5;196;38;5;226:tw=48;5;10;38;5;16:ow=48;5;10;38;5;21:st=48;5;21;38;5;15:ex=38;5;34:*.tar=38;5;9:*.tgz=38;5;9:*.arc=38;5;9:*.arj=38;5;9:*.taz=38;5;9:*.lha=38;5;9:*.lz4=38;5;9:*.lzh=38;5;9:*.lzma=38;5;9:*.tlz=38;5;9:*.txz=38;5;9:*.tzo=38;5;9:*.t7z=38;5;9:*.zip=38;5;9:*.z=38;5;9:*.Z=38;5;9:*.dz=38;5;9:*.gz=38;5;9:*.lrz=38;5;9:*.lz=38;5;9:*.lzo=38;5;9:*.xz=38;5;9:*.bz2=38;5;9:*.bz=38;5;9:*.tbz=38;5;9:*.tbz2=38;5;9:*.tz=38;5;9:*.deb=38;5;9:*.rpm=38;5;9:*.jar=38;5;9:*.war=38;5;9:*.ear=38;5;9:*.sar=38;5;9:*.rar=38;5;9:*.alz=38;5;9:*.ace=38;5;9:*.zoo=38;5;9:*.cpio=38;5;9:*.7z=38;5;9:*.rz=38;5;9:*.cab=38;5;9:*.jpg=38;5;13:*.jpeg=38;5;13:*.gif=38;5;13:*.bmp=38;5;13:*.pbm=38;5;13:*.pgm=38;5;13:*.ppm=38;5;13:*.tga=38;5;13:*.xbm=38;5;13:*.xpm=38;5;13:*.tif=38;5;13:*.tiff=38;5;13:*.png=38;5;13:*.svg=38;5;13:*.svgz=38;5;13:*.mng=38;5;13:*.pcx=38;5;13:*.mov=38;5;13:*.mpg=38;5;13:*.mpeg=38;5;13:*.m2v=38;5;13:*.mkv=38;5;13:*.webm=38;5;13:*.ogm=38;5;13:*.mp4=38;5;13:*.m4v=38;5;13:*.mp4v=38;5;13:*.vob=38;5;13:*.qt=38;5;13:*.nuv=38;5;13:*.wmv=38;5;13:*.asf=38;5;13:*.rm=38;5;13:*.rmvb=38;5;13:*.flc=38;5;13:*.avi=38;5;13:*.fli=38;5;13:*.flv=38;5;13:*.gl=38;5;13:*.dl=38;5;13:*.xcf=38;5;13:*.xwd=38;5;13:*.yuv=38;5;13:*.cgm=38;5;13:*.emf=38;5;13:*.axv=38;5;13:*.anx=38;5;13:*.ogv=38;5;13:*.ogx=38;5;13:*.aac=38;5;45:*.au=38;5;45:*.flac=38;5;45:*.mid=38;5;45:*.midi=38;5;45:*.mka=38;5;45:*.mp3=38;5;45:*.mpc=38;5;45:*.ogg=38;5;45:*.ra=38;5;45:*.wav=38;5;45:*.axa=38;5;45:*.oga=38;5;45:*.spx=38;5;45:*.xspf=38;5;45:"

_OS=$(uname)

if [[ $_OS == "Darwin" ]]; then
  alias ls="ls -G"
else
  alias ls="ls --color"
fi

unset _OS




#=============================
# System Management
#===============================================================================

# Run the cluster init config to deploy
function _ks_system_bootstrap () {
  _ks_is_mode_selected
  [[ $? -eq $_KS_CLI_FALSE ]] && { _ks_err_msg "No mode selected! Type 'ks mode help' for help"; return; }

  _ks_yesno "Do you want to launch bootstrap?[y/n] "
  [[ $? -eq $_KS_CLI_TRUE ]] && { _ks_info_msg "Launching Bootstrap"; } || { return $_KS_CLI_FALSE; }

  [[ -f $_KS_CLI_INVENTORY ]] || { _ks_err_msg "Inventory file not found. Abort."; return $_KS_CLI_FALSE; }

  case "$_KS_CLI_MODE_CURRENT" in
    dcos)
      _ks_info_msg "Launching DC/OS monitoring Bootstrap"
      KS_HOME=$KS_HOME bash ./dcos/bootstrap/bootstrap_dcos.sh
      if [[ $? -eq 0 ]]; then
        _ks_ok_msg "KS-CrateDB Bootstrap OK"
      else 
        _ks_err_msg "KS-CrateDB Bootstrap ERROR"
      fi


      _ks_info_msg "Running Ansible for Node configuration"

      _ansible_output="$(ansible-playbook -i $_KS_CLI_INVENTORY dcos/bootstrap/rsyslog/node_configuration/rsyslog_config.yml)"
      if [[ $? -eq 0 ]]; then
        _ks_ok_msg "DC/OS nodes configured!"
      else
        _ks_err_msg "DC/OS nodes configuration failed!"
        echo -e "$_ansible_output" > bootstrap_ansible.log
      fi
      ;;
    default)
      _ks_err_msg "Not Mode defined"
      ;;
   esac
}

# Run a command system for docker-compose management
function _ks_system_cmd () {
  docker-compose -f $_KS_CLI_MODE_DOCKERCOMPOSE_FILE $@
}

# Build and deploy the KS on docker
function _ks_system_up () {
  _ks_system_cmd up -d
  _ks_system_bootstrap
}

# Stop and remove the KS on docker
function _ks_system_down () {
  _ks_system_cmd down
}

# Destroy and build the KS on docker
function _ks_system_reboot () {
  _ks_system_down
  _ks_system_up
}

# Start the KS on docker
function _ks_system_start () {
  _ks_system_cmd start
}

# Stop the KS on docker
function _ks_system_stop () {
  _ks_system_cmd stop
}

# Restart the KS on docker
function _ks_system_restart () {
  _ks_system_cmd restart
}

# Print the logs of KS on docker
function _ks_system_logs () {
  _ks_system_cmd logs $@
}

# Print the current processes of KS in docker
function _ks_system_ps () {
  _ks_system_cmd ps
}

# Print the status of KS in docker
function _ks_system_status () {
  local status="$(_ks_system_ps)"
  local n_services=$(echo "$status" | grep -e "^$_KS_CLI_IMAGE_PREFIX" | wc -l | tr -d '[:space:]')
  local n_up_status=$(echo "$status" | grep -e "Up" | wc -l | tr -d '[:space:]')
  
  # No services running
  [[ $n_services -eq "0" ]] && { _ks_war_msg "KloudSense is \033[33mSTOPPED\033[0m"; return; }

  # Not all services are Up
  [[ $n_services -eq $n_up_status ]] && { _ks_ok_msg "KloudSense is \033[32mUP\033[0m"; } || {  _ks_err_msg "KloudSense is \033[31mERROR\033[0m"; }
}

# Print the current configuration for KS system
function _ks_system_config () {
  printf "KloudSense System current configuration\n
  \033[31mMode:\033[33m         $_KS_CLI_MODE_CURRENT
  \033[31mDeploy:\033[33m       $KS_CONFIG_DEPLOY
  \033[31mEnvironment:\033[33m  $KS_CONFIG_ENVIRONMENT
  \033[31mVersion:\033[33m      $_KS_CLI_VERSION
  \n"
}

# Help Message for System
function _ks_system_help () {
  printf "KloudSense CLI System Management:
  \n  Usage:   ks system <command> [options]\n
  System Commands:
    up                       Build and start all the containers for the selected profile
    down                     Stop and destroy all the container for the selected profile
    reboot                   Destroy and build in one step all the containers for the selected profile
    start                    Start all the containers for the selected profile
    bootstrap                Launch the Bootstrap process
    stop                     Stop all the containers for the selected profile
    restart                  Stop and Start all the containers for the selected profile
    logs                     Print by stdout the logs of all the containers for the selected profile
    status                   Print the status of all the containers for the selected profile
    config                   Print the current configuration for KS system
    help                     Print this message
\n"
}

# Menu System function
function _ks_system_menu () {
  local cmd=$1
  shift
  _ks_is_mode_selected
  [[ $? -eq $_KS_CLI_FALSE ]] && { _ks_err_msg "No mode selected! Type 'ks mode help' for help"; return; }
  case "$cmd" in
    up)
      _ks_system_up
      ;;
    down)
      _ks_system_down
      ;;
    reboot)
      _ks_system_reboot
      ;;
    start)
      _ks_system_start
      ;;
    bootstrap)
      _ks_system_bootstrap
      ;;
    stop)
      _ks_system_stop
      ;;
    restart)
      _ks_system_restart
      ;;
    logs)
      _ks_system_logs $@
      ;;
    ps)
      _ks_system_ps
      ;;
    status)
      _ks_system_status
      ;;
    config)
      _ks_system_config
      ;;
    help)
      _ks_system_help
      ;;
    *)
      _ks_err_msg "Unrecogniced System command"
      _ks_system_help
      ;;
  esac
}





#=============================
# Module Management
#===============================================================================

# Set a deploy mode ( dcos / none )
function _ks_mode_set () {
  local mode=$1
  _KS_CLI_MODE_CURRENT="$mode"
  case "$mode" in
    dcos)
      _KS_CLI_MODULES_FILE=$KS_MODULES_DCOS_FILE
      _KS_CLI_MODE_DOCKERCOMPOSE_FILE=$KS_DOCKERCOMPOSE_DCOS_FILE
      _KS_CLI_MODE_PROMPT_STR="\[\033[31m\][DC/OS]\[\033[0m\]"
      _KS_CLI_INVENTORY=$KS_DCOS_INVENTORY_FILE
      ;;
    none)
      _KS_CLI_MODULES_FILE=""
      _KS_CLI_MODE_DOCKERCOMPOSE_FILE=""
      _KS_CLI_MODE_PROMPT_STR="\[\033[31m\][NONE]\[\033[0m\]"
      _KS_CLI_INVENTORY=""
      ;;
  esac
  _ks_mode_print_current
}

# Check if a mode is selected
function _ks_is_mode_selected () {
  if [[ $_KS_CLI_MODE_CURRENT == "none" ]]; then
    return $_KS_CLI_FALSE
  else
    return $_KS_CLI_TRUE
  fi
}

# List all the available modes
function _ks_mode_list () {
  printf "KloudSense available modes:
  \n  Modes:\n
      DC/OS                  DC/OS Cluster Monitoring ( ks mode dcos )
      None                   Unset the mode configuration ( ks mode none )
\n"
}

# Print the current mode selected
function _ks_mode_print_current () {
  _ks_info_msg "Current mode: \033[31m$(echo $_KS_CLI_MODE_CURRENT | awk '{print toupper($0)}')\033[0m"
}

# Help Message for Mode
function _ks_mode_help () {
  printf "KloudSense CLI deploy Mode Management:
  \n  Usage:   ks system <command> [options]\n
  Mode Commands:
    dcos                     Set the deploy mode for DC/OS
    none                     Unset the deploy mode
    list                     List all the available modes
    current                  Print the current mode selected
    help                     Print this message
\n"
}

# Menu System function
function _ks_mode_menu () {
  local cmd=$1
  shift
  case "$cmd" in
    dcos)
      _ks_mode_set "dcos"
      ;;
    none)
      _ks_mode_set "none"
      ;;
    list)
      _ks_mode_list
      ;;
    current)
      _ks_mode_print_current
      ;;
    help)
      _ks_mode_help
      ;;
    *)
      _ks_err_msg "Unrecogniced Mode command"
      _ks_mode_help
      ;;
  esac
}





#=============================
# Module Management
#===============================================================================

# Aux function to get the url of the module
function _ks_get_module_url () {
  echo ${1%:*}
}

# Aux function to get the version of the module
function _ks_get_module_version () {
  echo ${1##*:}
}

# Aux function to get the name of the module
function _ks_get_module_name () {
  echo $1 | sed 's/git@github.com:kloudsense\///g;s/\.git:.*$//g'
}

# Aux function to check if a docker image exists locally
function _ks_check_if_image_exists () {
  if [[ "$(docker images -q $1 2> /dev/null)" == "" ]]; then
    return $_KS_CLI_FALSE
  else
    return $_KS_CLI_TRUE
  fi
}

# Aux function to return a string with the state of the module
function _ks_return_module_present_string () {
  [[ -z $1 ]] && { return $_KS_CLI_FALSE; }
  local retval=0
  _ks_check_if_image_exists keedio/$1
  retval=$?
  if [[ $retval -eq $_KS_CLI_TRUE ]]; then
    echo -e "\033[37m[\033[32mpresent\033[37m]\033[0m"
  else
    echo -e "\033[37m[\033[31mabsent\033[37m]\033[0m"
  fi
}

# Aux function to check if a module is pulled
function _ks_check_if_repo_is_pulled () {
  local repo_name=$1
  if [[ -d $KS_MODULES_DOWNLOAD_DIR ]]; then
    if [[ -d $KS_MODULES_DOWNLOAD_DIR$repo_name ]]; then
      return $_KS_CLI_TRUE
    else
      return $_KS_CLI_FALSE
    fi
  fi
}

# Aux function to return a string with the pull info of the module
function _ks_return_module_pulled_string () {
  [[ -z $1 ]] && { return $_KS_CLI_FALSE; }
  local retval=0
  _ks_check_if_repo_is_pulled $1
  retval=$?
  if [[ $retval -eq $_KS_CLI_TRUE ]]; then
    echo -e "\033[37m[\033[32mpulled\033[37m]\033[0m"
  else
    echo -e "\033[37m[\033[31mnot-pulled\033[37m]\033[0m"
  fi
}

# List modules
function _ks_module_list_modules () {
  while IFS= read -r line; do
    version="$(_ks_get_module_version $line)"
    name="$(_ks_get_module_name $line)"
    _ks_info_msg "\033[31mModule Name:\033[033m $name:$version\r\033[80C$(_ks_return_module_present_string $name:$version) $(_ks_return_module_pulled_string $name)"
  done < $_KS_CLI_MODULES_FILE
}

# Pull module
function _ks_module_pull_module () {
  [[ -z $1 ]] && { return $_KS_CLI_FALSE; }
  local repo_url=$1
  local repo_dir=$2
  local repo_name=$3
  _ks_check_if_repo_is_pulled $repo_name
  [[ $? -eq $_KS_CLI_FALSE ]] && { git clone $repo_url $repo_dir; }
  return $_KS_CLI_TRUE  
}

# Pull modules
function _ks_module_pull_modules () {
  while IFS= read -r line; do
    url="$(_ks_get_module_url $line)"
    name="$(_ks_get_module_name $line)"
    _ks_info_msg "\033[31mPulling Module:\033[033m $url"
    _ks_module_pull_module $url $KS_MODULES_DOWNLOAD_DIR$name $name
  done < $_KS_CLI_MODULES_FILE
}

# Clean pulled modules
function _ks_module_clean_modules () {
  # Remove repo downloads
  rm -Rf $KS_MODULES_DOWNLOAD_DIR

  # Remove local docker images
  _ks_info_msg "Cleanning KS Images..."
  docker images -a | grep "$_KS_CLI_IMAGE_PREFIX" | awk '{ print $3 }' | xargs docker rmi -f 1>/dev/null
  [[ $? -eq 0 ]] && { _ks_ok_msg "Cleanning KS Images Success"; } || { _ks_err_msg "Cleanning KS Images Error"; }

  _ks_ok_msg "Modules pulled cleaned"
}

# Build module
function _ks_module_build_module () {
  local name=$1
  local version=$2

  if [[ -d $KS_MODULES_DOWNLOAD_DIR/$name ]]; then
    cd $KS_MODULES_DOWNLOAD_DIR/$name
    local output="$(docker build -t keedio/$name:$version . 2>&1)"
    local retval=$?
    cd - &>/dev/null
    if [[ $retval -ne 0 ]]; then
      echo $output
      return $_KS_CLI_FALSE
    fi
  else
    _ks_err_msg "The module $name is not pulled. Try pulling the modules first"
  fi
  return $_KS_CLI_TRUE  
}

# Build modules
function _ks_module_build_modules () {
  while IFS= read -r line; do
    local name="$(_ks_get_module_name $line)"
    local version="$(_ks_get_module_version $line)"
    _ks_info_msg "\033[31mBuilding Module:\033[033m $name:$version"
    _ks_module_build_module $name $version
  done < $_KS_CLI_MODULES_FILE
}

# Help Message for Module module
function _ks_module_help () {
  printf "KloudSense CLI Module Management:
  \n  Usage:   ks module <command>\n
  Module Commands:
    list                     List and print the status of the KloudSense modules
    pull                     Pull the repositories of the defined modules defined in 'modules/modules.github' file
    clean                    Clean all the repositories of the modules pulled
    build                    Build the docker images of the modules
    help                     Print this message
\n"
}

# Menu Module function
function _ks_module_menu () {
  local cmd=$1
  shift
  _ks_is_mode_selected
  [[ $? -eq $_KS_CLI_FALSE ]] && { _ks_err_msg "No mode selected! Type 'ks mode help' for help"; return; }
  case "$cmd" in
    list)
      _ks_module_list_modules
      ;;
    pull)
      _ks_module_pull_modules
      ;;
    clean)
      _ks_module_clean_modules
      ;;
    build)
      _ks_module_build_modules
      ;;
    help)
      _ks_module_help
      ;;
    *)
      _ks_err_msg "Unrecogniced Module command"
      _ks_module_help
      ;;
  esac
}





#=============================
# Module Management
#===============================================================================

# Check the dependencies for KloudSense
function _ks_check_dependencies () {
  _ks_check_docker
  [[ $? -ne $_KS_CLI_TRUE ]] && { return $_KS_CLI_FALSE; }

  _ks_check_docker_compose
  [[ $? -ne $_KS_CLI_TRUE ]] && { return $_KS_CLI_FALSE; }

  _ks_check_ansible
  [[ $? -ne $_KS_CLI_TRUE ]] && { return $_KS_CLI_FALSE; }

  _ks_ok_msg "All dependencies are OK"
}

# Check if docker is installed
function _ks_check_docker () {
  which docker &>/dev/null
  [[ $? -ne 0 ]] && { _ks_err_msg "Docker is not installed"; return $_KS_CLI_FALSE; }
}

# Check if docker-compose is installed
function _ks_check_docker_compose () {
  which docker-compose &>/dev/null
  [[ $? -ne 0 ]] && { _ks_err_msg "Docker-Compose is not installed"; return $_KS_CLI_FALSE; }
}

# Check if docker-compose is installed
function _ks_check_ansible () {
  which ansible-playbook &>/dev/null
  [[ $? -ne 0 ]] && { _ks_err_msg "Ansible is not installed"; return $_KS_CLI_FALSE; }
}



#=============================
# Info methods
#===============================================================================

# Welcome msg
function _ks_welcome () {
  printf "\033[34m \n\
################################################################################\n\
Keedio's \033[36mKloudSense\033[34m command line interface:\n\
  Version: \033[36m$(_ks_print_version)\033[34m\n\
\n\
$(cat $KS_CLI_LOGO_PATH)
\n\
\033[37mTo get the help message type:  \033[1;33mks help\033[0;34m\n\
################################################################################\n\
\033[0m\n"
}

# Print Current Version
function _ks_print_version () {
  echo -e "\033[36mKloudSense:\033[37m $_KS_CLI_VERSION\033[0m\n"
}

# KS command usage function
function _ks_usage_msg () {
  printf "\n  $(_ks_print_version)"
  printf "\n  Usage:   ks <module> <command> [options]\n"
  printf "\n  Modules:
    system          Manage system actions
    mode            Manage deploys modes ( DCOS )
    module          Manage module actions
    version         Print Version information
    check           Check the dependencies for KloudSense
    help            Print this message
\n"
}

# Menu Master function
function _ks_top_menu () {
  local cmd=$1
  case "$cmd" in
    system)
      shift
      _ks_system_menu $@
      ;;
    mode)
      shift
      _ks_mode_menu $@
      ;;
    module)
      shift
      _ks_module_menu $@
      ;;
    version)
      shift
      _ks_print_version
      ;;
    check)
      shift
      _ks_check_dependencies
      ;;
    help)
      _ks_usage_msg
      ;;
    *)
      _ks_err_msg "Unrecogniced module"
      _ks_usage_msg
      ;;
  esac
}





#=============================
# Main
#===============================================================================
alias ks="_ks_top_menu $@"
source $KS_HOME/config/kloudsense.properties
_ks_welcome

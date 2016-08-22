#!/bin/bash

set -e

START_FILE="start_command"
YAML_FILE="yaml_file"

# StackOverflow driven development
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  app_release.out |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function build_command {
  echo -n "PORT=3000 " > "${START_FILE}"
  parse_yaml > "${YAML_FILE}"
  while read LINE; do
    if [[ $LINE == "config_vars_"* ]]; then
      echo $LINE \
      | sed s/^config_vars_// \
      | awk -F '=' '{printf "%s=%s ", $1, $2}' \
      >> "${START_FILE}"
    elif [[ $LINE == "default_process_types_web"* ]]; then
      echo $LINE \
      | sed s/^default_process_types_web\=// \
      >> "${START_FILE}"
    fi
  done < $YAML_FILE
  rm $YAML_FILE
  sed -i -e 's/$PORT/3000/g;s/"//g' ${START_FILE}
}

function deploy_app {
  if [ -e app_release.out ]; then
    build_command
    if [ -s ${START_FILE} ]; then
      echo -n "running start command "
      cat ${START_FILE}
      bash ${START_FILE}
    fi
  else
    exit 1
  fi
}

function deploy_hap {
  ./haproxy -f haproxy.cfg
}

deploy_app & deploy_hap

rm $START_FILE

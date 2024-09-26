#!/bin/bash

set -e

ENVV='prod'
template_file=start-deploy-build-$ENVV.json
S3_BUCKET="paigo-web-static"
PROJECT_NAME="paigo-kr-landing"
CF_ID_DISTRIBUTION="E2V48U1R3B6ZCG"


function deploy_version {
  echo "ARG: $1 + $2 + $3 "    
  sed -i -e 's/_DEPLOY_VERSION_/'"$2"'/' $template_file
  sed -i -e "s/_ID_DISTRIBUTION_/$3/" $template_file
  sed -i -e "s/_APP_NAME_/$1/" $template_file  
  aws codebuild start-build --cli-input-json file://$template_file > /dev/null 2>&1
  echo "Deploying $1 app with $2 Version... (The codeBuild projecto static-webs-deploy has been executed)"
  sed -i -e 's/'"$2"'/_DEPLOY_VERSION_/' $template_file
  sed -i -e "s/$3/_ID_DISTRIBUTION_/" $template_file
  sed -i -e "s/$1/_APP_NAME_/" $template_file
  
}

function get_image {  
  for my_array in $(aws s3 ls s3://$S3_BUCKET/$PROJECT_NAME/ --recursive | head -n 20 | awk '{print $4}' | sort -r | cut -d '/' -f 2); do buckets+=( "$my_array" ); done
  declare -a opt_image=()

  for i in "${!buckets[@]}"; do
  opt_image[i]="${buckets[$i]%% *}" # create an array of just names
  done            
  
  PS3='Seleccione la version y/o tag de la imagen a instalar: '
  select imagen in "${opt_image[@]}"; do    
    if [ -z "$imagen" ]
    then
      echo >&2 "opción no valida $REPLY"
    else
      echo "$imagen"
      [ -n "$imagen" ] \
      && { deploy_version "$PROJECT_NAME" "$imagen" "$CF_ID_DISTRIBUTION"; }      
      exit 0      
    fi                
  done
}

get_image
exit 0

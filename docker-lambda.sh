#!/bin/bash

# Wraper script for executing Lambda function via apex,
# from Docker's docker-lambda env.
#
# environment variable in `fanction.json` is read using jq, 
# and make env list file for `docker --input-file` option.

set -e

function usage() {
    cat <<EOF
Usage: $0 [-h] [-f FILE]
    -h    print this message.
    -f    input FILE containing input JSON.
EOF
    exit 1;
}

function create_env_file() {
    local env_json="function.json"

    jq -r '.environment | to_entries | map("\(.key)=\(.value)") | join("\n")' $env_json > .tmp.list
}

function remove_env_file() {
    rm .tmp.list
}

function docker_run() {
    local message=`cat $1`

    create_env_file

    docker run --rm \
           -e AWS_ACCESS_KEY_ID \
           -e AWS_SECRET_ACCESS_KEY \
           --env-file .tmp.list \
           -v $(pwd):/var/task lambci/lambda:python2.7 main.handle "$message"

    remove_env_file
}

while getopts "f:h" opt
do
    case $opt in
        f)
            docker_run $OPTARG
        ;;
        h) usage
           ;;
        \?) usage
            ;;
    esac
done

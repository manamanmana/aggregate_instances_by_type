#!/bin/bash

set -eu
set -o errtrace
set -o pipefail

# Error handling
onerror() {
    local status=$?
    local script=$0
    local line=$1
    shift

    args=
    for i in "$@"
    do
        args+="\"$i\" "
    done

    echo "" 1>&2
    echo "-----------------------------------------------------------------" 1>&2
    echo "Error occured on ${script} [Line ${line}]: Status: ${status}" 1>&2
    echo "" 1>&2
    echo "PID: $$" 1>&2
    echo "User: ${USER}" 1>&2
    echo "Current directory: ${PWD}" 1>&2
    echo "Command line: ${script} ${args}" 1>&2
    echo "-----------------------------------------------------------------" 1>&2
    echo "" 1>&2
}

# Show usage and exit on option handling
usage_exit() {
    echo "Usage: $0 [-m account|region]" 1>&2
    echo "Option: " 1>&2
    echo "  -m: aggregation mode [account|region] <required>" 1>&2
    echo "      account: aggregation output are shown by each AWS account" 1>&2
    echo "      region: aggregation output are shown by each AWS region" 1>&2
    exit 1
}

_describe_instances_with_profile_by_account() {
    while read -r profile
    do
        aws ec2 describe-regions --output text | cut -f 3 | \
        while read -r region
        do
            aws ec2 describe-instances \
            --query "Reservations[*].Instances[*].[InstanceType, Platform, Placement.Tenancy]" \
            --output=text \
            --profile "${profile}" \
            --region "${region}" | \
            while read -r instance_line
            do
                set -- $instance_line
                local instance_type=${1}
                local platform=${2}
                local tenancy=${3}
                echo "${region}:${instance_type}:${platform}:${tenancy}"
            done

            # Check NextToken
            local next_token=$(aws ec2 describe-instances --query "NextToken" --output=text --profile "${profile}" --region "${region}")
            while [[ $next_token != "None" ]]
            do
                aws ec2 describe-instances \
                --query "Reservations[*].Instances[*].[InstanceType, Platform, Placement.Tenancy]" \
                --output=text \
                --profile "${profile}"
                --region "${region}"
                --starting-token "${next_token}" | \
                while read -r instance_line
                do
                    set -- $instance_line
                    local instance_type=${1}
                    local platform=${2}
                    local tenancy=${3}
                    echo "${region}:${instance_type}:${platform}:${tenancy}"
                done

                local next_token=$(aws ec2 describe-instances --query "NextToken" --output=text --profile "${profile}" --region "${region}" --starting-token "${next_token}")
            done
        done
    done 
}

_parse_and_reorganize_line_for_account_aggregate() {
    while read -r aggregate_line
    do
        set -- $aggregate_line
        local count=${1}
        local rest_line=${2}
        IFS_ORG=$IFS
        IFS=":"
        set -- $rest_line
        IFS=$IFS_ORG
        local region=${1}
        local instance_type=${2}
        local platform=${3}
        local tenancy=${4}
        echo "${region},${instance_type},${platform},${tenancy},${count}"
    done
}

# Account mode aggregation
# Execution: echo "<profile according to the account>" | bash aggregate_instances_by_type.sh -m account
# Example execution: echo "default" | bash aggregate_instances_by_type.sh -m account
aggregate_by_account() {
    _describe_instances_with_profile_by_account | \
    sort                                        | \
    uniq -c                                     | \
    _parse_and_reorganize_line_for_account_aggregate
}

_divide_output_by_region() {
    local previous_region=""
    local -i line_count=0

    while read -r sammerized_line
    do
        local this_region=$(echo "${sammerized_line}" | cut -d "," -f 1)
        if [[ "${previous_region}" != "${this_region}" && $line_count > 0 ]]
        then
            echo ""
            echo "${sammerized_line}"
        else
            echo "${sammerized_line}"
        fi
        previous_region="$this_region"
        line_count=$((line_count + 1))
    done
}

# Region mode aggregation
# Execution: cat profile.list | bash aggregate_instances_by_type.sh -m region
# cat profile.list
# accountA
# accountB
# accountC
# ...
aggregate_by_region() {
    _describe_instances_with_profile_by_account      | \
    sort                                             | \
    uniq -c                                          | \
    _parse_and_reorganize_line_for_account_aggregate | \
    _divide_output_by_region
}

###################################
# Main Routine from here
###################################
declare aggregation_mode=""

# Setup Error handler
trap 'onerror $LINENO "$@"' ERR

# Option handking
while getopts m: OPT
do
    case $OPT in
        m)  aggregation_mode=$OPTARG; [[ $aggregation_mode != "account" && $aggregation_mode != "region" ]] && usage_exit
            ;;
        h)  usage_exit
            ;;
        \?) usage_exit
            ;;
    esac
done

shift $((OPTIND - 1 ))

# -m option is required
[[ $aggregation_mode = "" ]] && usage_exit

# Case account aggregation mode
if [[ $aggregation_mode = "account" ]]
then
    aggregate_by_account
    exit 0
fi

# Case region aggregation mode
if [[ $aggregation_mode = "region" ]]
then
    aggregate_by_region
    exit 0
fi


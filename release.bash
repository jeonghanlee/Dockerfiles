#!/usr/bin/env bash
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.3

declare -g SC_SCRIPT;
declare -g SC_TOP;

SC_SCRIPT="$(realpath "$0")";
SC_TOP="${SC_SCRIPT%/*}"

function pushd { builtin pushd "$@" > /dev/null || exit; }
function popd  { builtin popd  > /dev/null || exit; }

Debian10="debian10.yml"
Debian11="debian11.yml"
CentOS7="centos7.yml"
Rocky8="rocky8.yml"
Sl7="sl7.yml"
Alma8="alma8.yml"

ACTION_PATH="${SC_TOP}/.github/workflows";
DEB_FILE="${ACTION_PATH}/${Debian10}";
DEB11_FILE="${ACTION_PATH}/${Debian11}";
CEN_FILE="${ACTION_PATH}/${CentOS7}";
ROC_FILE="${ACTION_PATH}/${Rocky8}";
SL7_FILE="${ACTION_PATH}/${Sl7}";
ALMA_FILE="${ACTION_PATH}/${Alma8}";

function yes_or_no_to_go
{

    printf  "> \n";
    printf  "> Default latest tag will be used.\n"
    read -p ">> Do you want to continue (y/N)? " answer
    case ${answer:0:1} in
	y|Y )
	    printf ">> latest tag is going to be used...... ";
	    ;;
	* )
    printf  "> \n";
            printf ">> Please use the difference tag as an input.\n";
            printf ">> $SC_SCRIPT tag_name.\n";
	    exit;
    ;;
    esac

}

function replace_tag 
{
    local tag="$1"; shift;
    local file="$1"; shift;
    sed -i.bak -e "s| DOCKER_TAG:.*$| DOCKER_TAG: ${tag}|g" "${file}"
}


input_tag="$1";

if [ -z "$input_tag" ]; then
    input_tag="latest";
    yes_or_no_to_go;
fi

pushd "$SC_TOP" || exit
replace_tag "${input_tag}" "${DEB_FILE}"
replace_tag "${input_tag}" "${DEB11_FILE}"
replace_tag "${input_tag}" "${CEN_FILE}"
replace_tag "${input_tag}" "${ROC_FILE}"
replace_tag "${input_tag}" "${SL7_FILE}"
replace_tag "${input_tag}" "${ALMA_FILE}"
popd || exit

#git diff
exit


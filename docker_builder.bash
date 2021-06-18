#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.1

declare -g SC_SCRIPT;
declare -g SC_TOP;

SC_SCRIPT="$(realpath "$0")";
SC_TOP="${SC_SCRIPT%/*}"

function pushd { builtin pushd "$@" > /dev/null || exit; }
function popd  { builtin popd  > /dev/null || exit; }

declare -g TARGET_NAME=""
declare -g DOCKER_ID=""
declare -g BUILD_ARGS=""
declare -g DOCKER_BUILD_OPTS=""
declare -g DOCKER_FILENAME=""


options=":o:i:n:t:a:hd"
DRYRUN="NO"
#BUILDARG="NO"
docker_build_options=""
docker_file_path=""
docker_id=""
target_name=""
build_args=""

function usage
{
    {
	echo "";
	echo "Usage    : $0 ${options} "
	echo "";
	echo "              possbile options";
	echo "";
	echo "               -o : docker build options ${DOCKER_BUILD_OPTS}";
	echo "               -i : docker id  ${DOCKER_ID}";
	echo "               -n : target name ${TARGET_NAME}";
	echo "               -t : dockerpath Dockerfile"
	echo "               -a : array of build-arg translate from -a \"a=1 b=2 c=3\""
	echo "                    to \"--build-arg a=1 --build-arg b=2 --build-arg b=3\""
	echo "               -d : dry run";
	echo "               -h : this screen";
	echo "";
	echo " bash $0 -d "
	echo ""
    } 1>&2;
    exit 1;
}




while getopts "${options}" opt; do
    case "${opt}" in
    o)
        docker_build_options="${OPTARG}";
    ;;
    i)
        docker_id="${OPTARG}";
    ;;
    n)
        target_name="${OPTARG}";
    ;;
    t)
        docker_file_path="${OPTARG}";
    ;;
    a)
        build_args="${OPTARG}";
    ;;
    d)
        DRYRUN="YES";
    ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
    ;;
    h) usage
    ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        xit
    ;;
    *) usage
    ;;
    esac
done
#if [ $OPTIND -eq 1 ]; then  usage ; fi
shift $((OPTIND-1))


if [ -z "${docker_file_path}" ]; then
    usage;
else
    DOCKER_FILENAME=${docker_file_path}/Dockerfile;
fi

set -a
# shellcheck disable=SC1091
# shellcheck source=env.conf
. "$SC_TOP/${docker_file_path}/env.conf"
if [ -r "${SC_TOP}/${docker_file_path}"/env.local ]; then
    printf ">>> We've found the local configuration file.\\n";
    printf "    The original DOCKER_ID   = %s\\n" "${DOCKER_ID}"
    printf "                 TARGET_NAME = %s\\n" "${TARGET_NAME}"
    printf "                 BUILD_ARGS  = %s\\n" "${BUILD_ARGS}"
    printf "           DOCKER_BUILD_OPTS = %s\\n" "${DOCKER_BUILD_OPTS}"
    # shellcheck disable=SC1091
    # shellcheck source=docker_target_name.local
    . "$SC_TOP/target_name.local"
    printf "    will be overridden with \\n";
    printf "                 DOCKER_ID   = %s\\n" "${DOCKER_ID}"
    printf "                 TARGET_NAME = %s\\n" "${TARGET_NAME}"
    printf "                 BUILD_ARGS  = %s\\n" "${BUILD_ARGS}"
    printf "           DOCKER_BUILD_OPTS = %s\\n" "${DOCKER_BUILD_OPTS}"
fi
set +a

# BUILD OPTIONS
if [ -z "${docker_build_options}" ]; then
    printf ">>> We will use the predefined docker build options : %s\\n" "${DOCKER_BUILD_OPTS}"
else
    DOCKER_BUILD_OPTS="${docker_build_options}"
    printf ">>> We will use the input docker build options : %s\\n" "${DOCKER_BUILD_OPTS}"
fi

# ID
if [ -z "${docker_id}" ]; then
    printf ">>> We will use the predefined docker id : %s\\n" "${DOCKER_ID}"
else
    DOCKER_ID="${docker_id}"
    printf ">>> We will use the input docker id: %s\\n"  "${DOCKER_ID}"
fi

# Target Name
if [ -z "${target_name}" ]; then
    printf ">>> We will use the predefined target name: %s\\n" "${TARGET_NAME}"
else
    TARGET_NAME=${target_name};
    printf ">>> We will use the input target name: %s\\n" "${TARGET_NAME}"
fi

# Build Args
if [ -z "${build_args}" ]; then
    printf ">>> We will use the predefined build args : %s\\n" "${BUILD_ARGS}"
else
    BUILD_ARGS="${build_args}"
    printf ">>> We will use the input build args : %s\\n" "${BUILD_ARGS}"
fi


target_image="${DOCKER_ID}/${TARGET_NAME}"

docker_build_arg="";

if [ -z "${BUILD_ARGS}" ]; then
    docker_build_arg="";
else
    for arg in  "${BUILD_ARGS[@]}"; do
        docker_build_arg+="--build-arg";
	docker_build_arg+=" ";
	docker_build_arg+="\"${arg}\"";
	docker_build_arg+=" ";
    done
fi

command="docker build ${DOCKER_BUILD_OPTS} --file ${DOCKER_FILENAME} -t "${target_image}" "${docker_build_arg}" ."

SRC_TOP=${SC_TOP}


pushd "${SRC_TOP}" || exit
if [ "$DRYRUN" == "YES" ]; then
    echo "${command}"
else
    echo "${command}"
    eval "${command}"
fi
popd || exit

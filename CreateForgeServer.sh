#!/bin/bash

# Default values
AUTO_APPROVE=false
OUTPUT_DIR='OUTPUT'
RAM_MIN='1024'
RAM_MAX='4096'
LOG=true

# Help message
showHelp()
{
    echo ''
    echo 'Usage:'
    echo "  ${0} [-h / --help] [-o / --out-dir] NEW_SERVER"
    echo '  [-n / --ram-min] 1024 [-x / --ram-max] 4096'
    echo '  [-q / --quiet]'
    echo ''
    echo 'Options:'
    echo '  -h, --help'
    echo '    Display the help message of this script'
    echo '  -o, --out-dir'
    echo '    The name of the directory to output to'
    echo '  -n, --ram-min'
    echo '    Minimum amount of ram to be used with java'
    echo '  -x, --ram-max'
    echo '    Maximum amount of ram to be used with java'
    echo '  -a, --approve'
    echo '    Auto approve eula'
    echo ''
}

# Argument handling
while [ "${1}" != '' ]
do
    case ${1} in
    -h | --help )
        showHelp
        exit 0
    ;;
    -o | --out-dir )
        shift
        OUTPUT_DIR=${1}
    ;;
    -n | --ram-min )
        shift
        RAM_MIN=${1}
    ;;
    -x | --ram-max )
        shift
        RAM_MAX=${1}
    ;;
    -q | --quiet )
        LOG=false
    ;;
    -a | --approve )
        AUTO_APPROVE=true
    ;;
    * )
        echo Unknown option \"${1}\"
        exit 1
    esac
    shift
done

# Setup
URL_FORGE_INSTALLER='https://files.minecraftforge.net/maven/net/minecraftforge/forge/1.12-14.21.1.2387/forge-1.12-14.21.1.2387-installer.jar'
OLD_IFS=${IFS}
DIR="$(pwd)/${OUTPUT_DIR}"
if [ -d ${OUTPUT_DIR} ]
then
    echo '> Removing existing output directory'
    rm -r ${OUTPUT_DIR}
fi
mkdir ${OUTPUT_DIR}
cd ${OUTPUT_DIR}

# Get version numbers
IFS='-'
read -ra ARR <<< ${URL_FORGE_INSTALLER}
FORGE_MCVERSION="${ARR[-3]}"
FORGE_VERSION="${ARR[-2]}"
IFS=${OLD_IFS}
FORGE_INSTALLER_FILE="${DIR}/forge-${FORGE_MCVERSION}-${FORGE_VERSION}-installer.jar"
FORGE_UNIVERSAL_FILE="${DIR}/forge-${FORGE_MCVERSION}-${FORGE_VERSION}-universal.jar"

# Get Forge installer
echo '> Fetching Forge installer'
wget -q ${URL_FORGE_INSTALLER}
echo '> Unzipping Forge installer'
unzip -q ${FORGE_INSTALLER_FILE}
echo '> Running Forge installer'
if ${LOG}
then
    java -jar ${FORGE_INSTALLER_FILE} --installServer >> ../CreateForgeLog.txt
else
    java -jar ${FORGE_INSTALLER_FILE} --installServer > /dev/null 2>&1
fi
echo '> Forge installer complete'
rm ${FORGE_INSTALLER_FILE} ${FORGE_INSTALLER_FILE}.log forge-${FORGE_MCVERSION}-${FORGE_VERSION}-changelog.txt
echo '> Deleted installer and log'

# Pull and unzip modpack

# Initialize server
echo '> Initializing the server'
if ${LOG}
then
    java -Xms${RAM_MIN}M -Xmx${RAM_MAX}M -jar ${FORGE_UNIVERSAL_FILE} nogui >> ../CreateForgeLog.txt
else
    java -Xms${RAM_MIN}M -Xmx${RAM_MAX}M -jar ${FORGE_UNIVERSAL_FILE} nogui > /dev/null 2>&1
fi

# Handle eula
if ${AUTO_APPROVE}
then
    while true
    do
        read -p '> Approve eula: ' yn
        case ${yn} in
            [Yy]* )
                EULA=$(<eula.txt)
                echo "${EULA/"eula=false"/"eula=true"}" > eula.txt
                break
            ;;
            [Nn]* )
            echo '> Ending process...'
                exit 0;
            ;;
            * )
                echo '> Please enter "y" or "n"'
                continue
            ;;
        esac
    done
fi
echo '> Set eula to true'

# Create service file
# Start service

echo '> COMPLETE!!!'
# echo "\> You can find your server at ${OUTPUT_DIR} and your service file at ${place or another}"
exit 0

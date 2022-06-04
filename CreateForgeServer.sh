#!/bin/bash

# Default values
SKIP_MODPACK_DOWNLOAD=''
SKIP_SERVER_INITIALIZATION=''
URL_MODPACK=''
OUTPUT_DIR='OUTPUT'
AUTO_APPROVE=''
RAM_MIN='1024'
RAM_MAX='4096'
LOG='true'

# Help message
showHelp()
{
    echo ''
    echo 'Usage:'
    echo "  ${0} [-h / --help] [-o / --out-dir] NEW_SERVER"
    echo '  [-n / --ram-min] 1024 [-x / --ram-max] 4096'
    echo '  [-q / --quiet] [-a / --approve]'
    echo '  [-fv / --forge-version] [-mv / --minecraft-version]'
    echo '  [-mp / --modpack] [-sm / --skip-modpack-downoad]'
    echo '  [-si / --skip-initialization]'
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
    echo '  -fv, --forge-version'
    echo '    The version of Forge to download'
    echo '  -mv, --minecraft-version'
    echo '    The version of Minecraft to download'
    echo '  -m, --modpack'
    echo '    The URL to fetch the modpack at'
    echo '  -smd, --skip-modpack-download'
    echo '    Skip the download of the modpack, this is useful'
    echo '    for if the modpack is already local'
    echo '  -si, --skip-initialization'
    echo '    Skip the initialization of the modpack with forge'
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
        LOG=''
    ;;
    -a | --approve )
        AUTO_APPROVE='true'
    ;;
    -fv | --forge-version )
        shift
        FORGE_VERSION=${1}
    ;;
    -mv | --minecraft-version )
        shift
        MC_VERSION=${1}
    ;;
    -m | --modpack )
        shift
        URL_MODPACK=${1}
    ;;
    -smd | --skip-modpack-download )
        shift
        SKIP_MODPACK_DOWNLOAD='true'
    ;;
    -si | --skip-initialization )
        shift
        SKIP_SERVER_INITIALIZATION='true'
    ;;
    * )
        echo Unknown option \"${1}\"
        exit 1
    esac
    shift
done

# Validations
if [ !${MC_VERSION} ]
then
    echo 'Missing Minecraft version argument, stopping process'
    exit 1
elif [ !${FORGE_VERSION} ]
then
    echo 'Missing Forge version argument, stopping process'
    exit 1
elif [ ${URL_MODPACK} && ${SKIP_MODPACK_DOWNLOAD} ]
then
    echo 'Either a modpack URL has to be specified, or skipped with (-smd/--skip-modpack-download), stopping process'
    exit 1
fi

# Setup
URL_FORGE_INSTALLER="https://maven.minecraftforge.net/net/minecraftforge/forge/${MC_VERSION}-${FORGE_VERSION}/forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar"
DIR="$(pwd)/${OUTPUT_DIR}"
if [ -d ${OUTPUT_DIR} ]
then
    echo '> Removing existing output directory'
    rm -r ${OUTPUT_DIR}
fi
mkdir ${OUTPUT_DIR}
cd ${OUTPUT_DIR}

# Get version numbers
FORGE_INSTALLER_FILE="${DIR}/forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar"
FORGE_UNIVERSAL_FILE="${DIR}/forge-${MC_VERSION}-${FORGE_VERSION}-universal.jar"

# Get Forge installer
echo "> Fetching Forge installer - ${URL_FORGE_INSTALLER}"
wget -q ${URL_FORGE_INSTALLER}
echo '> Unzipping Forge installer'
unzip -q ${FORGE_INSTALLER_FILE}
echo '> Running Forge installer'
if [ ${LOG} ]
then
    java -jar ${FORGE_INSTALLER_FILE} --installServer >> ../CreateForgeLog.txt
else
    java -jar ${FORGE_INSTALLER_FILE} --installServer > /dev/null 2>&1
fi
echo '> Forge installer complete'
rm ${FORGE_INSTALLER_FILE} ${FORGE_INSTALLER_FILE}.log forge-${FORGE_MCVERSION}-${FORGE_VERSION}-changelog.txt
echo '> Deleted installer and log'

# Pull and unzip modpack
if [ !${SKIP_MODPACK_DOWNLOAD} ]
then
    MODPACK_ZIP='modpack.zip'
    echo '> Fetching modpack'
    wget -q -O ${MODPACK_ZIP} ${URL_MODPACK} # look at --progress=TYPE for progress
    echo '> Unzipping modpack'
    unzip -q -d tmp ${MODPACK_ZIP}
    cp -a tmp/. ./
    rm -r tmp ${MODPACK_ZIP}
fi

# Initialize server
if [ !${SKIP_SERVER_INITIALIZATION} ]
then
    echo '> Initializing the server'
    if [ ${LOG} ]
    then
        java -Xms${RAM_MIN}M -Xmx${RAM_MAX}M -jar ${FORGE_UNIVERSAL_FILE} nogui >> ../CreateForgeLog.txt
    else
        java -Xms${RAM_MIN}M -Xmx${RAM_MAX}M -jar ${FORGE_UNIVERSAL_FILE} nogui > /dev/null 2>&1
    fi
fi

# Handle eula
if [ ! ${AUTO_APPROVE} ]
then
    while true
    do
        read -p '> Approve eula: ' yn
        case ${yn} in
            [Yy]* )
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
EULA=$(<eula.txt)
echo "${EULA/'eula=false'/'eula=true'}" > eula.txt
echo '> Set eula to true'

# Create service file
# Start service

echo '> COMPLETE!!!'
# echo "\> You can find your server at ${OUTPUT_DIR} and your service file at ${place or another}"
exit 0

TMP_RESULT_FILE=/tmp/leovimdiffsrc
MYTOOLS=
PROJECT_LIST=${MYTOOLS}/myProjectList
SRC_FILE=
Project0=
Project1=
DEBUG=

#function funcNumber2String() {
#    if [[ $1 =~ ^-?[0-9]+$ ]]
#        then
#        str=` sed -n "$1,$1p" $PROJECT_LIST`
#        return $str
#    fi
#    return $1
#}

function funcEchoError() {
echo -e "\e[1;31m $1 \e[0m"
}

function funcUsage() {
echo "Usage diff2ProjectFiles.sh filename project1 project2"
}

##############
# main
##############
#echo $*
SRC_FILE=$1
Project0=$2
Project1=$3
DEBUG=$4

if test $# -lt 3
    then
        funcUsage
        echo ""
        exit 1
fi

if [[ ${Project0} =~ ^-?[0-9]+$ ]]
    then
    Project0=` sed -n "${Project0},${Project0}p" $PROJECT_LIST`
fi

if [[ ${Project1} =~ ^-?[0-9]+$ ]]
    then
    Project1=` sed -n "${Project1},${Project1}p" $PROJECT_LIST`
fi

echo '************** Find 1 ***************'
${MYTOOLS}/foundFileInProjects.sh ${SRC_FILE} ${Project0} 0
echo ""
echo '************** Find 2 ***************'
${MYTOOLS}/foundFileInProjects.sh ${SRC_FILE} ${Project1} 1

echo ""

ret=`wc $TMP_RESULT_FILE | awk '{ print $1 }'`
if  test $ret -ne 2 
    then
    funcEchoError "/tmp/leovimdiffsrc is not right"
    wc $TMP_RESULT_FILE
    exit 1
fi

file0=`sed -n "1,1p" $TMP_RESULT_FILE`
file1=`sed -n "2,2p" $TMP_RESULT_FILE`

r0=`md5sum $file0`
r1=`md5sum $file1`

if [[ $r0 = $r1 ]]
    then 
        echo "file is same!"
        echo $r0
        echo $r1
        exit 0
fi

if test $DEBUG
    then
        echo "vimdiff"
        exit 0
fi

vimdiff $file0 $file1

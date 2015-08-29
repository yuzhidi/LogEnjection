#!/bin/bash

MyFilePath=
MyProjectList=
TMP_RESULT_FILE=/tmp/leovimdiffsrc
DST_PATH=
INPUT_FILE=
startline=
endline=
FOUND_FILE=
#####
function funcEchoError() {
echo -e "\e[1;31m $1 \e[0m"
}
#####
function funcCheckSuffix() {
    funcFindSubstring $INPUT_FILE .java
    if test $? -eq 0
    then return 0
    fi

    INPUT_FILE=${INPUT_FILE}.java
    echo "update input to $INPUT_FILE"
    return 0
}
#####
# find substring
# $1 src string
# $2 sub string
# ret 0 success ; 1 fail
#####
function funcFindSubstring() {
if [[ $1 ==  *"${2}"* ]]
then
    return 0
fi
return 1
}
#####
# check in a ASOP project
# ret 0 success ; 1 fail
#####
function funcCheckInProject() {
local count=0
local dstpath=
for i in `cat ${MyProjectList}`
do
    #echo $i
    #echo $DST_PATH
    funcFindSubstring $i $DST_PATH 
    ret=$?
    #echo $ret

    # check multi project
    if test $ret -eq 0
    then
    echo "find project: $i"
    count=$[ $count + 1 ]
        if test $count -gt 1
        then
            funcEchoError "Multi Project conflict"
            return 1
        fi
        dstpath=~/${i}
        #echo $DST_PATH
    fi

done

    # go to codebase top
    if test $count -eq 1
    then
        DST_PATH=$dstpath
        cd $dstpath
        return 0
    fi

return 1
}
#########
# find file path
#########
function funcFindFilePath() {
    startline=`grep -n ${INPUT_FILE}.*start ${MyFilePath} | awk -F : '{print $1}'` 
    endline=`grep -n ${INPUT_FILE}.*end ${MyFilePath} | awk -F : '{print $1}'`

    #echo $startline
    #echo $endline

    if test -z startline
    then
    funcEchoError "startline not found"
    return 1
    fi

    if test -z endline
    then
    funcEchoError "endline not found"
    return 1
    fi

    if test $startline -ge $endline
    then
    funcEchoError "start line $startline is greater than endline $endline"
    return 1
    fi
return 0
}

#########
# find file
#########
function funcFindFlie() {
startline=$[ $startline + 1  ]
endline=$[ $endline - 1  ]
for i in `sed -n "$startline, ${endline}p" ${MyFilePath}`
    do
        #echo $i
        file ${i}/$INPUT_FILE
        if test $? -eq 0
            then
                FOUND_FILE=${i}/$INPUT_FILE
                return 0
            else
                echo ""
                echo ""
        fi
done

funcEchoError "could not find $INPUT_FILE"
return 1
}
#########
# main
#########
INPUT_FILE=$1
DST_PATH=$2
LINE_NUM=$3

funcCheckSuffix

funcCheckInProject

if test $? -ne 0
    then
        funcEchoError "not in any project!"
        exit 1 
fi

funcFindFilePath


if test $? -ne 0
    then
        exit 1 
fi

funcFindFlie

if test $? -ne 0
    then
        exit 1
fi

file $DST_PATH/$FOUND_FILE


if test $? -ne 0
    then
        funcEchoError "finally not found!"
        exit 1
fi

touch $TMP_RESULT_FILE
ret=`wc $TMP_RESULT_FILE -l | awk '{print $1}'`
if test $ret -eq $LINE_NUM
    then
        echo $DST_PATH/$FOUND_FILE >> $TMP_RESULT_FILE
    else
        echo $DST_PATH/$FOUND_FILE > $TMP_RESULT_FILE
fi

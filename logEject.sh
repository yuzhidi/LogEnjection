#!/bin/bash

DEBUG= # open echo
FILE_NAME=
LINE_NUM=
COND=
FOUND_COUNT=
TMP_BASE_NAME=
BASE_FILE_NAME=
LINE_ADDR=
FOUND_BRACE=
BraceExitLine=
LOG_SRC=
#########################
#1.find the insert line
#2.sed insert
#########################
function funcFindBrace() {
    #echo "funcFindBrace ENTER"
    # asume max 4 line.
    local i=0
    BraceExitLine=${LINE_ADDR}
    grep -n "$COND" ${TMP_BASE_NAME} | tee /tmp/tmpGrepCond
    #echo $tmpStr
    for((;i<=3;i++))
    do
        FOUND_BRACE=`grep "{" /tmp/tmpGrepCond | awk '{print $1}'`
        echo "FOUND_BRACE:" ${FOUND_BRACE}
        if test ${FOUND_BRACE}
            then
                echo "funcFindBrace"
                i=4 #return
            else
                BraceExitLine=$((${BraceExitLine}+1))
		# sed -n
                sed -n "${BraceExitLine}, ${BraceExitLine} p" ${TMP_BASE_NAME} >> /tmp/tmpGrepCond
                cat /tmp/tmpGrepCond
        fi
    done


    if test $FOUND_BRACE
        then
            echo ""
        else
            echo "not found brace, return"
            return
    fi
    #################################################
    # check super
    sed -n "$((${BraceExitLine}+1)), $((${BraceExitLine}+1)) p" ${TMP_BASE_NAME} > /tmp/tmpSuper
    local FOUND_SUPER=`grep "super" /tmp/tmpSuper`
    if test ${FOUND_SUPER}
        then
                BraceExitLine=$((${BraceExitLine}+1))
    fi
    ##################################################
    # eject
    echo "eject"

    # sed 's/ x / x /g'
    sed 's/\s/ /g' /tmp/tmpGrepCond |  sed 's/^[[:space:]]*//g' > /tmp/tmpGrepCond_tmp

    echo "**************************************************"
    # cat | tr
    LOG_SRC=` cat /tmp/tmpGrepCond_tmp | tr "\n" " " ; echo `
    echo ${LOG_SRC}

    # sed -e script, --expression=script
    sed -e "${BraceExitLine} a\ Log.d(TAG,\"leoAutoLog_${LOG_SRC} ENTER\");" ${TMP_BASE_NAME} > /tmp/source_temp.java
    mv /tmp/source_temp.java ${TMP_BASE_NAME}
    #sleep 10 #debug
    echo "#################################################"
}

function funcEjectFunctionEnterLog() {
    LINE_ADDR=
    FOUND_BRACE=

    # awk -F:
    LINE_ADDR=`grep -n "$COND" ${TMP_BASE_NAME} | awk -F: '{print $1}'`
    echo ${LINE_ADDR}
    #call funcFindBrace
    funcFindBrace
}

#echo $*
echo $1
FILE_NAME=$1
if test ${FILE_NAME}
    then
        echo ${FILE_NAME}
    else
        echo "file (only java)":
        read FILE_NAME
fi
#FILE_NAME=`ls -l ${FILE_NAME} | awk '{print $9}'`
#echo ${FILE_NAME}

file ${FILE_NAME}

if test $? -eq 1
    then
        echo "this file not exit!"
        exit 1
fi

BASE_FILE_NAME=`basename ${FILE_NAME}`
echo "base name:${BASE_FILE_NAME}"
TMP_BASE_NAME="/tmp/${BASE_FILE_NAME}"

# create tmp source file
cp ${FILE_NAME} ${TMP_DIR_BASE_NAME}

echo "" > ${TMP_DIR_BASE_NAME}_unmatch

# ctags --language-force=java -f
echo "ctags --language-force=java -f '${TMP_DIR_BASE_NAME}_tags' ${TMP_DIR_BASE_NAME}"
ctags --language-force=java -f "/tmp/${TMP_DIR_BASE_NAME}_tags" ${TMP_DIR_BASE_NAME}

# grep '	m	'
echo "grep '	m	' /tmp/${TMP_DIR_BASE_NAME}_tags > /tmp/TMP_BASE_NAME_method_tags"
grep '	m	' /tmp/${TMP_DIR_BASE_NAME}_tags > TMP_BASE_NAME_method_tags

# grep -o , --only-matching
# awk -F ' XX ' '{print $X}'
echo 'grep -o "/\\^.*\\$" TMP_BASE_NAME_method_tags | awk -F '/\\^' '{print $2}' | awk -F '\\$' '{print $1}' >  /tmp/TMP_BASE_NAME_method_def_line_tags'
grep -o "/\\^.*\\$" TMP_BASE_NAME_method_tags | awk -F '/\\^' '{print $2}' | awk -F '\\$' '{print $1}' >  /tmp/TMP_BASE_NAME_method_def_line_tags

# wc
wc /tmp/TMP_BASE_NAME_method_def_line_tags
LINE_NUM=`wc -l /tmp/TMP_BASE_NAME_method_def_line_tags | awk '{print $1}'`
echo ${LINE_NUM}

# sed -n "${i}, ${i} p"
for((i=1;i<=${LINE_NUM};i++))
do
    #grep "`sed -n "${i}, ${i} p" /tmp/TMP_BASE_NAME_method_def_line_tags`" ${TMP_BASE_NAME} | wc -l >> /tmp/ttt1
    COND=`sed -n "${i}, ${i} p" /tmp/TMP_BASE_NAME_method_def_line_tags`
    FOUND_COUNT=`grep "$COND" ${TMP_BASE_NAME} | wc -l`
    if test $? -eq 1
        then
            echo ${COND}
    elif test ${FOUND_COUNT} -ne 1
        then
            echo ${FOUND_COUNT} "   " ${COND}
    else
        # call function
        funcEjectFunctionEnterLog
    fi
done


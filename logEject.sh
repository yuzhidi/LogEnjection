#!/bin/bash

#############################
# Leo Tools
#############################

DEBUG= # open echo
FILE_NAME=
LINE_NUM=
COND=
FOUND_COUNT=
TMP_DIR_BASE_NAME=
BASE_FILE_NAME=
LINE_ADDR=
FOUND_BRACE=
BraceExitLine=
LOG_SRC=

#########################
#change paramters a b  > a"+a+"b"+b
function funcParametesExpend() {
echo "funcParametesExpend ENTER"
}

#########################
# call function handle paramters has [
function funcHandleSquareBrackets() {
echo $COND > /tmp/tmpHandleParametesSquareBrackets
sed 's/\[/\\[/g' /tmp/tmpHandleParametesSquareBrackets > /tmp/tmpHandleParametesSquareBracketsTmp
COND=`cat /tmp/tmpHandleParametesSquareBracketsTmp`
echo "funcHandleSquareBrackets : $COND"
}

#########################
#1.find the insert line
#2.sed insert
#########################
function funcFindBrace() {
    #echo "funcFindBrace ENTER"
    # asume max 4 line.
    local i=0
    BraceExitLine=${LINE_ADDR}
    grep -n "$COND" ${TMP_DIR_BASE_NAME} | tee /tmp/tmpGrepCond
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
                sed -n "${BraceExitLine}, ${BraceExitLine} p" ${TMP_DIR_BASE_NAME} >> /tmp/tmpGrepCond
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
    sed -n "$((${BraceExitLine}+1)), $((${BraceExitLine}+1)) p" ${TMP_DIR_BASE_NAME} > /tmp/tmpSuper
    local FOUND_SUPER=`grep "super" /tmp/tmpSuper|wc -l`
    if test ${FOUND_SUPER} -ne 0
        then
                BraceExitLine=$((${BraceExitLine}+1))
    fi
    #################################################
    # check constructor nested

    ##################################################
    # eject
    #echo "eject"

    sed 's/\s/ /g' /tmp/tmpGrepCond |  sed 's/^[[:space:]]*//g' > /tmp/tmpGrepCond_tmp

    echo "**************************************************"
    LOG_SRC=` cat /tmp/tmpGrepCond_tmp | tr '\n{' " " ; echo`
    echo ${LOG_SRC} | tee /tmp/logSrcTmpleo
    LOG_SRC=`sed 's/ \([a-zA-Z0-9_\-]*\) *\([,)]\)/ \1 :\" + \1 + \"\2/g' /tmp/logSrcTmpleo`
    echo $LOG_SRC
    ##################################################
    # call function funcparametesexpend
    funcParametesExpend
    ##################################################

    sed -e "${BraceExitLine} a\ Log.d(TAG,\"leoLog ${LOG_SRC}\");" ${TMP_DIR_BASE_NAME} > /tmp/source_temp.java
    mv /tmp/source_temp.java ${TMP_DIR_BASE_NAME}
    #sleep 10 #debug
    echo "#################################################"
}

function funcEjectFunctionEnterLog() {
    LINE_ADDR=
    FOUND_BRACE=

    LINE_ADDR=`grep -n "$COND" ${TMP_DIR_BASE_NAME} | awk -F: '{print $1}'`
    echo ${LINE_ADDR}
    #call funcFindBrace
    funcFindBrace
}

##############################################################################
#
#  main
#
###########################################################

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
TMP_DIR_BASE_NAME="/tmp/${BASE_FILE_NAME}"

############################
# create tmp source file
cp ${FILE_NAME} ${TMP_DIR_BASE_NAME}

echo "" > ${TMP_DIR_BASE_NAME}_unmatch
#########################
# ctags
echo "ctags --language-force=java -f '${TMP_DIR_BASE_NAME}_tags' ${TMP_DIR_BASE_NAME}"
ctags --language-force=java -f "${TMP_DIR_BASE_NAME}_tags" ${TMP_DIR_BASE_NAME}

#######################
# only methods
echo "grep '	m	' ${TMP_DIR_BASE_NAME}_tags > TMP_DIR_BASE_NAME_method_tags"
grep '	m	' ${TMP_DIR_BASE_NAME}_tags > TMP_DIR_BASE_NAME_method_tags

# print cmd
echo 'grep -o "/\\^.*\\$" TMP_DIR_BASE_NAME_method_tags | awk -F '/\\^' '{print $2}' | awk -F '\\$' '{print $1}' >  ${TMP_DIR_BASE_NAME}_method_def_line_tags'
grep -o "/\\^.*\\$" TMP_DIR_BASE_NAME_method_tags | awk -F '/\\^' '{print $2}' | awk -F '\\$' '{print $1}' >  ${TMP_DIR_BASE_NAME}_method_def_line_tags

wc ${TMP_DIR_BASE_NAME}_method_def_line_tags
LINE_NUM=`wc -l ${TMP_DIR_BASE_NAME}_method_def_line_tags | awk '{print $1}'`
echo ${LINE_NUM}


for((i=1;i<=${LINE_NUM};i++))
do
    #
    # only handle only match once
    #
    COND=`sed -n "${i}, ${i} p" ${TMP_DIR_BASE_NAME}_method_def_line_tags`
    echo $COND

    # call function funcHandlesquarebrackets
    funcHandleSquareBrackets

    FOUND_COUNT=`grep "$COND" ${TMP_DIR_BASE_NAME} | wc -l`

    # grep fail
    if test $? -eq 1
        then
            echo ${COND}
            echo "fail ${COND}" >> ${TMP_DIR_BASE_NAME}_unmatch
    # not match once
    elif test ${FOUND_COUNT} -ne 1
        then
            echo ${FOUND_COUNT} "   " ${COND}
            echo "${FOUND_COUNT} ${COND}" >> ${TMP_DIR_BASE_NAME}_unmatch
    else
        # call function
        funcEjectFunctionEnterLog
    fi
done

echo "*************** unmatch number*********************"
cat ${TMP_DIR_BASE_NAME}_unmatch
echo ""
echo "**************unmatch elements***************************"
awk -F "(" '{print $1}' ${TMP_DIR_BASE_NAME}_unmatch | awk '{print $NF}' | sort |uniq
echo ""

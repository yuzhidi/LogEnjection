#!/bin/bash
MR=
L1=
A5=

md5sum $1
md5sum ${MR}/$1

value0=`md5sum $1 |awk '{print $1}'`
#echo $value0

value1=`md5sum ${MR}/$1 |awk '{print $1}'`
#echo $value1

if [ $value1 = $value0 ]
then
    echo "same!!!!"
fi

md5sum ${A5}/$1
md5sum ${L1}/$1

value0=`md5sum ${A5}/$1 |awk '{print $1}'`
#echo $value0

value1=`md5sum ${L1}/$1 |awk '{print $1}'`
#echo $value1

if [ $value1 = $value0 ]
then
    echo "same!!!!"
fi

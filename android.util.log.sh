PackageLine=-1
File=
TMPFILE=/tmp/android.util.Log.tmp
function funcFindPackage() {
    egrep -n "package .*;" $File | tee $TMPFILE

    # check if muti package line

    n=`wc -l $TMPFILE | gawk '{print $1}'`
    echo "wc ret: $n"
    if [ $n -ne 1 ] ;
        then
            echo "more than 1 packages"
            exit 1
    fi

    PackageLine=`gawk -F : '{print $1}' $TMPFILE`
}

function funcInsert() {
    funcFindPackage
    echo "PackageLine : ${PackageLine} "
    echo "------------------------------------------------------------------"
    gsed -e "${PackageLine} a\import android.util.Log;" $File > /tmp/android.util.Log.tmp.result
    cp /tmp/android.util.Log.tmp.result $File
}

# main
File=$1
echo grep 'import android.util.Log;' $File

grep "import android.util.Log;" $File
if [ $? -ne 0 ] ;
    then funcInsert;
    else echo "this file have import android.util.Log;"
fi

echo "  ---- sh exit ----"
exit 0


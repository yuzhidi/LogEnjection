workdir=`pwd`
cd $workdir

find . -name \*.java > /tmp/tmp_java_files

# for loop example
for i in `cat /tmp/tmp_java_files`; do
   echo $i

   /Users/wangliang/Tools/LogEnjection/logeject.sh $i

   cp /tmp/`basename $i` $i
done






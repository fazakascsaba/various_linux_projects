#!/bin/bash

# /home/weblogic/pack-files.sh "/weblogic_appdata/paymentsense/outgoing/reports" "SVXP_A_\S+\.xml$" "svxp_a_All_XML"


# track progress:
# pid=`ps -eaf | grep pack-files.sh | grep -v grep | awk '{print $2}'`
# cat Statement_All.txt -n | grep `ps -eaf | grep $pid | egrep "\S+xml$" | awk '{print $12}'`

files_are_being_written(){
    first=`ls -l | egrep -E "$1" | wc -l`
    sleep 30s
    second=`ls -l | egrep -E "$1" | wc -l`
    if [ $first = $second ]
    then
        return 1
    else
        return 0
    fi
}
last_file_is_being_written(){
    size1=`du $1 -b | cut -f 1`
    sleep 30s
    size2=`du $1 -b | cut -f 1`
    if [ $size1 = $size2 ]
    then
        return 1
    else
        return 0
    fi
}

echo `date +'%x %X'` INFO "Validating input arguments..."
if [ -z "$1" ]
    then
    echo `date +'%x %X'` WARNING You must provide 1st argument! Work directory.
    exit
fi
if [ -z "$2" ]
    then
    echo `date +'%x %X'` WARNING You must provide 1st argument! egrep -E pattern for file matching.
    exit
fi
if [ -z "$3" ]
    then
    echo `date +'%x %X'` WARNING You must provide 2nd argument! Prefix of tar file.
    exit
fi

work_directory="$1"
pattern=$2"\S+"$3"$"
file_prefix=$4
file_list=$file_prefix".txt"
target_directory="$work_directory/$file_prefix"


# zip multithreading part
number_of_cpu=`lscpu | egrep "^CPU\(s\)\S+" | awk '{print $2}'`
threads_per_core=`lscpu | egrep "^Thread\(s\) per core\S+" | awk '{print $4}'`
number_of_threads=`expr $number_of_cpu \* $threads_per_core`

cd "$work_directory"
echo `date +'%x %X'` INFO "Process started. Pattern: $pattern in" `pwd`"."


# make sure necessary files/directories exist
if [ -f "$file_list" ]
then
    rm "$file_list"
fi

if [ ! -d "$target_directory" ]
then
  mkdir -p "$target_directory"
  chown weblogic:weblogic $target_directory
fi


echo `date +'%x %X'` "INFO Required directories have been created."

# do not execute on empty set
initial_number_of_files=`ls -l | egrep -E "$pattern" | wc -l`
if [ $initial_number_of_files -eq "0" ]
then
    echo `date +'%x %X'` WARNING "No files are matching your pattern."
    exit 0
fi



#delay process when files are still delivered
while files_are_being_written $pattern
do
    echo `date +'%x %X'` INFO "Files are still being created."
done
echo `date +'%x %X'` "INFO Number of files -" `ls -l | egrep -E "$pattern" | wc -l` "- did not change in the last 30 seconds."


latest_file=(`ls -Art | egrep -E "$pattern" | tail -n 1`)
while last_file_is_being_written $latest_file
do
    echo `date +'%x %X'` INFO "Last file is being written."
done
echo `date +'%x %X'` INFO Size of $latest_file did not change in the last 30 seconds.


timestamp=`date +'%d%m%Y%H%M'`
echo `date +'%x %X'` INFO "Packing files..."

ls -l | egrep -E "$pattern" | awk '{print $9}' > "$file_list"
# tar version
ofile=$file_prefix"_"$timestamp".tar.gz"
tar -cz -T "$file_list" -f $ofile --remove-files

if [ `whoami` = "root" ]
then
    chown weblogic:weblogic $ofile
else
    echo `date +'%x %X'` ERROR "Changing permissions to weblogic:weblogic failed. Must be root."
    exit 1
fi

mv $ofile $target_directory

#zip_files(){
#    from=`expr \( $1 - 1 \) \* $2 + 1`
#    if [ $1 -eq $number_of_threads ]
#        then
#            to=$number_of_files
#        else
#            to=`expr $1 \* $2`
#    fi
#    ofiletmp=$file_prefix"_"$timestamp"_"$1".zip.tmp"
#    ofile=$file_prefix"_"$timestamp"_"$1".zip"
#    for file in `cat $file_list | sed -n "$from,$to p"`
#    do
#        zip -4 -rmq $ofiletmp $file
#    done
#    mv $ofiletmp $ofile
#    echo `date +'%x %X'` "INFO $ofile created."
#}
#
#
#number_of_files=`cat $file_list | wc -l`
#zip_size=`expr $number_of_files / $number_of_threads`
#limit=`expr $number_of_threads - 1`
#
## spawn threads
#for i in $(seq 1 $limit)
#do
#    zip_files $i $zip_size &
#done
#
#zip_files $number_of_threads $zip_size


echo `date +'%x %X'` INFO "Program finished."

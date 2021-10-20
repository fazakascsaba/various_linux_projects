#!/bin/bash

# ./pack-files.sh "/weblogic_appdata/paymentsense/outgoing/statements/zip" "Statement_79\S+xml$" "Statement_All"
# ./pack-files.sh "/weblogic_appdata/paymentsense/outgoing/statements/zip" "Invoice_\S+xml$" "Invoice_xml_All"
# ./pack-files.sh "/weblogic_appdata/paymentsense/outgoing/statements/zip" "Invoice_\S+pdf$" "Invoice_pdf_All"
# ./pack-files.sh "/weblogic_appdata/paymentsense/outgoing/statements/zip" "Cover_note_\S+xml$" "Cover_note_xml_All"
# ./pack-files.sh "/weblogic_appdata/paymentsense/outgoing/statements/zip" "Cover_note_\S+pdf$" "Cover_note_pdf_All"

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
pattern="$2"
file_prefix=$3
file_list=$file_prefix".txt"

cd "$work_directory"
echo `date +'%x %X'` INFO "Process started. Pattern: $pattern in" `pwd`"."


# make sure necessary files/directories exist
if [ -f "$file_list" ]
then
    rm "$file_list"
fi

if [ ! -d "zip" ]; then
  mkdir "zip"
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


timestamp=`date +'%d%m%Y'`
echo `date +'%x %X'` INFO "Packing files..."

ls -l | egrep -E "$pattern" | awk '{print $9}' > "$file_list"
# tar version
# ofile=$file_prefix"_"$timestamp"0000.tar.gz"
# tar -c -T "$file_list" -f $ofile --remove-files

# zip version
ofiletmp=$file_prefix"_"$timestamp"0000.zip.tmp"
ofile=$file_prefix"_"$timestamp"0000.zip"
for file in `cat $file_list`
do
    zip -4 -rmq $ofiletmp $file
done

mv $ofiletmp $ofile

echo `date +'%x %X'` "INFO $ofile created."
echo `date +'%x %X'` INFO "Program finished."

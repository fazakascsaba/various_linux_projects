#!/bin/bash
##################################################################################
# takes GNS*7002 files from <source folder>
# checks if file was previously sent in uploaded_files.txt
# if it was it moves the files to duplicate_attempts folder
#       wasn't it sends the file and registers the file name in uploaded_files.txt
###################################################################################
DATE="/bin/date"
DIR="<source folder>"
PATTERN="GNS\S+7002$"
KEY="<path/rsa key>"
DEST="<ip-address>"
USERNAME="<ftp username>"
DESTDIR="inbox"
UPLOADED_FILES="uploaded_files.txt"

# email variables
email_to="<some email address>"

cd $DIR
if [ ! -f "./$UPLOADED_FILES" ]
then
   touch "./$UPLOADED_FILES"
fi

number_of_files=`ls -l | egrep -E $PATTERN | wc -l`
echo `$DATE` "number of files:" $number_of_files

if [ $number_of_files -eq 0 ]
then
   echo `$DATE` " WARNING Directory is empty"
   exit 1
fi

files_to_be_uploaded=`ls | egrep -E $PATTERN | awk 'BEGIN {FS=""} {ORS=" "}{print}'`


for file in $files_to_be_uploaded
do
   sent_already=`cat $UPLOADED_FILES | grep "$file" | wc -l`
   if [ $sent_already -eq 0 ]
   then
      file_size=`du -b $file | awk '{print $1}'`
      if [ ! `expr $file_size % 1400` = 0 ]
      then
         echo `$DATE` "ERROR Wrong file size"
         mv $file ./files_with_wrong_size/
         level="ERROR"
         result="FAILURE"
         email_body="$file has size error (not divisible by 1400). Escalate to SVBO support team."
      else
         echo `$DATE` "INFO Sending $file size: $file_size"
         sftp -o "IdentityFile=$KEY" $USERNAME@$DEST 2>&1 <<EOF
         cd $DESTDIR
         ls -ltr
         quit
EOF
         if [ `echo $?` -eq 0 ]
         then
            echo `$DATE` "INFO" $file "uploaded successfully."
            rm -rf $file
            echo `$DATE` $file "Initial file sending..."  >> $UPLOADED_FILES
            level="INFO"
            result="SUCCESS"
            email_body="$file was uploaded."
         else
            echo `$DATE` " ERROR upload failed."
            level="ERROR"
            result="FAILURE"
            email_body="$file could not be uploaded due to transfer error. Wait for next execution. If it fails again, then escalate to Jenkins support team."
         fi
      fi
   else
      echo `$DATE` "WARNING" $file "was previously sent."
      mv -f $file ./duplicate_attempts/
      level="WARNING"
      result="FAILURE"
      email_body="$file was already sent."
   fi
    echo "$email_body" | mail -v -s "$level File sending result: $result" $email_to
done


exit 0

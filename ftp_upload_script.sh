#!/bin/bash
##################################################################################
# takes input variables from 1st argument!!!
# takes GNS*7002 files from /home_ext/amex_prod/outgoing/
# checks if file was previously sent in uploaded_files.txt
# if it was it moves the files to duplicate_attempts folder
#       wasn't it sends the file and registers the file name in uploaded_files.txt
###################################################################################


DATE="/bin/date"

echo `date +'%x %X'` INFO "Validating input arguments..."
if [ -z "$1" ]
    then
    echo `date +'%x %X'` "WARNING You must provide 1st argument! Configuration file."
    exit
fi

source $1
cd $DIR

if [ ! -f "./$UPLOADED_FILES" ]
then
   touch "./$UPLOADED_FILES"
fi

number_of_files=`ls -l | egrep -E "$PATTERN" | wc -l`
echo `$DATE` "INFO number of files:" $number_of_files

if [ $number_of_files -eq 0 ]
then
   echo `$DATE` "WARNING Directory is empty"
   exit 1
fi

files_to_be_uploaded=`ls | egrep -E "$PATTERN" | awk 'BEGIN {FS=""} {ORS=" "}{print}'`


for file in $files_to_be_uploaded
do
   sent_already=`cat $UPLOADED_FILES | grep "$file" | wc -l`
   if [ $sent_already -eq 0 ]
   then
      file_size=`du -b $file | awk '{print $1}'`
      if [ ! `expr $file_size % 1400` = 0 ] && [[ $1 == *"amex"* ]]
      then
         echo `$DATE` "ERROR Wrong file size"
         mv -f $file ./files_with_wrong_size/
         level="ERROR"
         result="FAILURE"
         email_body="$file has size error (not divisible by 1400). Escalate to SVBO support team."
      else
         echo `$DATE` "INFO Sending $file size: $file_size"
         sftp -o "IdentityFile=$KEY" $USERNAME@$DEST 2>&1 <<EOF
         cd $DESTDIR
         mput $file
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
            email_body="$file was uploaded to $email_client."
         else
            echo `$DATE` " ERROR upload failed."
            level="ERROR"
            result="FAILURE"
            email_body="$file could not be uploaded to $email_client due to transfer error. Wait for next execution. If it fail again, then escalate to Jenkins support team."
         fi
      fi
   else
      echo `$DATE` "WARNING" $file "was previously sent."
      mv -f $file ./duplicate_attempts/
      level="WARNING"
      result="FAILURE"
      email_body="$file was already sent to $email_client."
   fi
    echo "$email_body" | mail -v -s "$level $email_client file sending result: $result" $email_to
done


exit 0

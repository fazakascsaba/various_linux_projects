#!/bin/bash
# /root/scripts/consolidated/upload_desjardin_file.sh /root/scripts/consolidated/upload_desjardin_file.param

source $1
cd $DESJARDIN_FOLDER

# validate and log input files
if [ -n "$(ls -A $DESJARDIN_FOLDER/queue/i_drd_* 2>/dev/null)" ]
then
   cd ./queue
   files_in_queue=`ls -A i_drd_* | awk 'BEGIN {FS=""} {ORS=" "}{print}'`
   echo `date +'%x %X'`" INFO files are staged for transmission in queue folder: $files_in_queue"
   no_file_queue="False"
   cd ..
else
   echo `date +'%x %X'`" WARNING no file is staged for transmission in queue folder."
   no_file_queue="True"
fi

if [ -n "$(ls -A $DESJARDIN_FOLDER/input/i_drd_* 2>/dev/null)" ]
then
   cd ./input
   files_in_input=`ls -A i_drd_* | awk 'BEGIN {FS=""} {ORS=" "}{print}'`
   echo `date +'%x %X'`" INFO files are staged for transmission in input folder: $files_in_input"
   cd ..
else
   echo `date +'%x %X'`" WARNING no file is staged for transmission in input folder."
   if [ $no_file_queue = "True" ]
   then
      echo `date +'%x %X'`" WARNING no file is staged for transmission in input or queue folder."
      exit
   fi
fi

# check for holiday file
today=`date +%Y%m%d`
it_is_holiday=`cat $SCRIPT_FOLDER/$HOLIDAY_FILE | grep $today |wc -l`
if [ $it_is_holiday -eq 1 ]
then
    echo `date +'%x %X'`" INFO $today is a holiday. Moving input file to queue"
    mv ./input/* ./queue
    exit
fi

# check for weekend
if [ `date +%u` -gt 5 ]
then
    echo `date +'%x %X'`" INFO $today is weekend day. Moving input file to queue"
    mv ./input/* ./queue
    exit
fi

# send files
if [ -n "$(ls -A $DESJARDIN_FOLDER/queue 2>/dev/null)" ]
then
   cd ./queue
   echo `date +'%x %X'`" INFO sending files from queue folder."
   files_to_be_uploaded=`ls -tr i_drd_*.txt | awk 'BEGIN {FS=""} {ORS=" "}{print}'`
   for file in $files_to_be_uploaded
   do
      f=$(cut -d'.' -f1 <<<"$file")
      echo `date +'%x %X'`" INFO sending files from queue folder: $f.txt and $f.cksum"
      sftp -o "IdentityFile=$KEY" $USERNAME@$DEST 2>&1 <<EOF
      cd $DESTDIR
      put $f.txt
      put $f.cksum
      ls -ltr
      quit
EOF
      if [ `echo $?` -eq 0 ]
      then
         echo `date +'%x %X'`" INFO file uploaded."
         echo `date +'%x %X'`" Copying files to client's sFTP folder."
         cp $f* /var/local/ftp/psp_dir/Back_office_reports/desjardins/
         /bin/chown -R eornelas:sftponly /var/local/ftp/psp_dir/Back_office_reports/desjardins/*
         echo `date +'%x %X'`" Moving files to processed folder."
         mv $f* ../processed
      else
         echo `date +'%x %X'`" ERROR upload failed."
      fi
      sleep 10m
   done
   cd $DESJARDIN_FOLDER
fi

if [ -n "$(ls -A $DESJARDIN_FOLDER/input 2>/dev/null)" ]
then
   cd ./input
   echo `date +'%x %X'`" INFO sending files from input folder."
   files_to_be_uploaded=`ls -tr i_drd_*.txt | awk 'BEGIN {FS=""} {ORS=" "}{print}'`
   for file in $files_to_be_uploaded
   do
      f=$(cut -d'.' -f1 <<<"$file")
      echo `date +'%x %X'`" INFO sending files from input folder: $f.txt and $f.cksum"
      sftp -o "IdentityFile=$KEY" $USERNAME@$DEST 2>&1 <<EOF
      cd $DESTDIR
      put $f.txt
      put $f.cksum
      ls -ltr
      quit
EOF
      if [ `echo $?` -eq 0 ]
      then
         echo `date +'%x %X'`" INFO file uploaded."
         echo `date +'%x %X'`" Copying files to client's sFTP folder."
         cp $f* /var/local/ftp/psp_dir/Back_office_reports/desjardins/
         /bin/chown -R eornelas:sftponly /var/local/ftp/psp_dir/Back_office_reports/desjardins/*
         echo `date +'%x %X'`" Moving files to processed folder."
         mv $f* ../processed
      else
         echo `date +'%x %X'`" ERROR upload failed."
      fi
      sleep 10m
   done
   cd $DESJARDIN_FOLDER
fi

echo `date +'%x %X'`" INFO process finished."

exit

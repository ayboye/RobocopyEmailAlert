This scripts consists of multiple parts:
-Main Batch
-Email notification batch and XML for both success and fail.
-Retention batch fro deleting old files.
-Log management batch
-Email body txt

NOTE: Please replace anything in block brackets ([ ]) with the relevant information (please exclude the block brackets)
NOTE: This script is currently used to pull files from a network location to the local machine, hence the mapped drive. Feel free to comment these out if not needed.

The sendmail.exe software written by  David Levinson is required. Add this to the script folder.
Link at time of writing: http://www.fieldstonsoftware.com/software/sendmail/sendmail.zip

******Script Start: MainBatch.bat*******

:: [NAME] Backup Copy script
:: ===================================================================
::
:: This script will run the robocopy from folder to folder and then 
:: execute the follow-up batches depending on the return code.
::
:: ===================================================================

@echo on

:: Robocopy's Variables
set source=[drive or UNC]\[folder]\
set destination=C:\[folder]
set logfilelocation=C:\Scripts\log.txt
set scripts=C:\Scripts

:: Map Source Location
net use P: %source% /user:[usernameOfSource] [passwordOfSource]

:: Run the replication
robocopy P:\ %destination% /E /NFL /NDL /NC /NS /NP /LOG+:%logfilelocation%
if errorlevel 1 goto success
if errorlevel 0 goto success
goto fail  

:fail
call %scripts%\logmanage.bat
call %scripts%\failmail.bat
net use P: /delete /y

:success
call %scripts%\logmanage.bat
call %scripts%\successmail.bat
call %scripts%\cleansource.bat
call %scripts%\retentiondelete.bat
net use P: /delete /y
******Script End*******

The next script will Copy the log file to the archive and rename it with the current date.
Please be aware that some changes might need to be made to get this right on anything other than server 2012.
The data command output differently on different OS's.
******Script Start: LogManage.bat*******
:: Log management
:: =============================================================
::
:: This script will rename the log file to the current datestamp
:: and then copy it to the archive folder. 
::
:: =============================================================

set TODAY="%date:~0,2%-%date:~3,2%-%date:~6,4%"
set logfilelocation="C:\Scripts\log.txt"
set logarchive="C:\Scripts\archive"

:: Copies the log file
copy %logfilelocation% %logarchive%

:: Renames the newly copied logfile
rename %logarchive%\log.txt %TODAY%.txt
******Script End*******

If the Robocopy fails, this will be executed to send an email with the bad news. The XML will follow.
If will also delete to log file. Please ensute this is executed after logmanage.bat.
******Script Start: FailMail.bat*******
:: On Failure, this script will send an failure email with the log attached
:: ========================================================================

@echo off

set scripts="C:\Scripts"

:: Sends a notification email with the log attached
%scripts%\sendmail.exe %scripts%\failmail.xml

ping -n 2 -w 1000 127.0.0.1 > nul

:: Deletes the log file
del %scripts%\log.txt
******Script End*******

******XML Start: FailMail.XML********
<Sendmail>
    <Server host="[SMTP SERVER]" port="25" username="" password=""/>   
    <Message>
    	<Sender email="[EMAIL FROM]" name="Notifications"/>
    	<Recipient email="[EMAIL TO]" name="Notifications"/>
    	<Subject>[EMAIL SUBJECT]</Subject>
      	<Body filename="C:\Scripts\body.txt"/>
    </Message> 
    <Attachment filename="C:\Scripts\log.txt" title="report.txt"/>
</Sendmail>
******XML End*******

If the Robocopy fails, this will be executed to send an email with the bad news. The XML will follow.
If will also delete to log file. Please ensute this is executed after logmanage.bat.
******Script Start: SuccessMail.bat*******
:: On Failure, this script will send an failure email with the log attached
:: ========================================================================

@echo off

set scripts="C:\Scripts"

:: Sends a notification email with the log attached
%scripts%\sendmail.exe %scripts%\successmail.xml

ping -n 2 -w 1000 127.0.0.1 > nul

:: Deletes the log file
del %scripts%\log.txt
******Script End*******

******XML Start: SuccessMail.XML********
<Sendmail>
    <Server host="[SMTP SERVER]" port="25" username="" password=""/>   
    <Message>
    	<Sender email="[EMAIL FROM]" name="Notifications"/>
    	<Recipient email="[EMAIL TO]" name="Notifications"/>
    	<Subject>[EMAIL SUBJECT - Success!]</Subject>
      	<Body filename="C:\Scripts\body.txt"/>
    </Message> 
    <Attachment filename="C:\Scripts\log.txt" title="report.txt"/>
</Sendmail>
******XML End*******

Optional: This will clear the source folder.
******Script Start: cleansource.bat*******
:: Folder Clear Script
:: ============================================
:: 
:: This script will empty the folder contents
:: entirely, including subfolders and files.
::
:: ============================================

@echo off

set folder="P:\"

cd /d %folder%
for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q)
******Script End*******

My favourite: This will delete anything older than specified in the batch, see the comments.
******Script Start: RetentionDelete.bat*******
:: Retention Delete Script
:: ======================================================
:: This script is designed to delete specific files/type
:: older than a certain time frame.
::
:: For example:
:: If you wanted to delete all files older than 7 days
:: with the .bak extention in the C:\temp folder, use the
:: following settings:
:: folder="C:\temp"
:: target=*.bak
:: retention=-7
:: ======================================================

:: Folder to be filtered
set folder="[TARGET]"

:: File type to be filtered
set target=*.*

:: Retention period (Days)
set retention=-14

FORFILES /P %folder% /M %target% /D %retention% /C "cmd /c del @file"
******Script End*******

$dev_folder = ".\${env:ProjectName}";
$dest_folder = ${env:ProgramFiles(x86)} + "\World of Warcraft\_retail_\Interface\AddOns\" + ${env:ProjectName};

Xcopy /Y /E /I $dev_folder $dest_folder
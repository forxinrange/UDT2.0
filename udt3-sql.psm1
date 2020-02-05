## Local Admin Tool - SQL Engine ##

## Vars ##

$sql_server = "LSIDB-001"
$sql_db = "UclanDriveTool"

function return_readonly_sql_credentials(){

    $p_key = Get-Content "$env:SystemDrive\p.dat"
    $username = Get-Content "$PSScriptRoot\resources\squ.dat"
    $password = Get-Content "$PSScriptRoot\resources\skey.dat" | ConvertTo-SecureString -Key $p_key
    $credential = New-Object System.Management.Automation.PSCredential($username,$password)
    $credential.Password.MakeReadOnly()
    $sql_creds = New-Object System.Data.SqlClient.SqlCredential($credential.UserName,$credential.Password)
    return $sql_creds
 
}

function create_connection_object($sql_creds){
    
    $connection_object = New-Object System.Data.SqlClient.SqlConnection
    $connection_object.ConnectionString = "Data Source=$sql_server;Initial Catalog=$sql_db;Integrated Security=false"
    $connection_object.Credential = $sql_creds
    return $connection_object

}

function execute_sql_command($connection_object, $sql_cmd){

    $sql_command_object = New-Object System.Data.SqlClient.SqlCommand
    $sql_command_object.Connection = $connection_object
    $sql_command_object.CommandText = $sql_cmd
    $connection_object.Open()
    $sql_command_object.ExecuteNonQuery()
    $connection_object.Close()

}

function build_sql_command($runStatus,$errorCode,$osVersion,$modelNo,$macAddress,$UUID){

    $hostName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $sql_command = "INSERT INTO UclanDriveTool (hostName, userName, runStatus, errorCode, date, osVersion, modelNo, macAddress, UUID) VALUES ('$env:USERNAME','$env:COMPUTERNAME','$current_date','$end_date','$counter');"
    return $sql_command

}


if(test-connection $sql_server -Count 1 -Quiet){

    $s_creds = return_readonly_sql_credentials
    $connection_obj = create_connection_object $s_creds
    $current_date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $end_date = get_session_date
    $counter = session_counter
    execute_sql_command $connection_obj "INSERT INTO UclanDriveTool (hostName, userName, runStatus, errorCode, date, osVersion, modelNo, macAddress, UUID) VALUES ('$env:USERNAME','$env:COMPUTERNAME','$current_date','$end_date','$counter');"

}
else{

    Write-host "Unable to find SQL server.  Will try again at next logon"

}
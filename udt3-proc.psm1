## UCLan Drive Tool 3 - Proc Module ##

$settings = @{

    InternalCheck = "ntds.uclan.ac.uk";
    ExternalCheck = "www.google.co.uk";
    DrivePath = "Hello world how are you?";

}

function PROC_invoke_proc(){
    
    [System.Windows.Forms.MessageBox]::Show("Main sequence begins here", "Unfinished")

}

function PROC_test_type(){

    # This is a test of the comment system
    write-host $settings.InternalCheck

}

function PROC_testing(){

    write-host "Hello there"

}

function PROC_ping($url){

    if($(Test-Connection $url -Quiet -Count 1)){
        return $true
    }
    else{
        return $false
    }

}

function PROC_check_adapter($name){
    $adapter = Get-NetAdapter | where-object {$_.Name -like "*$name*"}
    if($adapter.Status -eq "Up"){
        return $true
    }
    else{
        return $false
    }
}

function PROC_map_network_drive($letter, $path){

    $check_count = 3

    while($check_count -ne 0){
        if($(Test-Path -Path "$($letter)\")){

            Write-Host "$path mapped to drive $($letter):"
            return $true
    
        }
        else{
    
            net use "$($letter):" "$path" /persistent:yes
            if($check_count -eq 0){
                return $false
            }
            $check_count--
        }
    }

    

}

function PROC_return_username(){

    return $(Get-WmiObject -class win32_computersystem).UserName.Split('\')[1]

}

function PROC_Return_Account_Obj($username){

    $ADSI = [ADSI]''
    $ADSI_Searcher = New-Object System.DirectoryServices.DirectorySearcher($ADSI)
    $ADSI_Searcher.Filter = "(&(objectClass=user)(sAMAccountName=$username))"

    try{

        $ADSI_Results = $ADSI_Searcher.FindOne()

    }
    catch [Exception] {
        Write-Host $_.Exception | Format-List -force
        $ADSI_Results = $null

    }
    
    return $ADSI_Results

}

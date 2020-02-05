## UCLan Drive Tool 3 - University of Central Lancashire ##
##                                                       ##
## Author : M Bradley 2020                               ##

# Load Modules #
Import-Module "$PSScriptRoot\udt3-gui.psm1" -Force
Import-Module "$PSScriptRoot\udt3-proc.psm1" -Force
Import-Module "$PSScriptRoot\udt3-evnt.psm1" -Force

# Begin Functions #

# Load Frameworks #
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# Global Path Hash #
$G_path_hash = @{}

# Global Directory Object #
$G_user_object

function M_Configure_Hash($type){

    if($G_user_object.properties.extensionattribute1 -eq "staff"){
        $script:G_path_hash.Add("N", "$($G_user_object.properties.homedirectory)")
        $script:G_path_hash.Add("S", "\\LSA-001\Share")
        $script:G_path_hash.Add("T", "\\LSA-002\Share")
        $script:G_path_hash.Add("U", "\\LSA-003\Share")
        $script:G_path_hash.Add("W", "\\LSA-201\Share")
        $script:G_path_hash.Add("Q", "\\ntds.uclan.ac.uk\Apps")
    }
    else{

        write-host "Hash not configured"
    }
}

function M_Start_Graphics($GUI_ROOT){

    Write-Output $GUI_ROOT
    # Initialise Graphics #
    $GUI_ROOT["GraphicsEngine"] = $GUI_ROOT["MainForm"].createGraphics()
    # Apply a fresh coat of paint #
    $GUI_ROOT["MainForm"].Add_Paint({
        $GUI_ROOT["GraphicsEngine"].FillRectangle($GUI_ROOT["BrushObject"], $GUI_ROOT["RectObject"])
    })
    # Invoke #
    $GUI_ROOT["MainForm"].ShowDialog()

}

function M_External_Network_Checks($GUI_ROOT){

    #External Check
    $event_ID = "N1"
    
    if(PROC_port_test "www.google.co.uk" 80){
        $status = EVENT_Status_Return_Array $false $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "Success!"
        return $true
    }
    else{
        $status = EVENT_Status_Return_Array $true $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "$($status[2])"
        return $false
    }

}

function M_Internal_Network_Checks($GUI_ROOT){

    #Internal Check
    $event_ID = "N2"
    if(PROC_ping "ntds.uclan.ac.uk"){
        $status = EVENT_Status_Return_Array $false $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "Success!"
        return $true
    }
    else{
        $status = EVENT_Status_Return_Array $true $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "$($status[2])"
        return $false
    }

}

function M_Check_Adapter($GUI_ROOT){
    [int]$validate = 0
    $event_ID = "A1"
    if(PROC_check_adapter "UCLan Network"){
        $status = EVENT_Status_Return_Array $false $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "Success!"
        $validate = 0
        return $true
    }
    else{
        $status = EVENT_Status_Return_Array $true $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "$($status[2])"
        $validate = 1
        return $false
    }
}

function M_Get_Account_Type($username, $GUI_ROOT){

    $event_ID = "T1"
    $user_object = PROC_Return_Account_Obj "$username"
    #$user_object = "Academic"
    if($null -eq $user_object){
        Write-Host "Status is empty"
        $status = EVENT_Status_Return_Array $true $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "$($status[2])"
        return $false
    }
    else{
        Write-Host "Status is there"
        $script:G_user_object = $user_object
        $status = EVENT_Status_Return_Array $false $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "Type: $($user_object.properties.extensionattribute1)"
        return $true
    }

}

function M_Map_Drive($GUI_ROOT, $letter, $path){

    $event_ID = "M1"

    if($(PROC_Check_Drive_Exist $letter)){

        $status = EVENT_Status_Return_Array $false $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0]) $($letter):" "$($status[1]) $($letter): ($($script:G_path_hash[$letter]))" "Drive $($letter): already mapped."
        
    }
    else{

        if($(PROC_map_network_drive $letter $path)){
            $status = EVENT_Status_Return_Array $false $event_ID
            GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0]) $($letter):" "$($status[1]) $($letter): ($($script:G_path_hash[$letter])" "Successfully mapped $($letter): drive!"
            return $true
        }
        else{
            $status = EVENT_Status_Return_Array $true $event_ID
            GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1]) $letter" "$($status[2])"
            return $false
        }

    }

}

function M_Error_Triggered($GUI_ROOT){
    
    GUI_update_form $GUI_ROOT["MainForm"]
    GUI_change_element_text $GUI_ROOT["StatusLabel"] "Error - see below."
    $GUI_ROOT["StatusLabel"].ForeColor = "Red"
    GUI_update_form $GUI_ROOT["MainForm"]

}

function M_Update_Status($GUI_ROOT, $message){

    GUI_update_form $GUI_ROOT["MainForm"]
    GUI_change_element_text $GUI_ROOT["StatusLabel"] "$message"
    GUI_update_form $GUI_ROOT["MainForm"]    

}

function M_check_pass_sequence($GUI_ROOT,$row_no,$next_status){

    GUI_Change_Row_Colour $GUI_ROOT $row_no "Green"
    GUI_update_form $GUI_ROOT["MainForm"]
    M_Update_Status $GUI_ROOT "$next_status"
    GUI_update_form $GUI_ROOT["MainForm"]

}

function M_Initiate_Checks($GUI_ROOT){

    $GUI_ROOT["StatusLabel"].ForeColor = "Black"
    $finished = $false
    GUI_clear_grid($GUI_ROOT)

    # Change status to running #
    M_Update_Status $GUI_ROOT "Performing tasks..."

    ## BEGIN CHECKS SEQUENCE ##

    M_Update_Status $GUI_ROOT "Checking AlwaysOn."
    GUI_update_form $GUI_ROOT["MainForm"]

    if($(M_External_Network_Checks $GUI_ROOT)[1] -eq $true){
        M_check_pass_sequence $GUI_ROOT 0 "Checking Internet."
        if($(M_Check_Adapter $GUI_ROOT)[1] -eq $true){
            M_check_pass_sequence $GUI_ROOT 1 "Checking Domain."
            if($(M_Internal_Network_Checks $GUI_ROOT)[1] -eq $true){
                M_check_pass_sequence $GUI_ROOT 2 "Checking Active Directory"
                if($(M_Get_Account_Type "$(PROC_return_username)" $GUI_ROOT)[1] -eq $true){                    
                    GUI_Change_Row_Colour $GUI_ROOT 3 "Green"
                    GUI_update_form $GUI_ROOT["MainForm"]
                    M_Configure_Hash $script:G_user_object.properties.extensionattribute1
                    # MAP DRIVES #
                    $table_row_position = 4
                    foreach($key in $($script:G_path_hash.keys)){
                        M_Update_Status $GUI_ROOT "Mapping $($key): drive"
                        if($(M_Map_Drive $GUI_ROOT "$key" "$($script:G_path_hash[$key])")){
                            GUI_Change_Row_Colour $GUI_ROOT $table_row_position "Green"
                            GUI_update_form $GUI_ROOT["MainForm"]
                        }
                        else{
                            M_Error_Triggered $GUI_ROOT
                            GUI_Change_Row_Colour $GUI_ROOT $table_row_position "Red"
                        }
                        $table_row_position++
                    }
                    $finished = $true
                }
                else{
                    M_Error_Triggered $GUI_ROOT
                    GUI_Change_Row_Colour $GUI_ROOT 3 "Red"
                }
            }
            else{
                M_Error_Triggered $GUI_ROOT
                GUI_Change_Row_Colour $GUI_ROOT 2 "Red"
            }
        }
        else{
            M_Error_Triggered $GUI_ROOT
            GUI_Change_Row_Colour $GUI_ROOT 1 "Red"
        }
    }
    else{
        M_Error_Triggered $GUI_ROOT
        GUI_Change_Row_Colour $GUI_ROOT 0 "Red"
    }

    if($finished -eq $true){
        M_Update_Status $GUI_ROOT "Complete!"
        $GUI_ROOT["StatusLabel"].ForeColor = "Green"
        GUI_update_form $GUI_ROOT["MainForm"]
    }
    else{
        write-host "Exited with errors..."
    }
}

function main($switch){

    if($switch -ne "silent"){

        #GUI_faux_loading
        # Activate the Graphics Engine #
        $GUI_ROOT = GUI_Construct
        
        # Trigger on Button Press
        $GUI_ROOT["RecheckBtn"].add_Click({
            $script:G_user_object = $null
            $script:G_path_hash = @{}
            M_Initiate_Checks $GUI_ROOT
        })

        # Auto Trigger when launched
        $GUI_ROOT["MainForm"].add_Shown({

            #GUI_Hide_Console
            M_Initiate_Checks $GUI_ROOT

        })

        $GUI_ROOT["HelpButton"].add_Click({
            PROC_open_web "https://uclan.topdesk.net/tas/public/ssp"
        })

        M_Start_Graphics $GUI_ROOT
        
        
    }
    else{

        $GUI_ROOT = GUI_Construct
        M_Initiate_Checks $GUI_ROOT

    }

}


# End Functions #

# # Entry Point # #
main $args[0]
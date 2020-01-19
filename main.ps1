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
    
    if(PROC_ping "www.google.co.uk"){
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
    if(PROC_ping "www.google.co.uk"){
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
    if(PROC_check_adapter "WiFi"){
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

    if($null -eq $user_object){
        Write-Host "Status is empty"
        $status = EVENT_Status_Return_Array $true $event_ID
        GUI_update_grid $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "$($status[2])"
        return $false
    }
    else{
        Write-Host "Status is there"
        $status = EVENT_Status_Return_Array $false $event_ID
        GUI_update_form $GUI_ROOT["DataTable"] "$($status[0])" "$($status[1])" "Account type is: $($user_object.properties.extensionattribute1)"
        return $true
    }

}

function M_Error_Triggered($GUI_ROOT){
    
    GUI_update_form $GUI_ROOT["MainForm"]
    GUI_change_element_text $GUI_ROOT["StatusLabel"] "Error - see below."
    GUI_update_form $GUI_ROOT["MainForm"]

}

function M_Update_Status($GUI_ROOT, $message){

    GUI_update_form $GUI_ROOT["MainForm"]
    GUI_change_element_text $GUI_ROOT["StatusLabel"] "$message"
    GUI_update_form $GUI_ROOT["MainForm"]    

}

function M_Initiate_Checks($GUI_ROOT){


    GUI_clear_grid($GUI_ROOT)

    # Change status to running #
    M_Update_Status $GUI_ROOT "Performing tasks..."

    ## BEGIN CHECKS SEQUENCE ##

    M_Update_Status $GUI_ROOT "Checking AlwaysOn."
    GUI_update_form $GUI_ROOT["MainForm"]

    if($(M_External_Network_Checks $GUI_ROOT)[1] -eq $true){


        GUI_Change_Row_Colour $GUI_ROOT 0 "Green"
        GUI_update_form $GUI_ROOT["MainForm"]
        M_Update_Status $GUI_ROOT "Checking Internet."
        GUI_update_form $GUI_ROOT["MainForm"]

        if($(M_Check_Adapter $GUI_ROOT)[1] -eq $true){

            GUI_Change_Row_Colour $GUI_ROOT 1 "Green"
            GUI_update_form $GUI_ROOT["MainForm"]
            M_Update_Status $GUI_ROOT "Checking Domain."
            GUI_update_form $GUI_ROOT["MainForm"]

            if($(M_Internal_Network_Checks $GUI_ROOT)[1] -eq $true){

                GUI_Change_Row_Colour $GUI_ROOT 2 "Green"
                GUI_update_form $GUI_ROOT["MainForm"]
                M_Update_Status $GUI_ROOT "Checking Active Directory"
                GUI_update_form $GUI_ROOT["MainForm"]

                if($(M_Get_Account_Type "$(PROC_return_username)" $GUI_ROOT)[1] -eq $true){
                    
                    GUI_Change_Row_Colour $GUI_ROOT 3 "Green"
                    GUI_update_form $GUI_ROOT["MainForm"]

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
}

function main($switch){

    if($switch -ne "silent"){

        # Activate the Graphics Engine #
        $GUI_ROOT = GUI_Construct
        
        # Trigger on Button Press
        $GUI_ROOT["RecheckBtn"].add_Click({
            M_Initiate_Checks $GUI_ROOT
        })

        # Auto Trigger when launched
        $GUI_ROOT["MainForm"].add_Shown({

            #GUI_Hide_Console
            M_Initiate_Checks $GUI_ROOT

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
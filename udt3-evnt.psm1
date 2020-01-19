# Event I/O processor #

$MASTER_EVENTS = Import-Csv "$PSScriptRoot\e.csv"

function EVENT_Status_Return_Array($isError, $ID){

    if($isError){
        $event = $MASTER_EVENTS | where-object {$_.ID -eq "$ID"}
        $returnArray = @("$($event.Name)","$($event.ErrorText)","$($event.Help)")
        return $returnArray
    }
    else {
        $event = $MASTER_EVENTS | where-object {$_.ID -eq "$ID"}
        $returnArray = @("$($event.Name)","$($event.SuccessText)","$($event.Help)")
        return $returnArray
    }

}
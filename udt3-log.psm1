# UCLan Drive Tool 3 - Log Writer #

function LOG_Create_Log_Directory($directory){

    if(-not(Test-Path "$directory")){

        mkdir "$directory" -Force

    }

}

function LOG_Write_Entry($log_file, $log_event, $log_message){

    $directory = Split-Path $log_file


}


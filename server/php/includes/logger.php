<?php

/**
* 
*/
class Logger
{
    static public function log($msg)
    {
        if (!defined('ENABLE_LOGGING') || !ENABLE_LOGGING)
        {
            return;
        }
        file_put_contents('../log/hockey.log', $msg."\n", FILE_APPEND);
    }
}


?>
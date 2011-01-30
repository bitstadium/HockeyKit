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
        $trace = debug_backtrace();
        $msg = sprintf("%s (%s)::%s :: %d\t%s",
            array_key_exists('object', $trace[1]) ? get_class($trace[1]['object']) : '',
            array_key_exists('class', $trace[1]) ? $trace[1]['class'] : '',
            isset($trace[1]['function']) ? $trace[1]['function'] : '?',
            isset($trace[0]['line']) ? $trace[0]['line'] : '?',
            $msg
        );

        file_put_contents('../log/hockey.log', $msg."\n", FILE_APPEND);
    }
}


?>
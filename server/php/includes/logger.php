<?php

/**
* 
*/
class Logger
{
    static public function log($msg, $more = false)
    {
        if (!defined('ENABLE_LOGGING') || !ENABLE_LOGGING)
        {
            return;
        }
        $trace = debug_backtrace();
        
        $offset = $more ? 1 : 0;
        $msg = sprintf("%s (%s)::%s :: %d\t%s",
            array_key_exists('object', $trace[1+$offset]) ? get_class($trace[1+$offset]['object']) : '',
            array_key_exists('class', $trace[+$offset]) ? $trace[1+$offset]['class'] : '',
            isset($trace[1+$offset]['function']) ? $trace[1+$offset]['function'] : '?',
            isset($trace[0+$offset]['line']) ? $trace[0+$offset]['line'] : '?',
            $msg
        );
        
        $path = dirname(dirname(__FILE__)) . '/log';
        if(!is_dir($path))
        {
            mkdir($path);
        }
        @file_put_contents("$path/hockey.log", "$msg\n", FILE_APPEND);
    }
}


?>
<?php

/**
* Helper class providing utility functions
*/
class Helper
{
    const CHUNK_SIZE = 65536; // Size (in bytes) of tiles chunk

    // Read a file and display its content chunk by chunk
    static public function readfile_chunked($filename, $retbytes = TRUE) {
        $buffer = '';
        $cnt =0;
        // $handle = fopen($filename, 'rb');
        $handle = fopen($filename, 'rb');
        if ($handle === false) {
            return false;
        }
        while (!feof($handle)) {
            $buffer = fread($handle, self::CHUNK_SIZE);
            echo $buffer;
            @ob_flush();
            @flush();
            if ($retbytes) {
                $cnt += strlen($buffer);
            }
        }
        $status = fclose($handle);
        if ($retbytes && $status) {
            return $cnt; // return num. bytes delivered like readfile() does.
        }
        return $status;
    }

    static public function nl2br_skip_html($string) {
        // remove any carriage returns (Windows)
        $string = str_replace("\r", '', $string);

        // replace any newlines that aren't preceded by a > with a <br />
        $string = preg_replace('/(?<!>)\n/', "<br />\n", $string);

        return $string;
    }
    
    static public function array_orderby()
    {
        $args = func_get_args();
        $data = array_shift($args);
        foreach ($args as $n => $field) {
            if (is_string($field)) {
                $tmp = array();
                foreach ($data as $key => $row)
                    $tmp[$key] = $row[$field];
                    $args[$n] = $tmp;
                }
        }
        $args[] = &$data;
        @call_user_func_array('array_multisort', $args);
        return array_pop($args);
    }
    
    // map a device code into readable name
    static public function mapPlatform($device)
    {
        $platform = $device;
        
        switch ($device) {
            case "i386":
            case "x86_64":
                $platform = "iOS Simulator";
                break;
            case "iPhone1,1":
                $platform = "iPhone";
                break;
            case "iPhone1,2":
                $platform = "iPhone 3G";
                break;
            case "iPhone2,1":
                $platform = "iPhone 3GS";
                break;
            case "iPhone3,1":
                $platform = "iPhone 4";
                break;
            case "iPhone3,3":
                $platform = "iPhone 4 CDMA";
                break;
            case "iPhone4,1":
                $platform = "iPhone 4S";
                break;
            case "iPhone5,1":
                $platform = "iPhone 5 GSM";
                break;
            case "iPhone5,2":
                $platform = "iPhone 5 CDMA";
                break;
            case "iPhone5,3":
                $platform = "iPhone 5C GSM";
                break;
            case "iPhone5,4":
                $platform = "iPhone 5C CDMA";
                break;
            case "iPhone6,1":
                $platform = "iPhone 5S GSM";
                break;
            case "iPhone6,2":
                $platform = "iPhone 5S CDMA";
                break;
            case "iPad1,1":
                $platform = "iPad";
                break;
            case "iPad2,1":
                $platform = "iPad 2 WiFi";
                break;
            case "iPad2,2":
                $platform = "iPad 2 GSM";
                break;
            case "iPad2,3":
                $platform = "iPad 2 CDMA";
                break;
            case "iPad3,1":
                $platform = "iPad 3 WiFi";
                break;
            case "iPad3,2":
                $platform = "iPad 3 CDMA";
                break;
            case "iPad3,3":
                $platform = "iPad 3 GSM";
                break;
            case "iPad3,4":
                $platform = "iPad 4 WiFi";
                break;
            case "iPad3,5":
                $platform = "iPad 4 GSM";
                break;
            case "iPad3,6":
                $platform = "iPad 4 CDMA";
                break;
            case "iPad2,5":
                $platform = "iPad Mini WiFi";
                break;
            case "iPad2,6":
                $platform = "iPad Mini GSM";
                break;
            case "iPad2,7":
                $platform = "iPad Mini CDMA";
                break;
            case "iPad4,1":
                $platform = "iPad Air WiFi";
                break;
            case "iPad4,2":
                $platform = "iPad Air GSM+CDMA";
                break;
            case "iPad4,4":
                $platform = "iPad Mini Retina WiFi";
                break;
            case "iPad4,5":
                $platform = "iPad Mini Retina WiFi";
                break;
            case "iPod1,1":
                $platform = "iPod Touch";
                break;
            case "iPod2,1":
                $platform = "iPod Touch 2nd Gen";
                break;
            case "iPod3,1":
                $platform = "iPod Touch 3rd Gen";
                break;
            case "iPod4,1":
                $platform = "iPod Touch 4th Gen";
                break;
            case "iPod5,1":
                $platform = "iPod Touch 5th Gen";
                break;
        }
        
        return $platform;
    }
    
    static public function sendFile($filename, $content_type = 'application/octet-stream')
    {
        @ob_end_clean();
        header('Content-Disposition: attachment; filename=' . urlencode(basename($filename)));
        header("Content-Type: $content_type");
        header('Content-Transfer-Encoding: binary');
        header('Content-Length: '.filesize($filename)."\n");
        Helper::readfile_chunked($filename);
        exit;
    }
    
    static public function sendJSONAndExit($content, $info = null)
    {
        // error case
        if (is_numeric($content))
        {
            $content = array(AppUpdater::RETURN_RESULT => $content);
        }
        
        @ob_end_clean();
        header('Content-type: application/json');
        echo json_encode($content);
        exit();
    }
 
    static public function secondsToTime($seconds)
    {
        if ($seconds == "" or $seconds == 0)
            return $seconds;
            
        // extract hours
        $hours = floor($seconds / (60 * 60));
 
        // extract minutes
        $divisor_for_minutes = $seconds % (60 * 60);
        $minutes = floor($divisor_for_minutes / 60);
 
        // extract the remaining seconds
        $divisor_for_seconds = $divisor_for_minutes % 60;
        $seconds = ceil($divisor_for_seconds);
 
        $result = "";
        if ($hours > 0)
            $result .= $hours."h ";

        if ($minutes > 0)
            $result .= $minutes."m ";

        if ($seconds > 0)
            $result .= $seconds."s";
            
        return $result;
    }
       
}

?>

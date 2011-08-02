<?php

class DeviceDetector
{
    public static $isOldIOSDevice  = false; 
    public static $isNewIOSDevice  = false;
    public static $isiPad4Device   = false;
    public static $isAndroidDevice = false;
    public static $category        = "";

    public static function detect()
    {
        $agent = $_SERVER['HTTP_USER_AGENT'];
    
        if (strpos($agent, 'iPad') !== false) {
            if (strpos($agent, 'OS 3') !== false) {
                self::$isOldIOSDevice = true;
            } else {
                self::$isiPad4Device = true;
            }
        } else if (strpos($agent, 'iPhone') !== false) {
            if (strpos($agent, 'iPhone OS 3') !== false) {
                self::$isOldIOSDevice = true;
            } else {
                self::$isNewIOSDevice = true;
            }
        } else if (strpos($agent, 'Android') !== false) {
            self::$isAndroidDevice = true;
        }
    
        if (self::$isNewIOSDevice) {
            self::$category = "browser-ios4";
        } else if (self::$isiPad4Device) {
            self::$category = "browser-ipad4";
        } else if (self::$isOldIOSDevice) {
            self::$category = "browser-old-ios";
        } else if (self::$isAndroidDevice) {
            self::$category = "browser-android";
        } else {
            self::$category = "browser-desktop";
        }
    }
}


?>
<?php

## index.php
## 
##  Created by Andreas Linde on 8/17/10.
##             Stanley Rost on 8/17/10.
##  Copyright 2010 Andreas Linde. All rights reserved.
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in
##  all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
##  THE SOFTWARE.

require('json.inc');
require('plist.inc');
require_once('config.inc');

define('CHUNK_SIZE', 1024*1024); // Size (in bytes) of tiles chunk

  // Read a file and display its content chunk by chunk
  function readfile_chunked($filename, $retbytes = TRUE) {
    $buffer = '';
    $cnt =0;
    // $handle = fopen($filename, 'rb');
    $handle = fopen($filename, 'rb');
    if ($handle === false) {
      return false;
    }
    while (!feof($handle)) {
      $buffer = fread($handle, CHUNK_SIZE);
      echo $buffer;
      ob_flush();
      flush();
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

function nl2br_skip_html($string)
{
	// remove any carriage returns (Windows)
	$string = str_replace("\r", '', $string);

	// replace any newlines that aren't preceded by a > with a <br />
	$string = preg_replace('/(?<!>)\n/', "<br />\n", $string);

	return $string;
}

class AppUpdater
{
    // define the parameters being sent by the client checking for a new version
    const CLIENT_KEY_TYPE       = 'type';
    const CLIENT_KEY_BUNDLEID   = 'bundleidentifier';
    const CLIENT_KEY_APIVERSION = 'api';
    const CLIENT_KEY_UDID       = 'udid';                   // iOS client only
    const CLIENT_KEY_APPVERSION = 'version';
    const CLIENT_KEY_IOSVERSION = 'ios';                    // iOS client only
    const CLIENT_KEY_PLATFORM   = 'platform';
    const CLIENT_KEY_LANGUAGE   = 'lang';
    
    // define URL type parameter values
    const TYPE_PROFILE  = 'profile';
    const TYPE_APP      = 'app';
    const TYPE_IPA      = 'ipa';
    const TYPE_APK      = 'apk';
    const TYPE_AUTH     = 'authorize';

    // define the json response format version
    const API_V1 = '1';
    const API_V2 = '2';
    
    // define support app platforms
    const APP_PLATFORM_IOS      = "iOS";
    const APP_PLATFORM_ANDROID  = "Android";
    
    // define keys for the returning json string api version 1
    const RETURN_RESULT   = 'result';
    const RETURN_NOTES    = 'notes';
    const RETURN_TITLE    = 'title';
    const RETURN_SUBTITLE = 'subtitle';

    // define keys for the returning json string api version 2
    const RETURN_V2_VERSION         = 'version';
    const RETURN_V2_SHORTVERSION    = 'shortversion';
    const RETURN_V2_NOTES           = 'notes';
    const RETURN_V2_TITLE           = 'title';
    const RETURN_V2_TIMESTAMP       = 'timestamp';
    const RETURN_V2_AUTHCODE        = 'authcode';

    const RETURN_V2_AUTH_FAILED     = 'FAILED';

    // define keys for the array to keep a list of available beta apps to be displayed in the web interface
    const INDEX_APP             = 'app';
    const INDEX_VERSION         = 'version';
    const INDEX_SUBTITLE        = 'subtitle';
    const INDEX_DATE            = 'date';
    const INDEX_NOTES           = 'notes';
    const INDEX_PROFILE         = 'profile';
    const INDEX_PROFILE_UPDATE  = 'profileupdate';
    const INDEX_DIR             = 'dir';
    const INDEX_IMAGE           = 'image';
    const INDEX_STATS           = 'stats';
    const INDEX_PLATFORM        = 'platform';

    // define filetypes
    const FILE_IOS_PLIST        = '.plist';
    const FILE_IOS_IPA          = '.ipa';
    const FILE_IOS_PROFILE      = '.mobileprovision';
    const FILE_ANDROID_JSON     = '.json';
    const FILE_ANDROID_APK      = '.apk';
    const FILE_COMMON_NOTES     = '.html';
    const FILE_COMMON_ICON      = '.png';
    
    const FILE_VERSION_RESTRICT = '.team';                  // if present in a version subdirectory, defines the teams that do have access, comma separated
    const FILE_USERLIST         = 'stats/userlist.txt';     // defines UDIDs, real names for stats, and comma separated the associated team names
    
    // define version array structure
    const VERSIONS_COMMON_DATA      = 'common';
    const VERSIONS_SPECIFIC_DATA    = 'specific';
    
    // define keys for the array to keep a list of devices installed this app
    const DEVICE_USER       = 'user';
    const DEVICE_PLATFORM   = 'platform';
    const DEVICE_OSVERSION  = 'osversion';
    const DEVICE_APPVERSION = 'appversion';
    const DEVICE_LANGUAGE   = 'language';
    const DEVICE_LASTCHECK  = 'lastcheck';

    protected $appDirectory;
    protected $json = array();
    public $applications = array();

    
    function __construct($dir) {
        
        date_default_timezone_set('UTC');

        $this->appDirectory = $dir;

        $bundleidentifier = isset($_GET[self::CLIENT_KEY_BUNDLEID]) ?
            $this->validateDir($_GET[self::CLIENT_KEY_BUNDLEID]) : null;

        $type = isset($_GET[self::CLIENT_KEY_TYPE]) ? $this->validateType($_GET[self::CLIENT_KEY_TYPE]) : null;
        $api = isset($_GET[self::CLIENT_KEY_APIVERSION]) ? $this->validateAPIVersion($_GET[self::CLIENT_KEY_APIVERSION]) : self::API_V1;
        
        // if a bundleidentifier is submitted and request coming from a client, return JSON
        if ($bundleidentifier && 
            (
                strpos($_SERVER["HTTP_USER_AGENT"], 'CFNetwork') !== false ||       // iOS network requests, which means the client is calling, old versions don't add a custom user agent
                strpos($_SERVER["HTTP_USER_AGENT"], 'Hockey/iOS') !== false ||      // iOS hockey client is calling
                strpos($_SERVER["HTTP_USER_AGENT"], 'Hockey/Android') !== false ||  // Android hockey client is calling
                $type
            ))
        {
            return $this->deliver($bundleidentifier, $api, $type);
        }
        
        // if a bundleidentifier is provided, only show that app
        $this->show($bundleidentifier);
    }
    
    protected function array_orderby()
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


    protected function validateDir($dir)
    {
        // do not allow .. or / in the name and check if that path actually exists
        if (
            $dir &&
            !preg_match('#(/|\.\.)#u', $dir) &&
            file_exists($this->appDirectory.$dir))
        {
            return $dir;
        }
        return null;
    }
    
    protected function validateType($type)
    {
        if (in_array($type, array(self::TYPE_PROFILE, self::TYPE_APP, self::TYPE_IPA, self::TYPE_AUTH, self::TYPE_APK)))
        {
            return $type;
        }
        return null;
    }

    protected function validateAPIVersion($api)
    {
        if (in_array($api, array(self::API_V1, self::API_V2)))
        {
            return $api;
        }
        return self::API_V1;
    }
    
    // map a device UDID into a username
    protected function mapUser($user, $userlist)
    {
        $username = $user;
        $lines = explode("\n", $userlist);

        foreach ($lines as $i => $line) :
            if ($line == "") continue;
            
            $userelement = explode(";", $line);

            if (count($userelement) >= 2) {
                if ($userelement[0] == $user) {
                    $username = $userelement[1];
                    break;
                }
            }
        endforeach;

        return $username;
    }
    
    // map a device UDID into a list of assigned teams
    protected function mapTeam($user, $userlist)
    {
        $teams = "";
        $lines = explode("\n", $userlist);

        foreach ($lines as $i => $line) :
            if ($line == "") continue;
            
            $userelement = explode(";", $line);

            if (count($userelement) == 3) {
                if ($userelement[0] == $user) {
                    $teams = $userelement[2];
                    break;
                }
            }
        endforeach;

        return $teams;
    }
    
    // map a device code into readable name
    protected function mapPlatform($device)
    {
        $platform = $device;
        
        switch ($device) {
            case "i386":
                $platform = "iPhone Simulator";
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
            case "iPad1,1":
                $platform = "iPad";
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
        }
	
        return $platform;
    }

    protected function addStats($bundleidentifier)
    {
        // did we get any user data?
        $udid = isset($_GET[self::CLIENT_KEY_UDID]) ? $_GET[self::CLIENT_KEY_UDID] : null;
        $appversion = isset($_GET[self::CLIENT_KEY_APPVERSION]) ? $_GET[self::CLIENT_KEY_APPVERSION] : "";
        $osversion = isset($_GET[self::CLIENT_KEY_IOSVERSION]) ? $_GET[self::CLIENT_KEY_IOSVERSION] : "";
        $platform = isset($_GET[self::CLIENT_KEY_PLATFORM]) ? $_GET[self::CLIENT_KEY_PLATFORM] : "";
        $language = isset($_GET[self::CLIENT_KEY_LANGUAGE]) ? strtolower($_GET[self::CLIENT_KEY_LANGUAGE]) : "";
        
        if ($udid && $type != self::TYPE_AUTH) {
            $thisdevice = $udid.";;".$platform.";;".$osversion.";;".$appversion.";;".date("m/d/Y H:i:s").";;".$language;
            $content =  "";

            $filename = $this->appDirectory."stats/".$bundleidentifier;

            if (is_dir($this->appDirectory."stats/")) {
                $content = @file_get_contents($filename);
            
                $lines = explode("\n", $content);
                $content = "";
                $found = false;
                foreach ($lines as $i => $line) :
                    if ($line == "") continue;
                    $device = explode( ";;", $line);

                    $newline = $line;
                
                    if (count($device) > 0) {
                        // is this the same device?
                        if ($device[0] == $udid) {
                            $newline = $thisdevice;
                            $found = true;
                        }
                    }
                
                    $content .= $newline."\n";
                endforeach;
            
                if (!$found) {
                    $content .= $thisdevice;
                }
            
                // write back the updated stats
                @file_put_contents($filename, $content);
            }
        }
    }

    protected function deliverJson($api, $files)
    {
        // check for available updates for the given bundleidentifier
        // and return a JSON string with the result values

        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $ipa = $current[self::FILE_IOS_IPA];
        $plist = $current[self::FILE_IOS_PLIST];
        $apk = $current[self::FILE_ANDROID_APK];
        $json = $current[self::FILE_ANDROID_JSON];
        $note = $current[self::FILE_COMMON_NOTES];
        
        $profile = $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE];
        $image = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];
        
        if ($ipa && $plist) {
            
            // this is an iOS app
            if ($api == self::API_V1) {
                // this is API Version 1
                
                // parse the plist file
                $plistDocument = new DOMDocument();
                $plistDocument->load($plist);
                $parsed_plist = parsePlist($plistDocument);

                // get the bundle_version which we treat as build number
                $latestversion = $parsed_plist['items'][0]['metadata']['bundle-version'];
                
                // add the latest release notes if available
                if ($note) {
                    $this->json[self::RETURN_NOTES] = nl2br_skip_html(file_get_contents($appDirectory . $note));
                }

                $this->json[self::RETURN_TITLE]   = $parsed_plist['items'][0]['metadata']['title'];

                if ($parsed_plist['items'][0]['metadata']['subtitle'])
    	            $this->json[self::RETURN_SUBTITLE]   = $parsed_plist['items'][0]['metadata']['subtitle'];

                $this->json[self::RETURN_RESULT]  = $latestversion;

                return $this->sendJSONAndExit();
            } else {
                // this is API Version 2
                
                $appversion = isset($_GET[self::CLIENT_KEY_APPVERSION]) ? $_GET[self::CLIENT_KEY_APPVERSION] : "";
                
                foreach ($files[self::VERSIONS_SPECIFIC_DATA] as $version) {
                    $ipa = $version[self::FILE_IOS_IPA];
                    $plist = $version[self::FILE_IOS_PLIST];
                    $note = $version[self::FILE_COMMON_NOTES];
                    
                    // parse the plist file
                    $plistDocument = new DOMDocument();
                    $plistDocument->load($plist);
                    $parsed_plist = parsePlist($plistDocument);

                    // get the bundle_version which we treat as build number
                    $thisVersion = $parsed_plist['items'][0]['metadata']['bundle-version'];
                    
                    $newAppVersion = array();
                    // add the latest release notes if available
                    if ($note) {
                        $newAppVersion[self::RETURN_V2_NOTES] = nl2br_skip_html(file_get_contents($appDirectory . $note));
                    }

                    $newAppVersion[self::RETURN_V2_TITLE]   = $parsed_plist['items'][0]['metadata']['title'];

                    if ($parsed_plist['items'][0]['metadata']['subtitle'])
    	                $newAppVersion[self::RETURN_V2_SHORTVERSION]   = $parsed_plist['items'][0]['metadata']['subtitle'];

                    $newAppVersion[self::RETURN_V2_VERSION]  = $thisVersion;
            
                    $newAppVersion[self::RETURN_V2_TIMESTAMP]  = filectime($appDirectory . $ipa);;

                    $this->json[] = $newAppVersion;
                    
                    // only send the data until the current version if provided
                    if ($appversion == $thisVersion) break;
                }
                return $this->sendJSONAndExit();
            }
        } else if ($apk && $json) {
            
            // this is an Android app
            
            $appversion = isset($_GET[self::CLIENT_KEY_APPVERSION]) ? $_GET[self::CLIENT_KEY_APPVERSION] : "";
            
            // API version is V2 by default, even if the client provides V1
            foreach ($files[self::VERSIONS_SPECIFIC_DATA] as $version) {
                $apk = $version[self::FILE_ANDROID_APK];
                $json = $version[self::FILE_ANDROID_JSON];
                $note = $version[self::FILE_COMMON_NOTES];
                
                // parse the json file
                $parsed_json = json_decode(file_get_contents($appDirectory . $json), true);
            
                $newAppVersion = array();
                // add the latest release notes if available
                if ($note) {
                    $newAppVersion[self::RETURN_V2_NOTES] = nl2br_skip_html(file_get_contents($appDirectory . $note));
                }

                $newAppVersion[self::RETURN_V2_TITLE]   = $parsed_json['title'];

                $newAppVersion[self::RETURN_V2_SHORTVERSION]  = $parsed_json['versionName'];
                $newAppVersion[self::RETURN_V2_VERSION]  = $parsed_json['versionCode'];
        
                $newAppVersion[self::RETURN_V2_TIMESTAMP]  = filectime($appDirectory . $apk);;

                $this->json[] = $newAppVersion;
                
                // only send the data until the current version if provided
                if ($appversion == $parsed_json['versionCode']) break;
            }
            return $this->sendJSONAndExit();
        }
    }

    protected function deliverIOSProfile($filename)
    {
        // send latest profile for the given bundleidentifier
        header('Content-Disposition: attachment; filename=' . urlencode(basename($filename)));
        header('Content-Type: application/vnd.android.package-archive apk');
        header('Content-Transfer-Encoding: binary');
        header('Content-Length: '.filesize($filename)."\n");
        readfile($filename);
    }
    
    protected function deliverIOSAppPlist($bundleidentifier, $ipa, $plist, $image)
    {
        $protocol = strtolower(substr($_SERVER["SERVER_PROTOCOL"],0,5))=='https'?'https':'http';
        
        // send XML with url to app binary file
        $ipa_url = dirname($protocol."://".$_SERVER['SERVER_NAME'].':'.$_SERVER["SERVER_PORT"].$_SERVER['REQUEST_URI']) . '/index.php?type=' . self::TYPE_IPA . '&amp;bundleidentifier=' . $bundleidentifier;

        $plist_content = file_get_contents($plist);
        $plist_content = str_replace('__URL__', $ipa_url, $plist_content);
        
        if ($image) {
            $image_url =
                dirname($protocol."://".$_SERVER['SERVER_NAME'].':'.$_SERVER["SERVER_PORT"].$_SERVER['REQUEST_URI']) . '/' .
                $bundleidentifier . '/' . basename($image);
            $imagedict = "<dict><key>kind</key><string>display-image</string><key>needs-shine</key><false/><key>url</key><string>".$image_url."</string></dict></array>";
            $insertpos = strpos($plist_content, '</array>');
            $plist_content = substr_replace($plist_content, $imagedict, $insertpos, 8);
        }

        header('content-type: application/xml');
        echo $plist_content;
    }

    protected function deliverIOSIPA($filename)
    {
        // send the ipa iOS application file
        header('Content-Disposition: attachment; filename=' . urlencode(basename($filename)));
        header('Content-Type: application/octet-stream');
        header('Content-Transfer-Encoding: binary');
        header('Content-Length: '.filesize($filename)."\n");
        readfile_chunked($filename);
    }
    
    protected function deliverAndroidAPK($filename)
    {
        // send apk android application file
        header('Content-Disposition: attachment; filename=' . urlencode(basename($filename)));
        header('Content-Type: application/octet-stream');
        header('Content-Transfer-Encoding: binary');
        header('Content-Length: '.filesize($filename)."\n");
        readfile_chunked($filename);
    }
    
    protected function deliverAuthenticationResponse($bundleidentifier)
    {
        // did we get any user data?
        $udid = isset($_GET[self::CLIENT_KEY_UDID]) ? $_GET[self::CLIENT_KEY_UDID] : null;
        $appversion = isset($_GET[self::CLIENT_KEY_APPVERSION]) ? $_GET[self::CLIENT_KEY_APPVERSION] : "";
        
        // check if the UDID is allowed to be used
        $filename = $this->appDirectory."stats/".$bundleidentifier;

        $this->json[self::RETURN_V2_AUTHCODE] = self::RETURN_V2_AUTH_FAILED;

        $userlistfilename = $this->appDirectory.self::FILE_USERLIST;
    
        if (file_exists($filename)) {
            $userlist = @file_get_contents($userlistfilename);
            
            $lines = explode("\n", $userlist);

            foreach ($lines as $i => $line) :
                if ($line == "") continue;
                
                $device = explode(";", $line);
                
                if (count($device) > 0) {
                    // is this the same device?
                    if ($device[0] == $udid) {
                        $this->json[self::RETURN_V2_AUTHCODE] = md5(HOCKEY_AUTH_SECRET . $appversion. $bundleidentifier . $udid);
                        break;
                    }
                }
            endforeach;                
        }
        
        return $this->sendJSONAndExit();
    }
    
    protected function checkProtectedVersion($restrict)
    {
        $allowed = false;
        
        $allowedTeams = @file_get_contents($restrict);
        if (strlen($allowedTeams) == 0) return true;
        $allowedTeams = explode(",", $allowedTeams);
        
        $udid = isset($_GET[self::CLIENT_KEY_UDID]) ? $_GET[self::CLIENT_KEY_UDID] : null;
        if ($udid) {
            // now get the current user statistics
            $userlist =  "";

            $userlistfilename = $this->appDirectory.self::FILE_USERLIST;
            $userlist = @file_get_contents($userlistfilename);
            $assignedTeams = $this->mapTeam($udid, $userlist);
            if (strlen($assignedTeams) > 0) {
                $teams = explode(",", $assignedTeams);
                foreach ($teams as $team) {
                    if (in_array($team, $allowedTeams)) {
                        $allowed = true;
                        break;
                    }
                }
            }
        }
        
        return $allowed;
    }
    
    protected function getApplicationVersions($bundleidentifier)
    {
        $files = array();
        
        $language = isset($_GET[self::CLIENT_KEY_LANGUAGE]) ? strtolower($_GET[self::CLIENT_KEY_LANGUAGE]) : "";
        
        // iOS
        $ipa        = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_IOS_IPA));
        $plist      = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_IOS_PLIST));
        $profile    = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_IOS_PROFILE));

        // Android
        $apk        = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_ANDROID_APK));
        $json       = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_ANDROID_JSON));

        // Common
        if ($language != "") {
            $note   = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_COMMON_NOTES . '.' . $language));
        }
        if (!$note) {
            $note   = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_COMMON_NOTES));   // the default language file should not have a language extension, so if en is default, never creaete a .html.en file!
        }
        $icon       = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_COMMON_ICON));
        
        $allVersions = array();
        
        if ((!$ipa || !$plist) && 
            (!$apk || !$json)) {
            // check if any are available in a subdirectory
            
            $subDirs = array();
            if ($handleSub = opendir($this->appDirectory . $bundleidentifier)) {
                while (($fileSub = readdir($handleSub)) !== false) {
                    if (!in_array($fileSub, array('.', '..')) && 
                        is_dir($this->appDirectory . $bundleidentifier . '/'. $fileSub)) {
                        array_push($subDirs, $fileSub);
                    }
                }
                closedir($handleSub);
            }

            // Sort the files and display
            rsort($subDirs);
            
            if (count($subDirs) > 0) {
                foreach ($subDirs as $subDir) {
                    // iOS
                    $ipa        = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_IOS_IPA));             // this file could be in a subdirectory per version
                    $plist      = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_IOS_PLIST));           // this file could be in a subdirectory per version
                    
                    // Android
                    $apk        = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_ANDROID_APK));         // this file could be in a subdirectory per version
                    $json       = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_ANDROID_JSON));        // this file could be in a subdirectory per version
                    
                    // Common
                    unset($note);                                                                                                                   // this file could be in a subdirectory per version                    
                    if ($language != "") {
                        $note   = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_COMMON_NOTES . '.' . $language));
                    }
                    if (!$note) {
                        $note   = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_COMMON_NOTES));
                    }
                    $restrict   = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_VERSION_RESTRICT));    // this file defines the teams allowed to access this version
                                        
                    if ($ipa && $plist) {
                        $version = array();
                        $version[self::FILE_IOS_IPA] = $ipa;
                        $version[self::FILE_IOS_PLIST] = $plist;
                        $version[self::FILE_COMMON_NOTES] = $note;
                        $version[self::FILE_VERSION_RESTRICT] = $restrict;
                        
                        // if this is a restricted version, check if the UDID is provided and allowed
                        if ($restrict && !$this->checkProtectedVersion($restrict)) {
                            continue;
                        }
                        
                        $allVersions[$subDir] = $version;
                    } else if ($apk && $json) {
                        $version = array();
                        $version[self::FILE_ANDROID_APK] = $apk;
                        $version[self::FILE_ANDROID_JSON] = $json;
                        $version[self::FILE_COMMON_NOTES] = $note;
                        $allVersions[$subDir] = $version;
                    }
                }
                if (count($allVersions) > 0) {
                    $files[self::VERSIONS_SPECIFIC_DATA] = $allVersions;
                    $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE] = $profile;
                    $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON] = $icon;
                }
            }
        } else {
            $version = array();
            if ($ipa && $plist) {
                $version[self::FILE_IOS_IPA] = $ipa;
                $version[self::FILE_IOS_PLIST] = $plist;
                $version[self::FILE_COMMON_NOTES] = $note;
                $allVersions[] = $version;
                $files[self::VERSIONS_SPECIFIC_DATA] = $allVersions;
                $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON] = $icon;
            } else if ($apk && $json) {
                $version[self::FILE_ANDROID_APK] = $apk;
                $version[self::FILE_ANDROID_JSON] = $json;
                $version[self::FILE_COMMON_NOTES] = $note;
                $allVersions[] = $version;
                $files[self::VERSIONS_SPECIFIC_DATA] = $allVersions;
                $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON] = $icon;
            }
        }
        return $files;
    }
    
    protected function deliver($bundleidentifier, $api, $type)
    {
        $files = $this->getApplicationVersions($bundleidentifier);

        if (count($files) == 0) {
            $this->json = array(self::RETURN_RESULT => -1);
            return $this->sendJSONAndExit();
        }
                        
        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $ipa = $current[self::FILE_IOS_IPA];
        $plist = $current[self::FILE_IOS_PLIST];
        $apk = $current[self::FILE_ANDROID_APK];
        $json = $current[self::FILE_ANDROID_JSON];
        $note = $current[self::FILE_COMMON_NOTES];

        $profile = $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE];
        $image = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];
        
        // notes file is optional, other files are required
        if ((!$ipa || !$plist) && 
            (!$apk || !$json)) {
            $this->json = array(self::RETURN_RESULT => -1);
            return $this->sendJSONAndExit();
        }
        
        $this->addStats($bundleidentifier);
        
        if (!$type) {
            // the client requested the current available updates
            $this->deliverJSON($api, $files);
        } else if ($type == self::TYPE_PROFILE) {
            $this->deliverIOSProfile($appDirectory . $profile);
        } else if ($type == self::TYPE_APP) {
            $this->deliverIOSAppPlist($bundleidentifier, $ipa, $plist, $image);
        } else if ($type == self::TYPE_IPA) {
            $this->deliverIOSIPA($appDirectory . $ipa);
        } else if ($type == self::TYPE_APK) {
            $this->deliverAndroidAPK($appDirectory . $apk);//TODO
        } else if ($type == self::TYPE_AUTH && $api != self::API_V1 && $udid && $appversion) {
            // handle authentication request
            $this->deliverAuthenticationResponse($bundleidentifier);
        }

        exit();
    }
    
    protected function sendJSONAndExit()
    {
        
        ob_end_clean();
        header('Content-type: application/json');
        print json_encode($this->json);
        exit();
    }
    
    protected function findPublicVersion($files)
    {
        $publicVersion = array();
        
        foreach ($files as $version => $fileSet) {
            // since it is currently only supported on iOS, make it fix
            $ipa = $fileSet[self::FILE_IOS_IPA];
            $plist = $fileSet[self::FILE_IOS_PLIST];
            $apk = $current[self::FILE_ANDROID_APK];
            $json = $current[self::FILE_ANDROID_JSON];
            $restrict = $fileSet[self::FILE_VERSION_RESTRICT];
            
            if ($apk) {
                $publicVersion = $fileSet;
                break;
            }
            
            if ($ipa && $restrict && strlen(file_get_contents($restrict)) > 0) {
                continue;
            }
            
            $publicVersion = $fileSet;
            break;
        }
        
        return $publicVersion;
    }
    
    protected function show($appBundleIdentifier)
    {
        // first get all the subdirectories, which do not have a file named "private" present
        if ($handle = opendir($this->appDirectory)) {
            while (($file = readdir($handle)) !== false) {
                if (in_array($file, array('.', '..')) || !is_dir($this->appDirectory . $file) || (glob($this->appDirectory . $file . '/private') && !$appBundleIdentifier)) {
                    // skip if not a directory or has `private` file
                    // but only if no bundle identifier is provided to this function
                    continue;
                }
                
                // if a bundle identifier is provided and the directory does not match, continue
                if ($appBundleIdentifier && $file != $appBundleIdentifier) {
                    continue;
                }

                // now check if this directory has the 3 mandatory files
                
                $files = $this->getApplicationVersions($file);
                
                if (count($files) == 0) {
                    continue;
                }
                
                $current = $this->findPublicVersion($files[self::VERSIONS_SPECIFIC_DATA]);
//                $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
                $ipa = $current[self::FILE_IOS_IPA];
                $plist = $current[self::FILE_IOS_PLIST];
                $apk = $current[self::FILE_ANDROID_APK];
                $json = $current[self::FILE_ANDROID_JSON];
                $note = $current[self::FILE_COMMON_NOTES];
                $restrict = $current[self::FILE_VERSION_RESTRICT];
                
                $profile = $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE];
                $image = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];

                if (!$ipa && !$apk) {
                    continue;
                }

                // if this app version has any restrictions, don't show it on the web interface!
                // we make it easy for now and do not check if the data makes sense and has users assigned to the defined team names
                if ($restrict && strlen(file_get_contents($restrict)) > 0) {
                    $current = $this->findPublicVersion($files);
                }
                
                $newApp = array();

                $newApp[self::INDEX_DIR]            = $file;
                $newApp[self::INDEX_IMAGE]          = substr($image, strpos($image, $file));
                $newApp[self::INDEX_NOTES]          = $note ? nl2br_skip_html(file_get_contents($note)) : '';
                $newApp[self::INDEX_STATS]          = array();

                if ($ipa) {
                    // iOS application
                    $plistDocument = new DOMDocument();
                    $plistDocument->load($plist);
                    $parsed_plist = parsePlist($plistDocument);

                    // now get the application name from the plist
                    $newApp[self::INDEX_APP]            = $parsed_plist['items'][0]['metadata']['title'];
                    if ($parsed_plist['items'][0]['metadata']['subtitle'])
                        $newApp[self::INDEX_SUBTITLE]   = $parsed_plist['items'][0]['metadata']['subtitle'];
                    $newApp[self::INDEX_VERSION]        = $parsed_plist['items'][0]['metadata']['bundle-version'];
                    $newApp[self::INDEX_DATE]           = filectime($ipa);
                
                    if ($provisioningProfile) {
                        $newApp[self::INDEX_PROFILE]        = $provisioningProfile;
                        $newApp[self::INDEX_PROFILE_UPDATE] = filectime($provisioningProfile);
                    }
                    $newApp[self::INDEX_PLATFORM]       = self::APP_PLATFORM_IOS;
                    
                } else if ($apk) {
                    // Android Application
                    
                    // parse the json file
                    $parsed_json = json_decode(file_get_contents($json), true);

                    // now get the application name from the json file
                    $newApp[self::INDEX_APP]        = $parsed_json['title'];
                    $newApp[self::INDEX_SUBTITLE]   = $parsed_json['versionName'];
                    $newApp[self::INDEX_VERSION]    = $parsed_json['versionCode'];                    
                    $newApp[self::INDEX_DATE]       = filectime($apk);                
                    $newApp[self::INDEX_PLATFORM]   = self::APP_PLATFORM_ANDROID;
                }
                
                // now get the current user statistics
                $userlist =  "";

                $filename = $this->appDirectory."stats/".$file;
                $userlistfilename = $this->appDirectory.self::FILE_USERLIST;
        
                if (file_exists($filename)) {
                    $userlist = @file_get_contents($userlistfilename);
                
                    $content = file_get_contents($filename);
                    $lines = explode("\n", $content);

                    foreach ($lines as $i => $line) :
                        if ($line == "") continue;
                    
                        $device = explode(";;", $line);
                    
                        $newdevice = array();

                        $newdevice[self::DEVICE_USER] = $this->mapUser($device[0], $userlist);
                        $newdevice[self::DEVICE_PLATFORM] = $this->mapPlatform($device[1]);
                        $newdevice[self::DEVICE_OSVERSION] = $device[2];
                        $newdevice[self::DEVICE_APPVERSION] = $device[3];
                        $newdevice[self::DEVICE_LASTCHECK] = $device[4];
                        $newdevice[self::DEVICE_LANGUAGE] = $device[5];
                    
                        $newApp[self::INDEX_STATS][] = $newdevice;
                        endforeach;
                
                    // sort by app version
                    $newApp[self::INDEX_STATS] = self::array_orderby($newApp[self::INDEX_STATS], self::DEVICE_APPVERSION, SORT_DESC, self::DEVICE_OSVERSION, SORT_DESC, self::DEVICE_PLATFORM, SORT_ASC, self::DEVICE_LASTCHECK, SORT_DESC);
                }
            
                // add it to the array
                $this->applications[] = $newApp;
            }
            closedir($handle);
        }
    }
}


?>
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

date_default_timezone_set('UTC');

require('plist.inc');
require_once('config.inc');
require_once('helper.php');
require_once('logger.php');
require_once('router.php');
require_once('devicedetector.php');

class AppUpdater
{
    // define the API V1 paramater keys (only the parameters that differ from V2, iOS only)
    const PARAM_1_TYPE          = 'type';
    const PARAM_1_IDENTIFIER    = 'bundleidentifier';
    const PARAM_1_DEVICE        = 'platform';
    const PARAM_1_APP_VERSION   = 'version';
    const PARAM_1_OS_VERSION    = 'ios';
    
    // define URL type parameter values
    const PARAM_1_TYPE_VALUE_PROFILE    = 'profile';
    const PARAM_1_TYPE_VALUE_APP        = 'app';
    const PARAM_1_TYPE_VALUE_IPA        = 'ipa';

    // define the API V2 paramater keys
    const PARAM_2_IDENTIFIER    = 'bundleidentifier';
    const PARAM_2_FORMAT        = 'format';
    const PARAM_2_UDID          = 'udid';                   // iOS client only
    const PARAM_2_DEVICE        = 'device';
    const PARAM_2_APP_VERSION   = 'app_version';
    const PARAM_2_OS            = 'os';
    const PARAM_2_OS_VERSION    = 'os_version';
    const PARAM_2_LANGUAGE      = 'lang';
    const PARAM_2_FIRST_START   = 'first_start_at';
    const PARAM_2_USAGE_TIME    = 'usage_time';
    const PARAM_2_AUTHORIZE     = 'authorize';
    
    // define the API V2 paramater values
    const PARAM_2_FORMAT_VALUE_JSON             = 'json';
    const PARAM_2_FORMAT_VALUE_MOBILEPROVISION  = 'mobileprovision';
    const PARAM_2_FORMAT_VALUE_PLIST            = 'plist';
    const PARAM_2_FORMAT_VALUE_IPA              = 'ipa';
    const PARAM_2_FORMAT_VALUE_APK              = 'apk';
    
    const PARAM_2_AUTHORIZE_VALUE_YES           = 'yes';
    const PARAM_2_AUTHORIZE_VALUE_NO            = 'no';
    
    // define the json response format version
    const API_V1 = '1';
    const API_V2 = '2';
    
    // define support app platforms
    const APP_PLATFORM_IOS      = "iOS";
    const APP_PLATFORM_ANDROID  = "Android";
    
    const PLATFORM_IOS      = "ios";
    const PLATFORM_ANDROID  = "android";

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
    const RETURN_V2_APPSIZE         = 'appsize';
    const RETURN_V2_AUTHCODE        = 'authcode';
    const RETURN_V2_MANDATORY       = 'mandatory';

    const RETURN_V2_AUTH_FAILED     = 'FAILED';

    // define keys for the array to keep a list of available beta apps to be displayed in the web interface
    const INDEX_APP             = 'app';
    const INDEX_VERSION         = 'version';
    const INDEX_SUBTITLE        = 'subtitle';
    const INDEX_DATE            = 'date';
    const INDEX_APPSIZE         = 'appsize';
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

    const FILE_VERSION_MANDATORY  = '.mandatory';             // if present in a version subdirectory, defines that version to be mandatory
    const FILE_VERSION_RESTRICT   = '.team';                  // if present in a version subdirectory, defines the teams that do have access, comma separated
    const FILE_USERLIST           = 'stats/userlist.txt';     // defines UDIDs, real names for stats, and comma separated the associated team names
    
    // define version array structure
    const VERSIONS_COMMON_DATA      = 'common';
    const VERSIONS_SPECIFIC_DATA    = 'specific';
    
    // define keys for the array to keep a list of devices installed this app
    const DEVICE_USER           = 'user';
    const DEVICE_PLATFORM       = 'platform';
    const DEVICE_OSVERSION      = 'osversion';
    const DEVICE_APPVERSION     = 'appversion';
    const DEVICE_LANGUAGE       = 'language';
    const DEVICE_LASTCHECK      = 'lastcheck';
    const DEVICE_INSTALLDATE    = 'installdate';
    const DEVICE_USAGETIME      = 'usagetime';

    const CONTENT_TYPE_APK = 'application/vnd.android.package-archive';

    const E_UNKNOWN_PLATFORM  = -1;
    const E_NO_VERSIONS_FOUND = -1;
    const E_FILES_INCOMPLETE  = -1;
    const E_UNKNOWN_API       = -1;
    const E_UNKNOWN_BUNDLE_ID = -1;
    
    const STATS_SEPARATOR = ';;';


    static public function factory($platform = null, $options = null) {
        
        if ($platform) {
            require_once(strtolower("platforms/abstract.php"));
            $included = include_once(strtolower("platforms/$platform.php"));
            if (!$included) {
                Logger::log("unknown platform: $platform");
                Helper::sendJSONAndExit(self::E_UNKNOWN_PLATFORM, $platform);
            }
        }
        $klass = "{$platform}AppUpdater";
        // Logger::log("Factory: Creating $klass");
        return new $klass($options);
    }


    public $appDirectory;
    public $applications = array();

    
    protected function __construct($options) {
        $this->appDirectory = $options['appDirectory'];
        $this->logic = isset($options['logic']) ? $options['logic'] : null;
    }
    
    public function execute($action, $arguments = array()) {
        if (!method_exists($this, $action))
        {
            Router::get()->serve404();
        }
        call_user_func(array($this, $action), $arguments);
    }
    
    protected function index($arguments)
    {
        return $this->show(null);
    }
    
    protected function app($arguments)
    {
        return $this->show($arguments['bundleidentifier']);
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
    
    protected function addStats($bundleidentifier, $format)
    {
        // did we get any user data?
        $osname = Router::arg(self::PARAM_2_OS, 'iOS');

        if ($osname == "Android") {
		    $udid = Router::arg_match(self::PARAM_2_UDID, '/^[0-9a-f]{16}$/i');
	    }
	    else {
		    $udid = Router::arg_match(self::PARAM_2_UDID, '/^[0-9a-f]{40}$/i');
	    }

        if (!$udid || !is_dir($this->appDirectory.'stats/')) {
            return;
        }
        
        $appversion     = Router::arg_variants(array(self::PARAM_2_APP_VERSION, self::PARAM_1_APP_VERSION));
        $osversion      = Router::arg_variants(array(self::PARAM_2_OS_VERSION, self::PARAM_1_OS_VERSION));
        $device         = Router::arg_variants(array(self::PARAM_2_DEVICE, self::PARAM_1_DEVICE));
        $language       = Router::arg(self::PARAM_2_LANGUAGE, '');
        $firststartdate = Router::arg(self::PARAM_2_FIRST_START, '');
        $usagetime      = Router::arg(self::PARAM_2_USAGE_TIME, '');
        
        $thisdevice = array(
            $udid,
            $device,
            $osname.' '.$osversion,
            $appversion,
            date('m/d/Y H:i:s'),
            $language,
            $firststartdate,
            $usagetime);

        $filename = $this->appDirectory."stats/".$bundleidentifier;

        $lines = @file($filename, FILE_IGNORE_NEW_LINES);
        $found = false;
        $lines = $lines ? array_filter(array_map('trim', $lines)) : array();
        foreach ($lines as $i => $line) {
            $device = explode(self::STATS_SEPARATOR, $line);
            
            if (!count($device)) {
                continue;
            }
            // is this the same device?
            if ($device[0] === $udid) {
                $found = true;
                $lines[$i] = join(self::STATS_SEPARATOR, $thisdevice);
                break;
            }
        }
            
        if (!$found) {
            $lines[] = join(self::STATS_SEPARATOR, $thisdevice);
        }

        // write back the updated stats
        if ($lines) {
            if (!@file_put_contents($filename, join("\n", $lines)))
            {
                Logger::log("Stats file not writable: $filename");
            }
        }
    }
    
    protected function checkProtectedVersion($restrict)
    {
        $allowedTeams = array();
        foreach (@file($restrict) as $line) {
            if (preg_match('/^\s*#/', $line)) continue;
            $items = array_filter(array_map('trim', explode(',', $line)));
            $allowedTeams = array_merge($allowedTeams, $items);
        }

        if (!$allowedTeams) return true;

        $udid = Router::arg(self::PARAM_2_UDID);
        if (!$udid) return false;
        
        $users = self::parseUserList();
        if (isset($users[$udid])) {
            return count(array_intersect($users[$udid]['teams'], $allowedTeams)) > 0;
        }
        
        return false;
    }
    
    protected function getApplicationVersions($bundleidentifier, $platform = null)
    {
        $files = array();
        
        $language = Router::arg(self::PARAM_2_LANGUAGE);
        
        // iOS
        $ipa        = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_IOS_IPA));
        $plist      = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_IOS_PLIST));
        $profile    = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_IOS_PROFILE));

        // Android
        $apk        = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_ANDROID_APK));
        $json       = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*' . self::FILE_ANDROID_JSON));
        
        $note = '';
        // Common
        if ($language) {
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
            usort($subDirs, array($this, 'sort_versions'));
            
            if (count($subDirs) > 0) {
                foreach ($subDirs as $subDir) {
                    // iOS
                    $ipa        = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_IOS_IPA));             // this file could be in a subdirectory per version
                    $plist      = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_IOS_PLIST));           // this file could be in a subdirectory per version
                    
                    // Android
                    $apk        = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_ANDROID_APK));         // this file could be in a subdirectory per version
                    $json       = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_ANDROID_JSON));        // this file could be in a subdirectory per version
                    
                    // Common
                    $note = '';                                                                                                                   // this file could be in a subdirectory per version
                    if ($language) {
                        $note   = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_COMMON_NOTES . '.' . $language));
                    }
                    if (!$note) {
                        $note   = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_COMMON_NOTES));
                    }
                    $mandatory  = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_VERSION_MANDATORY));    // this file defines if the version is mandatory
                    $restrict   = @array_shift(glob($this->appDirectory.$bundleidentifier . '/'. $subDir . '/*' . self::FILE_VERSION_RESTRICT));    // this file defines the teams allowed to access this version
                                        
                    if ($ipa && $plist && (!$platform || $platform == self::PLATFORM_IOS)) {
                        $version = array();
                        $version[self::FILE_IOS_IPA] = $ipa;
                        $version[self::FILE_IOS_PLIST] = $plist;
                        $version[self::FILE_COMMON_NOTES] = $note;
                        $version[self::FILE_VERSION_RESTRICT] = $restrict;
                        $version[self::FILE_VERSION_MANDATORY] = $mandatory;
                        
                        // if this is a restricted version, check if the UDID is provided and allowed
                        if ($restrict && !$this->checkProtectedVersion($restrict)) {
                            continue;
                        }
                        
                        $allVersions[$subDir] = $version;
                    } else if ($apk && $json && (!$platform || $platform == self::PLATFORM_ANDROID)) {
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
                $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE] = $profile;
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
    
    protected function deliver($bundleidentifier, $api, $format)
    {
        $files = $this->getApplicationVersions($bundleidentifier);

        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $api $format");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND, $bundleidentifier);
        }
        
        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $ipa   = isset($current[self::FILE_IOS_IPA]) ? $current[self::FILE_IOS_IPA] : null;
        $plist = isset($current[self::FILE_IOS_PLIST]) ? $current[self::FILE_IOS_PLIST] : null;
        $apk   = isset($current[self::FILE_ANDROID_APK]) ? $current[self::FILE_ANDROID_APK] : null;
        $json  = isset($current[self::FILE_ANDROID_JSON]) ? $current[self::FILE_ANDROID_JSON] : null;

        // notes file is optional, other files are required
        if ((!$ipa || !$plist) && 
            (!$apk || !$json)) {
            Logger::log("uncomplete files: $bundleidentifier");
            return Helper::sendJSONAndExit(self::E_FILES_INCOMPLETE, $bundleidentifier);
        }

        $profile = isset($files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE]) ?
            $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE] : null;
        $image = isset($files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON]) ?
            $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON] : null;
        
        $this->addStats($bundleidentifier, $format);
        
        switch ($format) {
            case self::PARAM_2_FORMAT_VALUE_MOBILEPROVISION:
              Helper::sendFile($profile);
              break;
            case self::PARAM_2_FORMAT_VALUE_PLIST:
              $pos = strpos($current[self::FILE_IOS_IPA], $bundleidentifier);
              $ipa_file = substr($current[self::FILE_IOS_IPA], $pos);
              $this->deliverIOSAppPlist($bundleidentifier, $plist, $image, $ipa_file);
              break;
            case self::PARAM_2_FORMAT_VALUE_IPA:
              Helper::sendFile($ipa);
              break;
            case self::PARAM_2_FORMAT_VALUE_APK:
              Helper::sendFile($apk, self::CONTENT_TYPE_APK);
              break;
            default: break;
        }

        exit();
    }
    
    protected function findPublicVersion($files)
    {
        $publicVersion = array();
        
        foreach ($files as $version => $fileSet) {
            if (isset($fileSet[self::FILE_ANDROID_APK])) {
                $publicVersion = $fileSet;
                break;
            }
            
            $restrict = isset($fileSet[self::FILE_VERSION_RESTRICT]) ? $fileSet[self::FILE_VERSION_RESTRICT] : null;
            if (isset($fileSet[self::FILE_IOS_IPA]) && $restrict && filesize($restrict) > 0) {
                continue;
            }
            
            $publicVersion = $fileSet;
            break;
        }
        
        return $publicVersion;
    }
    
    public function show($appBundleIdentifier)
    {
        // first get all the subdirectories, which do not have a file named "private" present
        if ($handle = opendir($this->appDirectory)) {
            while (($file = readdir($handle)) !== false) {
                if (
                  in_array($file, array('.', '..')) ||
                  !is_dir($this->appDirectory . $file) ||
                  (
                    glob($this->appDirectory . $file . '/private') &&
                    !$appBundleIdentifier &&
                    $this->logic != 'stats'
                  )
                )
                {
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
                $ipa      = isset($current[self::FILE_IOS_IPA]) ? $current[self::FILE_IOS_IPA] : null;
                $plist    = isset($current[self::FILE_IOS_PLIST]) ? $current[self::FILE_IOS_PLIST] : null;
                $apk      = isset($current[self::FILE_ANDROID_APK]) ? $current[self::FILE_ANDROID_APK] : null;
                $json     = isset($current[self::FILE_ANDROID_JSON]) ? $current[self::FILE_ANDROID_JSON] : null;
                $note     = isset($current[self::FILE_COMMON_NOTES]) ? $current[self::FILE_COMMON_NOTES] : null;
                $restrict = isset($current[self::FILE_VERSION_RESTRICT]) ? $current[self::FILE_VERSION_RESTRICT] : null;
                
                $profile = isset($files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE]) ?
                    $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE] : null;
                $image = isset($files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON]) ?
                    $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON] : null;

                if (!$ipa && !$apk) {
                    continue;
                }

                // if this app version has any restrictions, don't show it on the web interface!
                // we make it easy for now and do not check if the data makes sense and has users assigned to the defined team names
                if ($restrict && strlen(file_get_contents($restrict)) > 0) {
                    $current = $this->findPublicVersion($files);
                }
                
                $app = $ipa ? $ipa : $apk;

                $newApp = array();
                $newApp['path']            = substr($app, strpos($app, $file));
                $newApp[self::INDEX_DIR]   = $file;
                $newApp[self::INDEX_IMAGE] = substr($image, strpos($image, $file));
                $newApp[self::INDEX_NOTES] = $note ? Helper::nl2br_skip_html(file_get_contents($note)) : '';
                $newApp[self::INDEX_STATS] = array();

                if ($ipa) {
                    // iOS application
                    $plistDocument = new DOMDocument();
                    $plistDocument->load($plist);
                    $parsed_plist = parsePlist($plistDocument);

                    // now get the application name from the plist
                    $newApp[self::INDEX_APP]            = $parsed_plist['items'][0]['metadata']['title'];
                    if (isset($parsed_plist['items'][0]['metadata']['subtitle']) && $parsed_plist['items'][0]['metadata']['subtitle'])
                        $newApp[self::INDEX_SUBTITLE]   = $parsed_plist['items'][0]['metadata']['subtitle'];
                    $newApp[self::INDEX_VERSION]        = $parsed_plist['items'][0]['metadata']['bundle-version'];
                    $newApp[self::INDEX_DATE]           = filectime($ipa);
                    $newApp[self::INDEX_APPSIZE]        = filesize($ipa);
                    
                    if ($profile) {
                        $newApp[self::INDEX_PROFILE]        = $profile;
                        $newApp[self::INDEX_PROFILE_UPDATE] = filectime($profile);
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
                    $newApp[self::INDEX_APPSIZE]    = filesize($apk);
                    $newApp[self::INDEX_PLATFORM]   = self::APP_PLATFORM_ANDROID;

                    if (!isset($newApp[self::INDEX_NOTES])) {
                        $newApp[self::INDEX_NOTES]      = isset($parsed_json['notes']) ? $parsed_json['notes'] : '';
                    }
                }
                
                // now get the current user statistics
                $filename = $this->appDirectory."stats/".$file;
        
                if (file_exists($filename)) {
                    $users = self::parseUserList();
                
                    $lines = @file($filename, FILE_IGNORE_NEW_LINES);
                    foreach ($lines as $i => $line) {
                        if (!$line) continue;
                        
                        $device = explode(self::STATS_SEPARATOR, $line);
                        $device[0] = strtolower($device[0]); // need case-insensitive match
                        $newdevice = array();
                        $newdevice[self::DEVICE_USER]        = isset($users[$device[0]]) ? $users[$device[0]]['name'] : '-';
                        $newdevice[self::DEVICE_PLATFORM]    = Helper::mapPlatform(isset($device[1]) ? $device[1] : null);
                        $newdevice[self::DEVICE_OSVERSION]   = isset($device[2]) ? $device[2] : '';
                        $newdevice[self::DEVICE_APPVERSION]  = isset($device[3]) ? $device[3] : '';
                        $newdevice[self::DEVICE_LASTCHECK]   = isset($device[4]) ? $device[4] : '';
                        $newdevice[self::DEVICE_LANGUAGE]    = isset($device[5]) ? $device[5] : '';
                        $newdevice[self::DEVICE_INSTALLDATE] = isset($device[6]) ? $device[6] : '';
                        $newdevice[self::DEVICE_USAGETIME]   = isset($device[7]) ? $device[7] : '';
                    
                        $newApp[self::INDEX_STATS][] = $newdevice;
                    }
                
                    // sort by app version
                    $newApp[self::INDEX_STATS] = Helper::array_orderby($newApp[self::INDEX_STATS], self::DEVICE_APPVERSION, SORT_DESC, self::DEVICE_OSVERSION, SORT_DESC, self::DEVICE_PLATFORM, SORT_ASC, self::DEVICE_INSTALLDATE, SORT_DESC, self::DEVICE_LASTCHECK, SORT_DESC);
                }
            
                // add it to the array
                $this->applications[] = $newApp;
            }
            closedir($handle);
        }
    }
    
    protected function parseUserList()
    {
        $users = array();
        $userlistfilename = $this->appDirectory.self::FILE_USERLIST;
        
        $lines = @file($userlistfilename);
        if (!$lines)
        {
            return $users;
        }
        foreach ($lines as $line)
        {
            @list($udid, $name, $teams) = explode(";", $line);
            if (!$udid || isset($users[$udid])) continue;
            $udid = strtolower($udid); // could be uppercase
            $teams = array_filter(array_map('trim', explode(',', $teams)));
            $users[$udid] = array(
                'udid'  => $udid,
                'name'  => $name ? $name : '-',
                'teams' => $teams,
            );
        }
            
        return $users;
    }
    
    protected function sort_versions($a, $b)
    {
      return version_compare($a, $b, '<');
    }
}


?>

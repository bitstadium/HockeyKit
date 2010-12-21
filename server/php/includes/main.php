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

function nl2br_skip_html($string)
{
	// remove any carriage returns (Windows)
	$string = str_replace("\r", '', $string);

	// replace any newlines that aren't preceded by a > with a <br />
	$string = preg_replace('/(?<!>)\n/', "<br />\n", $string);

	return $string;
}

class iOSUpdater
{
    // define URL type parameter values
    const TYPE_PROFILE = 'profile';
    const TYPE_APP     = 'app';
    const TYPE_IPA     = 'ipa';
    
    // define keys for the returning json string
    const RETURN_RESULT   = 'result';
    const RETURN_NOTES    = 'notes';
    const RETURN_TITLE    = 'title';
    const RETURN_SUBTITLE = 'subtitle';

    // define keys for the array to keep a list of available beta apps to be displayed in the web interface
    const INDEX_APP            = 'app';
    const INDEX_VERSION        = 'version';
    const INDEX_SUBTITLE       = 'subtitle';
    const INDEX_DATE           = 'date';
    const INDEX_NOTES          = 'notes';
    const INDEX_PROFILE        = 'profile';
    const INDEX_PROFILE_UPDATE = 'profileupdate';
    const INDEX_DIR            = 'dir';
    const INDEX_IMAGE          = 'image';
    const INDEX_STATS          = 'stats';


    // define keys for the array to keep a list of devices installed this app

    const DEVICE_USER       = 'user';
    const DEVICE_PLATFORM   = 'platform';
    const DEVICE_OSVERSION  = 'osversion';
    const DEVICE_APPVERSION = 'appversion';
    const DEVICE_LASTCHECK  = 'lastcheck';

    protected $appDirectory;
    protected $json = array();
    public $applications = array();

    
    function __construct($dir) {
        
        date_default_timezone_set('UTC');

        $this->appDirectory = $dir;

        $bundleidentifier = isset($_GET['bundleidentifier']) ?
            $this->validateDir($_GET['bundleidentifier']) : null;

        $type = isset($_GET['type']) ? $this->validateType($_GET['type']) : null;

        // if (!$bundleidentifier)
        // {
        //     $this->json = array(self::RETURN_RESULT => -1);
        //     return $this->sendJSONAndExit();
        // }
        
        if ($bundleidentifier)
        {
            return $this->deliver($bundleidentifier, $type);
        }
        
        $this->show();
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
        call_user_func_array('array_multisort', $args);
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
        if (in_array($type, array(self::TYPE_PROFILE, self::TYPE_APP, self::TYPE_IPA)))
        {
            return $type;
        }
        return null;
    }
    
    // map a device UDID into a username
    protected function mapUser($user, $userlist)
    {
        $username = $user;
        $lines = explode("\n", $userlist);

        foreach ($lines as $i => $line) :
            if ($line == "") continue;
            
            $userelement = explode(";", $line);

            if (count($userelement) == 2) {
                if ($userelement[0] == $user) {
                    $username = $userelement[1];
                    break;
                }
            }
        endforeach;

        return $username;
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
    
    protected function deliver($bundleidentifier, $type)
    {
        $plist               = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.plist'));
        $ipa                 = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.ipa'));
        $provisioningProfile = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.mobileprovision'));
        $note                = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.html'));
        $image               = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.png'));
        
        // did we get any user data?
        $udid = isset($_GET['udid']) ? $_GET['udid'] : null;
        $appversion = isset($_GET['version']) ? $_GET['version'] : "";
        $osversion = isset($_GET['ios']) ? $_GET['ios'] : "";
        $platform = isset($_GET['platform']) ? $_GET['platform'] : "";
        
        if ($udid) {
            $thisdevice = $udid.";;".$platform.";;".$osversion.";;".$appversion.";;".date("m/d/Y H:i:s");
            $content =  "";

            $filename = $this->appDirectory."stats/".$bundleidentifier;

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
            file_put_contents($filename, $content);
        }

        // notes file is optional, other files are required
        if (!$plist || !$ipa)
        {
            $this->json = array(self::RETURN_RESULT => -1);
            return $this->sendJSONAndExit();
        }

        if (!$type) {
            // check for available updates for the given bundleidentifier
            // and return a JSON string with the result values

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

        } else if ($type == self::TYPE_PROFILE) {

            // send latest profile for the given bundleidentifier
            $filename = $appDirectory  . $provisioningProfile;
            header('Content-Disposition: attachment; filename=' . urlencode(basename($filename)));
            header('Content-Type: application/octet-stream;');
            header('Content-Transfer-Encoding: binary');
            header('Content-Length: '.filesize($filename).";\n");
            readfile($filename);

        } else if ($type == self::TYPE_APP) {

            // send XML with url to app binary file
            $ipa_url =
                dirname("http://".$_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI']) . '/' .
                $bundleidentifier . '/' . basename($ipa);

            $plist_content = file_get_contents($plist);
            $plist_content = str_replace('__URL__', $ipa_url, $plist_content);
            if ($image) {
                $image_url =
                    dirname("http://".$_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI']) . '/' .
                    $bundleidentifier . '/' . basename($image);
                $imagedict = "<dict><key>kind</key><string>display-image</string><key>needs-shine</key><false/><key>url</key><string>".$image_url."</string></dict></array>";
                $insertpos = strpos($plist_content, '</array>');
                $plist_content = substr_replace($plist_content, $imagedict, $insertpos, 8);
            }
            header('content-type: application/xml');
            echo $plist_content;

        } else if ($type == self::TYPE_IPA) {
 
            // send latest profile for the given bundleidentifier
            $filename = $appDirectory  . $ipa;
            header('Content-Disposition: attachment; filename=' . urlencode(basename($filename)));
            header('Content-Type: application/octet-stream;');
            header('Content-Transfer-Encoding: binary');
            header('Content-Length: '.filesize($filename).";\n");
            readfile($filename);
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
    
    protected function show()
    {
        // first get all the subdirectories, which do not have a file named "private" present
        if ($handle = opendir($this->appDirectory)) {
            while (($file = readdir($handle)) !== false) {
                if (in_array($file, array('.', '..')) || !is_dir($this->appDirectory . $file) || glob($this->appDirectory . $file . '/private')) {
                    // skip if not a directory or has `private` file
                    continue;
                }

                // now check if this directory has the 3 mandatory files
                $ipa                 = @array_shift(glob($this->appDirectory.$file . '/*.ipa'));
                $provisioningProfile = @array_shift(glob($this->appDirectory.$file . '/*.mobileprovision'));
                $plist               = @array_shift(glob($this->appDirectory.$file . '/*.plist'));
                $note                = @array_shift(glob($this->appDirectory.$file . '/*.html'));
                $image               = @array_shift(glob($this->appDirectory.$file . '/*.png'));

                if (!$ipa || !$plist) {
                    continue;
                }

                $plistDocument = new DOMDocument();
                $plistDocument->load($plist);
                $parsed_plist = parsePlist($plistDocument);

                $newApp = array();

                // now get the application name from the plist
                $newApp[self::INDEX_APP]            = $parsed_plist['items'][0]['metadata']['title'];
                if ($parsed_plist['items'][0]['metadata']['subtitle'])
                  $newApp[self::INDEX_SUBTITLE]       = $parsed_plist['items'][0]['metadata']['subtitle'];
                $newApp[self::INDEX_VERSION]        = $parsed_plist['items'][0]['metadata']['bundle-version'];
                $newApp[self::INDEX_DATE]           = filectime($ipa);
                $newApp[self::INDEX_DIR]            = $file;
                $newApp[self::INDEX_IMAGE]          = substr($image, strpos($image, $file));
                $newApp[self::INDEX_NOTES]          = $note ? nl2br_skip_html(file_get_contents($note)) : '';
                $newApp[self::INDEX_STATS]          = array();

                if ($provisioningProfile) {
                    $newApp[self::INDEX_PROFILE]        = $provisioningProfile;
                    $newApp[self::INDEX_PROFILE_UPDATE] = filectime($provisioningProfile);
                }
                
                // now get the current user statistics
                $userlist =  "";

                $filename = $this->appDirectory."stats/".$file;
                $userlistfilename = $this->appDirectory."stats/userlist.txt";
            
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
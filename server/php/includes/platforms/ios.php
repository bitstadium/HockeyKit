<?php

/**
* iOS implementation
*/
class iOSAppUpdater extends AbstractAppUpdater
{

    protected function deliverJSON($api, $files)
    {
        // check for available updates for the given bundleidentifier
        // and return a JSON string with the result values

        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $ipa      = isset($current[self::FILE_IOS_IPA]) ? $current[self::FILE_IOS_IPA] : null;
        $plist    = isset($current[self::FILE_IOS_PLIST]) ? $current[self::FILE_IOS_PLIST] : null;
        $note     = isset($current[self::FILE_COMMON_NOTES]) ? $current[self::FILE_COMMON_NOTES] : null;
        
        if ($ipa && $plist) {
            
            // this is an iOS app
            if ($api == self::API_V1) {
                // this is API Version 1
                $result = array();
                
                // parse the plist file
                $plistDocument = new DOMDocument();
                $plistDocument->load($plist);
                $parsed_plist = parsePlist($plistDocument);

                // get the bundle_version which we treat as build number
                $latestversion = $parsed_plist['items'][0]['metadata']['bundle-version'];
                
                // add the latest release notes if available
                if ($note) {
                    $result[self::RETURN_NOTES]     = Helper::nl2br_skip_html(file_get_contents($appDirectory . $note));
                }

                $result[self::RETURN_TITLE]         = $parsed_plist['items'][0]['metadata']['title'];

                if ($parsed_plist['items'][0]['metadata']['subtitle'])
                    $result[self::RETURN_SUBTITLE]  = $parsed_plist['items'][0]['metadata']['subtitle'];

                $result[self::RETURN_RESULT]        = $latestversion;

                return Helper::sendJSONAndExit($result);
            } else {
                // this is API Version 2
                $result = array();
                
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
                        $newAppVersion[self::RETURN_V2_NOTES]           = Helper::nl2br_skip_html(file_get_contents($appDirectory . $note));
                    }

                    $newAppVersion[self::RETURN_V2_TITLE]               = $parsed_plist['items'][0]['metadata']['title'];

                    if ($parsed_plist['items'][0]['metadata']['subtitle'])
                        $newAppVersion[self::RETURN_V2_SHORTVERSION]    = $parsed_plist['items'][0]['metadata']['subtitle'];

                    $newAppVersion[self::RETURN_V2_VERSION]             = $thisVersion;
            
                    $newAppVersion[self::RETURN_V2_TIMESTAMP]           = filectime($appDirectory . $ipa);
                    $newAppVersion[self::RETURN_V2_APPSIZE]             = filesize($appDirectory . $ipa);
                    
                    $result[] = $newAppVersion;
                    
                    // only send the data until the current version if provided
                    if ($appversion == $thisVersion) break;
                }
                return Helper::sendJSONAndExit($result);
            }
        }
        Logger::log("no versions found: ios/deliverJSON");
        return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
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

    protected function deliverAuthenticationResponse($bundleidentifier)
    {
        $result = array();
        // did we get any user data?
        $udid = isset($_GET[self::CLIENT_KEY_UDID]) ? $_GET[self::CLIENT_KEY_UDID] : null;
        $appversion = isset($_GET[self::CLIENT_KEY_APPVERSION]) ? $_GET[self::CLIENT_KEY_APPVERSION] : "";
        
        // check if the UDID is allowed to be used
        $filename = $this->appDirectory."stats/".$bundleidentifier;

        $result[self::RETURN_V2_AUTHCODE] = self::RETURN_V2_AUTH_FAILED;

        $userlistfilename = $this->appDirectory.self::FILE_USERLIST;
    
        if (file_exists($filename)) {
            $userlist = @file_get_contents($userlistfilename);
            
            $lines = explode("\n", $userlist);

            foreach ($lines as $i => $line) {
                if ($line == "") continue;
                
                $device = explode(";", $line);
                
                if (count($device) > 0) {
                    // is this the same device?
                    if ($device[0] == $udid) {
                        $result[self::RETURN_V2_AUTHCODE] = md5(HOCKEY_AUTH_SECRET . $appversion. $bundleidentifier . $udid);
                        break;
                    }
                }
            }
        }
        
        return Helper::sendJSONAndExit($result);
    }
    
    protected function deliver($bundleidentifier, $api, $type)
    {
        $files = $this->getApplicationVersions($bundleidentifier);
        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $api $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }

        $current = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $ipa   = isset($current[self::FILE_IOS_IPA]) ? $current[self::FILE_IOS_IPA] : null;
        $plist = isset($current[self::FILE_IOS_PLIST]) ? $current[self::FILE_IOS_PLIST] : null;

        // notes file is optional, other files are required
        if (!$ipa || !$plist) {
            Logger::log("incomplete files: $bundleidentifier $api $type");
            return Helper::sendJSONAndExit(self::E_FILES_INCOMPLETE);
        }

        $profile = $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE];
        $image = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];
        
        $this->addStats($bundleidentifier);
        
        switch ($type) {
            case self::TYPE_PROFILE: Helper::sendFile($appDirectory . $profile); break;
            case self::TYPE_APP:     $this->deliverIOSAppPlist($bundleidentifier, $ipa, $plist, $image);
            case self::TYPE_IPA:     Helper::sendFile($appDirectory . $ipa); break;
            case self::TYPE_AUTH:
                if ($api != self::API_V1 && $udid && $appversion) {
                    $this->deliverAuthenticationResponse($bundleidentifier);
                } else {
                    // ?
                }
                break;
            default: $this->deliverJSON($api, $files); break;
        }

        exit();
    }
}

?>
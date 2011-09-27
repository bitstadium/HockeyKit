<?php

/**
* iOS implementation
*/
class iOSAppUpdater extends AbstractAppUpdater
{

    protected function status($arguments) {
        $api = self::API_V2;
        $bundleidentifier = $arguments[self::PARAM_2_IDENTIFIER];
        
        $files = $this->getApplicationVersions($bundleidentifier, self::PLATFORM_IOS);
        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }

        $this->addStats($bundleidentifier, null);

        return $this->deliverJSON($api, $files);
    }
    
    protected function download($arguments) {
        $bundleidentifier = $arguments[self::PARAM_2_IDENTIFIER];
        $format           = $arguments[self::PARAM_2_FORMAT];
        
        $files = $this->getApplicationVersions($bundleidentifier, self::PLATFORM_IOS);
        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }

        $dir = array_shift(array_keys($files[self::VERSIONS_SPECIFIC_DATA]));
        $current = $files[self::VERSIONS_SPECIFIC_DATA][$dir];
        
        if ($format == self::PARAM_2_FORMAT_VALUE_PLIST) // || $type == self::PARAM_1_TYPE_VALUE_APP)
        {
            $image = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];
            $file = isset($current[self::FILE_IOS_PLIST]) ? $current[self::FILE_IOS_PLIST] : null;
            
            if (!$file)
            {
                return Router::get()->serve404();
            }

            $pos = strpos($current[self::FILE_IOS_IPA], $bundleidentifier);
            $ipa_file = substr($current[self::FILE_IOS_IPA], $pos);
            self::deliverIOSAppPlist($bundleidentifier, $file, $image, $ipa_file);
            exit();
        }
        elseif ($format == self::PARAM_2_FORMAT_VALUE_MOBILEPROVISION) // || $type == self::PARAM_1_TYPE_VALUE_PROFILE)
        {
            $file = $files[self::VERSIONS_COMMON_DATA][self::FILE_IOS_PROFILE];
            return Helper::sendFile($file);
        }
        elseif ($format == self::PARAM_2_FORMAT_VALUE_IPA) // || $type == self::PARAM_1_TYPE_VALUE_IPA)
        {
            $file = isset($current[self::FILE_IOS_IPA]) ? $current[self::FILE_IOS_IPA] : null;

            if (!$file)
            {
                return Router::get()->serve404();
            }
            
            return Helper::sendFile($file);

//            if ($dir == 0) $dir = ""; else $dir .= '/';
//            @ob_end_clean();
//            header('Location: ' . Router::get()->baseURL.$bundleidentifier.'/'.$dir.basename($file));
        }
        return Router::get()->serve404();
    }
    
    protected function authorize($arguments)
    {
        $bundleidentifier = $arguments[self::PARAM_2_IDENTIFIER];
        
        $files = $this->getApplicationVersions($bundleidentifier, self::PLATFORM_IOS);
        if (count($files) == 0) {
            Logger::log("no versions found: $bundleidentifier $api $type");
            return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
        }

        $udid    = Router::arg_match(self::PARAM_2_UDID, '/^[0-9a-f]{40}$/i');
        $version = Router::arg(self::PARAM_2_APP_VERSION);

        return $this->deliverAuthenticationResponse($bundleidentifier, $udid, $version);
    }
    
    protected function deliverJSON($api, $files)
    {
        // check for available updates for the given bundleidentifier
        // and return a JSON string with the result values

        $current    = current($files[self::VERSIONS_SPECIFIC_DATA]);
        $ipa        = isset($current[self::FILE_IOS_IPA]) ? $current[self::FILE_IOS_IPA] : null;
        $plist      = isset($current[self::FILE_IOS_PLIST]) ? $current[self::FILE_IOS_PLIST] : null;
        $note       = isset($current[self::FILE_COMMON_NOTES]) ? $current[self::FILE_COMMON_NOTES] : null;
        
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
                    $result[self::RETURN_NOTES]     = Helper::nl2br_skip_html(file_get_contents($note));
                }

                $result[self::RETURN_TITLE]         = $parsed_plist['items'][0]['metadata']['title'];

                if (array_key_exists('subtitle', $parsed_plist['items'][0]['metadata']) && $parsed_plist['items'][0]['metadata']['subtitle'])
                    $result[self::RETURN_SUBTITLE]  = $parsed_plist['items'][0]['metadata']['subtitle'];

                $result[self::RETURN_RESULT]        = $latestversion;

                return Helper::sendJSONAndExit($result);
            } else {
                // this is API Version 2
                $result = array();
                
                $appversion = Router::arg(self::PARAM_2_APP_VERSION) != null ? Router::arg(self::PARAM_2_APP_VERSION) : Router::arg(self::PARAM_1_APP_VERSION);
                
                foreach ($files[self::VERSIONS_SPECIFIC_DATA] as $version) {
                    $ipa = $version[self::FILE_IOS_IPA];
                    $plist = $version[self::FILE_IOS_PLIST];
                    $note = $version[self::FILE_COMMON_NOTES];
                    $mandatory  = isset($version[self::FILE_VERSION_MANDATORY]) ? $version[self::FILE_VERSION_MANDATORY] : null;
                    
                    // parse the plist file
                    $plistDocument = new DOMDocument();
                    $plistDocument->load($plist);
                    $parsed_plist = parsePlist($plistDocument);

                    // get the bundle_version which we treat as build number
                    $thisVersion = $parsed_plist['items'][0]['metadata']['bundle-version'];
                    
                    $newAppVersion = array();
                    // add the latest release notes if available
                    if ($note) {
                        $newAppVersion[self::RETURN_V2_NOTES]           = Helper::nl2br_skip_html(file_get_contents($note));
                    }
                    
                    if ($mandatory) {
                        $newAppVersion[self::RETURN_V2_MANDATORY]       = true;
                    } else {
                        $newAppVersion[self::RETURN_V2_MANDATORY]       = false;
                    }

                    $newAppVersion[self::RETURN_V2_TITLE]               = $parsed_plist['items'][0]['metadata']['title'];

                    if (array_key_exists('subtitle', $parsed_plist['items'][0]['metadata']) && $parsed_plist['items'][0]['metadata']['subtitle'])
                        $newAppVersion[self::RETURN_V2_SHORTVERSION]    = $parsed_plist['items'][0]['metadata']['subtitle'];

                    $newAppVersion[self::RETURN_V2_VERSION]             = $thisVersion;
            
                    $newAppVersion[self::RETURN_V2_TIMESTAMP]           = filectime($ipa);
                    $newAppVersion[self::RETURN_V2_APPSIZE]             = filesize($ipa);
                    
                    $result[] = $newAppVersion;
                }
                return Helper::sendJSONAndExit($result);
            }
        }
        Logger::log("no versions found: ios/deliverJSON");
        return Helper::sendJSONAndExit(self::E_NO_VERSIONS_FOUND);
    }

    static protected function deliverIOSAppPlist($bundleidentifier, $plist, $image, $ipa_file)
    {
        $r = Router::get();
        $udid = Router::arg_match(self::PARAM_2_UDID, '/^[0-9a-f]{40}$/i');
        // send XML with url to app binary file
        $ipa_url = "<![CDATA[{$r->baseURL}{$ipa_file}]]>";

        $plist_content = file_get_contents($plist);
        $plist_content = str_replace('__URL__', $ipa_url, $plist_content);
        
        if ($image) {
            $image_url = $r->baseURL . $bundleidentifier . '/' . basename($image);
            $imagedict = <<<XML
        <dict>
                            <key>kind</key>
                            <string>display-image</string>
                            <key>needs-shine</key>
                            <false/>
                            <key>url</key>
                            <string>$image_url</string>
                        </dict>
                </array>
XML;
            $insertpos = strpos($plist_content, '</array>');
            $plist_content = substr_replace($plist_content, $imagedict, $insertpos, 8);
        }

        header('content-type: application/xml');
        echo $plist_content;
    }

    protected function deliverAuthenticationResponse($bundleidentifier = null, $udid = null, $appversion = null)
    {
        $result[self::RETURN_V2_AUTHCODE] = self::RETURN_V2_AUTH_FAILED;
        if (!$bundleidentifier)
        {
            return Helper::sendJSONAndExit($result);
        }
        
        $users = self::parseUserList();
        if (isset($users[$udid]))
        {
            $result[self::RETURN_V2_AUTHCODE] = md5(HOCKEY_AUTH_SECRET . $appversion. $bundleidentifier . $udid);
        }
        
        return Helper::sendJSONAndExit($result);
    }
    
    public function deliver($bundleidentifier, $api, $format)
    {
        $files = $this->getApplicationVersions($bundleidentifier, self::PLATFORM_IOS);
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
        $image   = $files[self::VERSIONS_COMMON_DATA][self::FILE_COMMON_ICON];

        $udid       = Router::arg(self::PARAM_2_UDID);
        $appversion = Router::arg(self::PARAM_2_APP_VERSION) != null ? Router::arg(self::PARAM_2_APP_VERSION) : Router::arg(self::PARAM_1_APP_VERSION);

        $this->addStats($bundleidentifier, null);
        switch ($format) {
            case self::PARAM_2_FORMAT_VALUE_MOBILEPROVISION:
              Helper::sendFile($profile);
              break;
            case self::PARAM_2_FORMAT_VALUE_PLIST:
              $pos = strpos($current[self::FILE_IOS_IPA], $bundleidentifier);
              $ipa_file = substr($current[self::FILE_IOS_IPA], $pos);
              self::deliverIOSAppPlist($bundleidentifier, $plist, $image, $ipa_file);
              break;
            case self::PARAM_2_FORMAT_VALUE_IPA:
              Helper::sendFile($ipa);
              break;
/*
            case self::TYPE_AUTH:
                if ($api != self::API_V1 && $udid && $appversion) {
                    $this->deliverAuthenticationResponse($bundleidentifier, $udid, $appversion);
                } else {
                    $this->deliverAuthenticationResponse();
                }
                break;
*/
            default:
              $this->deliverJSON($api, $files);
              break;
        }

        exit();
    }
}

?>
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

class iOSUpdater
{
    // define URL type parameter values
    const TYPE_PROFILE = 'profile';
    const TYPE_APP     = 'app';
    
    // define keys for the returning json string
    const RETURN_RESULT   = 'result';
    const RETURN_NOTES    = 'notes';
    const RETURN_PROFILE  = 'profile';
    const RETURN_TITLE    = 'title';
    const RETURN_SUBTITLE = 'subtitle';

    // define keys for the array to keep a list of available beta apps to be displayed in the web interface
    const INDEX_APP            = 'app';
    const INDEX_VERSION        = 'version';
    const INDEX_NOTES          = 'notes';
    const INDEX_PROFILE        = 'profile';
    const INDEX_PROFILE_UPDATE = 'profileupdate';
    const INDEX_DIR            = 'dir';


    protected $appDirectory;
    protected $json = array();
    public $applications = array();

    
    function __construct($dir) {
        
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
        if (in_array($type, array(self::TYPE_PROFILE, self::TYPE_APP)))
        {
            return $type;
        }
        return null;
    }
    
    protected function deliver($bundleidentifier, $type)
    {
        $plist               = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.plist'));
        $ipa                 = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.ipa'));
        $provisioningProfile = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.mobileprovision'));
        $note                = @array_shift(glob($this->appDirectory.$bundleidentifier . '/*.html'));

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
                $this->json[self::RETURN_NOTES] = file_get_contents($appDirectory . $note);
            }

            if ($provisioningProfile)
                $this->json[self::RETURN_PROFILE] = filectime($appDirectory . $provisioningProfile);
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
            header('content-type: application/xml');
            echo str_replace('__URL__', $ipa_url, $plist_content);

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
                if (in_array($file, array('.', '..')) || !is_dir($file) || glob($file . '/private')) {
                    // skip if not a directory or has `private` file
                    continue;
                }

                // now check if this directory has the 3 mandatory files
                $ipa                 = @array_shift(glob($file . '/*.ipa'));
                $provisioningProfile = @array_shift(glob($file . '/*.mobileprovision'));
                $plist               = @array_shift(glob($file . '/*.plist'));
                $note                = @array_shift(glob($file . '/*.html'));

                if (!$ipa || !$plist) {
                    continue;
                }

                $plistDocument = new DOMDocument();
                $plistDocument->load($plist);
                $parsed_plist = parsePlist($plistDocument);

                $newApp = array();

                // now get the application name from the plist
                $newApp[self::INDEX_APP]            = $parsed_plist['items'][0]['metadata']['title'];
                $newApp[self::INDEX_VERSION]        = $parsed_plist['items'][0]['metadata']['bundle-version'];
                $newApp[self::INDEX_DIR]            = $file;
                $newApp[self::INDEX_NOTES]          = $note ? nl2br(file_get_contents($note)) : '';

                if ($provisioningProfile) {
                    $newApp[self::INDEX_PROFILE]        = $provisioningProfile;
                    $newApp[self::INDEX_PROFILE_UPDATE] = filectime($this->appDirectory . $provisioningProfile);
                }
                
                // add it to the array
                $this->applications[] = $newApp;
            }
            closedir($handle);
        }
    }
}


?>
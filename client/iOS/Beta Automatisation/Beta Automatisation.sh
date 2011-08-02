#!/bin/sh

# This has to match the name of the configuration you use for Ad-Hoc builds!
adHocConfigurationName="Ad Hoc"
adHocCertificate="iPhone Distribution: Your Name Here"
provisioningProfilePath="/Users/yourname/Library/MobileDevice/Provisioning Profiles/profile.mobileprovision"

executableName="Your Application"
bundleDisplayName="Your Application"

archiveDirectoryPath="${PROJECT_DIR}/Releases/Beta";
dropboxDistributionDirectoryPath="/users/myusername/Dropbox/My Application Beta";

uploadMethod="scp"

secretSubDirStart='cdgj';

ftpUsername="username"
ftpPassword="password"
ftpServerDirectoryPath="my-cool-server.com/httpdocs/beta"

scpUser="username"
scpHost="yourhost.com"
scpPath="/path/to/app"

applicationPath="${CONFIGURATION_BUILD_DIR}/$executableName.app"

if [[ "${EFFECTIVE_PLATFORM_NAME}" == "-iphoneos" && "${BUILD_STYLE}" == $adHocConfigurationName && -e $applicationPath ]]
then
    bundleVersion=$(defaults read "$applicationPath/Info" CFBundleVersion)
    bundleIdentifier=$(defaults read "$applicationPath/Info" CFBundleIdentifier)
    bundleShortVersionString=$(defaults read "$applicationPath/Info" CFBundleShortVersionString)
    
    # Zip the app and dSYM
    zipPath="${CONFIGURATION_BUILD_DIR}/$executableName $bundleVersion.zip"
    
    zip -qr "${CONFIGURATION_BUILD_DIR}/$executableName $bundleVersion.zip" . -i ${CONFIGURATION_BUILD_DIR}/$executableName.app ${CONFIGURATION_BUILD_DIR}/$executableName.app.dSYM
    
    # Move new archive
    if !([ -e "$archiveDirectoryPath/$bundleIdentifier $bundleVersion.zip" ])
    then
        mv "$zipPath" "$archiveDirectoryPath";
    fi
    
    cd "${CONFIGURATION_BUILD_DIR}"

    # Archive the application for Ad-Hoc distribution
    /usr/bin/xcrun -sdk iphoneos PackageApplication "$executableName.app" -o "${CONFIGURATION_BUILD_DIR}/$executableName.ipa" --sign "$adHocCertificate" --embed "$provisioningProfilePath"
    
    # Generate .plist file for wireless app distribution
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
         <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
         <plist version=\"1.0\">
         <dict>
            <key>items</key>
            <array>
                <dict>
                    <key>assets</key>
                    <array>
                        <dict>
                            <key>kind</key>
                            <string>software-package</string>
                            <key>url</key>
                            <string>__URL__</string>
                        </dict>
                    </array>
                    <key>metadata</key>
                    <dict>
                        <key>bundle-identifier</key>
                        <string>$bundleIdentifier</string>
                        <key>bundle-version</key>
                        <string>$bundleVersion</string>
                        <key>kind</key>
                        <string>software</string>
                        <key>title</key>
                        <string>$bundleDisplayName</string>
                        <key>subtitle</key>
                        <string>$bundleShortVersionString</string>
                    </dict>
                </dict>
            </array>
         </dict>
         </plist>" > "${CONFIGURATION_BUILD_DIR}/$executableName.plist";
    
    # Move the archived application to Dropbox
    cp "$executableName.ipa" "$dropboxDistributionDirectoryPath/$executableName.ipa";
    
    # Open Terminal and upload the .ipa and .plist files
    if ([ "$uploadMethod" == "ftp" ])
    then
        echo "Uploading $executableName.ipa and $executableName.plist to $ftpServerDirectoryPath...";
        
        /usr/bin/osascript <<-EOF           
on isApplicationRunning(application)
tell application "System Events" to (name of processes) contains application
end isApplicationRunning

if not (isApplicationRunning("Terminal")) then
tell application "Terminal"
    launch
    close window 1
end tell
end if

tell application "Terminal"
do script with command "curl -T \"${CONFIGURATION_BUILD_DIR}/$executableName.ipa\" -u $ftpUsername:$ftpPassword \"ftp://$ftpServerDirectoryPath/$bundleIdentifier/$executableName.ipa\""
do script with command "curl -T \"${CONFIGURATION_BUILD_DIR}/$executableName.plist\" -u $ftpUsername:$ftpPassword \"ftp://$ftpServerDirectoryPath/$bundleIdentifier/$executableName.plist\""
end tell
EOF
    elif [[ "$uploadMethod" == "scp" ]]
    then
        echo "Uploading $executableName.ipa and $executableName.plist to $scpHost...";
        ssh $scpUser@$scpHost "mkdir $scpPath/$bundleIdentifier/$secretSubDirStart$bundleVersion/"
        scp "${CONFIGURATION_BUILD_DIR}/$executableName.ipa" $scpUser@$scpHost:"$scpPath/$bundleIdentifier/$secretSubDirStart$bundleVersion/"
        scp "${CONFIGURATION_BUILD_DIR}/$executableName.plist" $scpUser@$scpHost:"$scpPath/$bundleIdentifier/$secretSubDirStart$bundleVersion/"
        #scp "${PROJECT_DIR}/../ReleaseNotes.html" $scpUser@$scpHost:"$scpPath/$bundleIdentifier/$secretSubDirStart$bundleVersion/"

    fi
fi

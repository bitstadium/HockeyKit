#!/bin/sh

# This has to match the name of the configuration you use for Ad-Hoc builds!
adHocConfigurationName="Ad-Hoc";

executableName="My Application";
bundleDisplayName="My Application";

symbolicationDirectoryPath="${PROJECT_DIR}/Development/CrashReporter/Symbolication";
dropboxDistributionDirectoryPath="/users/myusername/Dropbox/My Application Beta";

ftpUsername="username";
ftpPassword="password";
ftpServerDirectoryPath="my-cool-server.com/httpdocs/beta";



if ([ "${EFFECTIVE_PLATFORM_NAME}" == "-iphoneos" ])
then
	
	applicationPath="${CONFIGURATION_BUILD_DIR}/$executableName.app";
	bundleVersion=$(defaults read "$applicationPath/Info" CFBundleVersion);
	bundleIdentifier=$(defaults read "$applicationPath/Info" CFBundleIdentifier);
	
	# Move .app file to a secure location
  	if !([ -e "$symbolicationDirectoryPath/$bundleIdentifier $bundleVersion.app" ])
     then

       	cp -r $applicationPath $symbolicationDirectoryPath;
		mv "$symbolicationDirectoryPath/$executableName.app" "$symbolicationDirectoryPath/$bundleIdentifier $bundleVersion.app";
		
     fi

	# Move .app.dSYM file to a secure location
	if !([ -e "$symbolicationDirectoryPath/$bundleIdentifier $bundleVersion.app.dSYM" ])
  	   then

       	cp -r "$applicationPath.dSYM" $symbolicationDirectoryPath;
		mv "$symbolicationDirectoryPath/$executableName.app.dSYM" "$symbolicationDirectoryPath/$bundleIdentifier $bundleVersion.app.dSYM";
		
     fi


	if ([ "${BUILD_STYLE}" == $adHocConfigurationName ])
	then
		cd "${CONFIGURATION_BUILD_DIR}";

		# Archive the application for Ad-Hoc distribution
		mkdir "${CONFIGURATION_BUILD_DIR}/Payload";
		cp -r $applicationPath "${CONFIGURATION_BUILD_DIR}/Payload";
		(zip -qr "$executableName.ipa" Payload);
		rm -rf "${CONFIGURATION_BUILD_DIR}/Payload";
		
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
						</dict>
					</dict>
				</array>
			 </dict>
			 </plist>" > "${CONFIGURATION_BUILD_DIR}/$executableName.plist";
		
		# Move the archived application to Dropbox
		cp "$executableName.ipa" "$dropboxDistributionDirectoryPath/$executableName.ipa";

		# Open Terminal and upload the .ipa and .plist files
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
				do script with command "curl -T \"${CONFIGURATION_BUILD_DIR}/$executableName.ipa\" \"ftp://$ftpUsername:$ftpPassword@$ftpServerDirectoryPath/$bundleIdentifier/$executableName.ipa\""
				do script with command "curl -T \"${CONFIGURATION_BUILD_DIR}/$executableName.plist\" \"ftp://$ftpUsername:$ftpPassword@$ftpServerDirectoryPath/$bundleIdentifier/$executableName.plist\""
			end tell
		EOF

		cd "${PROJECT_DIR}";
	fi
fi

exit 0;
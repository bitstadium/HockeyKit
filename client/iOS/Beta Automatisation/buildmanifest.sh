#!/bin/sh
if [[ $# -eq 0 || $1 == "-?" || $1 == "--help" || ! -f "$1.plist" ]]
then
    echo
    echo "usage: buildmanifest name [output]"
    echo
    echo "  name   : absolute path and filename of the .plist file excluding the file extension"
    echo "  output : the filenane to write the manifest content, default is manifest.plist"
    echo
    echo "  Example: ./buildmanifest ~/SourceCode/Hockey/HockeyDemo-Info"
    echo
    exit
fi

exportFilename="manifest.plist";

if [ $# -eq 2 ]
then
    exportFilename=$2
fi

bundleVersion=$(defaults read "$1" CFBundleVersion)
bundleIdentifier=$(defaults read "$1" CFBundleIdentifier)
bundleShortVersionString=$(defaults read "$1" CFBundleShortVersionString)
    
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
         </plist>" > $exportFilename;
         
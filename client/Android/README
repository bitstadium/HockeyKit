Requirements:
*************

+ ADT Plugin 0.9.7 (or higher)
+ Android 2.2 (or higher); it might work with older SDKs, but we haven't tested it
+ HockeyKit 2 (or higher)

Steps to integrate Hockey into your Android app:
************************************************

1. Import the project in client/Android into Eclipse.

2. Open the properties for your project.

3. Select "Android" in the sidebar.

4. Click "Add.." in the section "Library".

5. Select "Hockey" and confirm with "OK".

6. Close the properties with "OK".

7. The folder "Hockey_src" should appear in your project; if not, restart Eclipse.

8. Open your "AndroidManifest.xml" and add the following line:

  <activity android:name="net.hockeyapp.android.UpdateActivity" />
  
9. Make sure that your app has permissions for the internet and for writing onto the SD card:

  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

10. Open your main activity and the following lines:

import net.hockeyapp.android.CheckUpdateTask;

public class MainActivity extends Activity {
  private CheckUpdateTask checkUpdateTask;

  @Override
  public void onCreate(Bundle savedInstanceState) {
    // Some code to create view
    // ...
    
    // Set icon drawable
    UpdateActivity.iconDrawableId = R.drawable.icon;
    
    // Check for updates
    checkForUpdates();
  }

  private void checkForUpdates() {
    checkUpdateTask = (CheckUpdateTask)getLastNonConfigurationInstance();
    if (checkUpdateTask != null) {
      checkUpdateTask.attach(this);
    }
    else {
      checkUpdateTask = new CheckUpdateTask(this, "YOUR_URL");
      checkUpdateTask.execute();
    }
  }

  @Override
  public Object onRetainNonConfigurationInstance() {
    checkUpdateTask.detach();
    return checkUpdateTask;
  }
  
  // Probably more methods
}    

11. Replace YOUR_URL by your Hockey Server URL.

12. Build your project and create a signed apk.

13. Create a new file info.json with the following content:

{
  "title": "HockeyDemo",
  "versionCode": 23,
  "versionName":"1.0"
}

Replace the value for title with the title of your app and the values for versionCode and versionName with the latest values (maybe it's possible to automate this with Eclipse).

14. Upload both files to the server.

15. Done.

Bugs, Problems, Questions?
**************************

Send us a tweet to @ashtom or @therealkerni.

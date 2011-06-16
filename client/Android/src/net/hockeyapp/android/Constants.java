package net.hockeyapp.android;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;

/**
 * LICENSE INFORMATION
 * 
 * Copyright (c) 2009 nullwire aps
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Contributors:
 * Mads Kristiansen, mads.kristiansen@nullwire.com
 * Glen Humphrey
 * Evan Charlton
 * Peter Hewitt
 * Thomas Dohmke, thomas@dohmke.de
 **/

public class Constants {
  // Since the exception handler doesn't have access to the context,
  // or anything really, the library prepares these values for when
  // the handler needs them.
  public static String FILES_PATH = null;
  public static String APP_VERSION = null;
  public static String APP_PACKAGE = null;
  
  public static String ANDROID_VERSION  = null;
  public static String PHONE_MODEL = null;
  public static String PHONE_MANUFACTURER = null;
  
  public static String TAG = "HockeyApp";

  public static void loadFromContext(Context context) {
    Constants.ANDROID_VERSION = android.os.Build.VERSION.RELEASE;
    Constants.PHONE_MODEL = android.os.Build.MODEL;
    Constants.PHONE_MANUFACTURER = android.os.Build.MANUFACTURER;

    PackageManager packageManager = context.getPackageManager();
    try {
      PackageInfo packageInfo = packageManager.getPackageInfo(context.getPackageName(), 0);
      Constants.APP_VERSION = "" + packageInfo.versionCode;
      Constants.APP_PACKAGE = packageInfo.packageName;
      Constants.FILES_PATH = context.getFilesDir().getAbsolutePath();
    } 
    catch (NameNotFoundException e) {
      e.printStackTrace();
    }
  }
}
package net.hockeyapp.android;

import java.io.BufferedReader;
import java.io.File;
import java.io.FilenameFilter;
import java.io.InputStreamReader;
import java.lang.Thread.UncaughtExceptionHandler;
import java.util.ArrayList;
import java.util.List;

import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.protocol.HTTP;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.util.Log;

public class CrashManager {
  private static String identifier = null;
  private static String urlString = null;

  public static void register(Context context, String urlString, String appIdentifier) {
    CrashManager.urlString = urlString;
    CrashManager.identifier = appIdentifier;

    Constants.loadFromContext(context);
    
    if (CrashManager.identifier == null) {
      CrashManager.identifier = Constants.APP_PACKAGE;
    }

    if (hasStackTraces()) {
      showDialog(context);
    }
    else {
      registerHandler();
    }
  }

  public static void register(Context context, String url) {
    register(context, url, null);
  }

  private static void showDialog(final Context context) {
    if (context == null) {
      return;
    }

    AlertDialog.Builder builder = new AlertDialog.Builder(context);
    builder.setTitle(R.string.crash_dialog_title);
    builder.setMessage(R.string.crash_dialog_message);

    builder.setNegativeButton(R.string.crash_dialog_negative_button, new DialogInterface.OnClickListener() {
      public void onClick(DialogInterface dialog, int which) {
        deleteStackTraces(context);
        registerHandler();
      } 
    });

    builder.setPositiveButton(R.string.crash_dialog_positive_button, new DialogInterface.OnClickListener() {
      public void onClick(DialogInterface dialog, int which) {
        new Thread() {
          @Override
          public void run() {
            submitStackTraces(context);
            registerHandler();
          }
        }.start();
      } 
    });

    builder.create().show();
  }

  public static void registerHandler() {
    // Get current handler
    UncaughtExceptionHandler currentHandler = Thread.getDefaultUncaughtExceptionHandler();
    if (currentHandler != null) {
      Log.d(Constants.TAG, "Current handler class = " + currentHandler.getClass().getName());
    }

    // Register if not already registered
    if (!(currentHandler instanceof ExceptionHandler)) {
      Thread.setDefaultUncaughtExceptionHandler(new ExceptionHandler(currentHandler));
    }
  }

  private static String getURLString() {
    return urlString + "api/2/apps/" + identifier + "/crashes/";      
  }

  public static void deleteStackTraces(Context context) {
    Log.d(Constants.TAG, "Looking for exceptions in: " + Constants.FILES_PATH);
    String[] list = searchForStackTraces();

    if ((list != null) && (list.length > 0)) {
      Log.d(Constants.TAG, "Found " + list.length + " stacktrace(s).");

      for (int index = 0; index < list.length; index++) {
        try {
          Log.d(Constants.TAG, "Delete stacktrace " + list[index] + ".");
          context.deleteFile(list[index]);
        } 
        catch (Exception e) {
          e.printStackTrace();
        }
      }
    }
  }
  
  public static void submitStackTraces(Context context) {
    Log.d(Constants.TAG, "Looking for exceptions in: " + Constants.FILES_PATH);
    String[] list = searchForStackTraces();

    if ((list != null) && (list.length > 0)) {
      Log.d(Constants.TAG, "Found " + list.length + " stacktrace(s).");

      for (int index = 0; index < list.length; index++) {
        try {
          // Read contents of stack trace
          StringBuilder contents = new StringBuilder();
          BufferedReader reader = new BufferedReader(new InputStreamReader(context.openFileInput(list[index])));
          String line = null;
          while ((line = reader.readLine()) != null) {
            contents.append(line);
            contents.append(System.getProperty("line.separator"));
          }
          reader.close();
          String stacktrace = contents.toString();

          // Transmit stack trace with POST request
          Log.d(Constants.TAG, "Transmitting crash data: \n" + stacktrace);
          DefaultHttpClient httpClient = new DefaultHttpClient(); 
          HttpPost httpPost = new HttpPost(getURLString());
          List <NameValuePair> nvps = new ArrayList <NameValuePair>(); 
          nvps.add(new BasicNameValuePair("raw", stacktrace));
          httpPost.setEntity(new UrlEncodedFormEntity(nvps, HTTP.UTF_8)); 
          httpClient.execute(httpPost);                                   
        }
        catch (Exception e) {
          e.printStackTrace();
        } 
        finally {
          try {
            context.deleteFile(list[index]);
          } 
          catch (Exception e) {
            e.printStackTrace();
          }
        }
      }
    }
  } 

  public static boolean hasStackTraces() {
    return (searchForStackTraces().length > 0);
  }

  private static String[] searchForStackTraces() {
    // Try to create the files folder if it doesn't exist
    File dir = new File(Constants.FILES_PATH + "/");
    dir.mkdir();

    // Filter for ".stacktrace" files
    FilenameFilter filter = new FilenameFilter() { 
      public boolean accept(File dir, String name) {
        return name.endsWith(".stacktrace"); 
      } 
    }; 
    return dir.list(filter); 
  }
}

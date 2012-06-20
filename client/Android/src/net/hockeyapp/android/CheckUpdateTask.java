package net.hockeyapp.android;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;

import org.json.JSONArray;
import org.json.JSONObject;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.provider.Settings;

public class CheckUpdateTask extends AsyncTask<String, String, JSONArray>{
  private Activity activity = null;
  private String urlString = null;
  private String appIdentifier = null;
  
  public CheckUpdateTask(Activity activity, String urlString) {
    this.appIdentifier = null;
    this.activity = activity;
    this.urlString = urlString;
    
    Constants.loadFromContext(activity);
  }
  
  public CheckUpdateTask(Activity activity, String urlString, String appIdentifier) {
    this.appIdentifier = appIdentifier;
    this.activity = activity;
    this.urlString = urlString;

    Constants.loadFromContext(activity);
  }
  
  public void attach(Activity activity) {
    this.activity = activity;

    Constants.loadFromContext(activity);
  }
  
  public void detach() {
    activity = null;
  }
  
  @Override
  protected JSONArray doInBackground(String... args) {
    try {
      int versionCode = activity.getPackageManager().getPackageInfo(activity.getPackageName(), PackageManager.GET_META_DATA).versionCode;
      
      URL url = new URL(getURLString("json"));
      URLConnection connection = url.openConnection();
      connection.addRequestProperty("User-Agent", "Hockey/Android");
      connection.setRequestProperty("connection", "close");
      connection.connect();

      InputStream inputStream = new BufferedInputStream(connection.getInputStream());
      String jsonString = convertStreamToString(inputStream);
      inputStream.close();
      
      JSONArray json = new JSONArray(jsonString);
      for (int index = 0; index < json.length(); index++) {
        JSONObject entry = json.getJSONObject(index);
        if (entry.getInt("version") > versionCode) {
          return json;
        }
      }
    }
    catch (Exception e) {
      e.printStackTrace();
    }
    
    return null;
  }

  @Override
  protected void onPostExecute(JSONArray updateInfo) {
    if (updateInfo != null) {
      showDialog(updateInfo);
    }
  }
  
  private String getURLString(String format) {
    StringBuilder builder = new StringBuilder();
    builder.append(urlString);
    builder.append("api/2/apps/");
    builder.append((this.appIdentifier != null ? this.appIdentifier : activity.getPackageName()));
    builder.append("?format=" + format);
    
    String uid = Settings.Secure.getString(activity.getContentResolver(), Settings.Secure.ANDROID_ID);
    if (uid != null) {
    	builder.append("&udid=" + URLEncoder.encode(uid));
    }
    builder.append("&os=Android");
    builder.append("&os_version=" + URLEncoder.encode(Constants.ANDROID_VERSION));
    builder.append("&device=" + URLEncoder.encode(Constants.PHONE_MODEL));
    builder.append("&oem=" + URLEncoder.encode(Constants.PHONE_MANUFACTURER));
    builder.append("&app_version=" + URLEncoder.encode(Constants.APP_VERSION));
    
    return builder.toString();
  }
  
  private void showDialog(final JSONArray updateInfo) {
    if ((activity == null) || (activity.isFinishing())) {
      return;
    }
    
    AlertDialog.Builder builder = new AlertDialog.Builder(activity);
    builder.setTitle(R.string.update_dialog_title);
    builder.setMessage(R.string.update_dialog_message);

    builder.setNegativeButton(R.string.update_dialog_negative_button, new DialogInterface.OnClickListener() {
      public void onClick(DialogInterface dialog, int which) {
      } 
    });
    
    builder.setPositiveButton(R.string.update_dialog_positive_button, new DialogInterface.OnClickListener() {
      public void onClick(DialogInterface dialog, int which) {
        Intent intent = new Intent(activity, UpdateActivity.class);
        intent.putExtra("json", updateInfo.toString());
        intent.putExtra("url", getURLString("apk"));
        activity.startActivity(intent);
      } 
    });
    
    builder.create().show();
  }

  private static String convertStreamToString(InputStream inputStream) {
    BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream), 1024);
    StringBuilder stringBuilder = new StringBuilder();

    String line = null;
    try {
      while ((line = reader.readLine()) != null) {
        stringBuilder.append(line + "\n");
      }
    } 
    catch (IOException e) {
      e.printStackTrace();
    } 
    finally {
      try {
        inputStream.close();
      } 
      catch (IOException e) {
        e.printStackTrace();
      }
    }
    return stringBuilder.toString();
  }
}
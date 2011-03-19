package net.hockeyapp.android;

import java.text.SimpleDateFormat;
import java.util.Date;

import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class UpdateInfoAdapter extends BaseAdapter {
  Activity activity;
  JSONObject info;
  
  public UpdateInfoAdapter(Activity activity, String infoJSON) {
    super();
    
    this.activity = activity;
    try {
      this.info = new JSONObject(infoJSON);
    }
    catch (JSONException e) {
      this.info = new JSONObject();
    }
  }
  
  public int getCount() {
    return 3;
  }

  public Object getItem(int position) {
    String item = null;
    switch (position) {
    case 0:
      item = "Release Notes:";
      break;
    case 1:
      item = failSafeGetStringFromJSON(info, "notes", "");
      break;
    case 2:
      try {
        PackageInfo packageInfo = activity.getPackageManager().getPackageInfo(activity.getPackageName(), PackageManager.GET_META_DATA);
        item = "Installed Version: " + packageInfo.versionName + " (" + packageInfo.versionCode + ")";
      }
      catch (NameNotFoundException e) {
      }
    }
    return item;
  }
  
  public String getVersionString() {
    return failSafeGetStringFromJSON(info, "shortversion", "") + " (" + failSafeGetStringFromJSON(info, "version", "") + ")";
  }
  
  public String getFileInfoString() {
    int appSize = failSafeGetIntFromJSON(info, "appsize", 0);
    long timestamp = failSafeGetIntFromJSON(info, "timestamp", 0);
    Date date = new Date(timestamp * 1000);
    SimpleDateFormat dateFormat = new SimpleDateFormat("dd.MM.yyyy");
    return dateFormat.format(date) + " - " + String.format("%.2f", appSize / 1024F / 1024F) + " MB";
  }
  
  private static String failSafeGetStringFromJSON(JSONObject json, String name, String defaultValue) {
    try {
      return json.getString(name);
    }
    catch (JSONException e) {
      return defaultValue;
    }
  }
  
  private static int failSafeGetIntFromJSON(JSONObject json, String name, int defaultValue) {
    try {
      return json.getInt(name);
    }
    catch (JSONException e) {
      return defaultValue;
    }
  }

  public long getItemId(int position) {
    return new Integer(position).hashCode();
  }

  public View getView(int position, View convertView, ViewGroup parent) {
    switch (position) {
    case 0:
    case 2:
      return getSimleView(position, convertView, parent);
    case 1:
      return getWebView(position, convertView, parent);
    default:
      return null;
    }
  }

  private View getSimleView(int position, View convertView, ViewGroup parent) {
    View row = convertView;
    if (!(row instanceof TextView)) {
      LayoutInflater inflater = activity.getLayoutInflater();
      row = inflater.inflate(android.R.layout.simple_list_item_1, parent, false);
    }
      
    String item = (String)getItem(position);
    
    
    TextView textView = (TextView)row.findViewById(android.R.id.text1);
    float scale = activity.getResources().getDisplayMetrics().density;
    boolean leftPadding = (parent.getTag().equals("right"));
    textView.setPadding((int)(20 * scale) * (leftPadding ? 2 : 1), (int)(20 * scale) * (leftPadding ? 1 : 2), (int)(20 * scale), 0);
    textView.setText(item);
    textView.setTextColor(Color.BLACK);
    
    return row;
  }

  private View getWebView(int position, View convertView, ViewGroup parent) {
    View row = convertView;
    if (row == null) {
      RelativeLayout layout = new RelativeLayout(activity);
      layout.setLayoutParams(new ListView.LayoutParams(ListView.LayoutParams.FILL_PARENT, ListView.LayoutParams.WRAP_CONTENT));
      row = layout;
      
      WebView webView = new WebView(activity);
      webView.setId(1337);
      RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.FILL_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT); 
      float scale = activity.getResources().getDisplayMetrics().density;
      boolean leftPadding = (parent.getTag().equals("right"));
      params.setMargins((int)(20 * scale) * (leftPadding ? 2 : 1), (int)(0 * scale), (int)(20 * scale), 0);
      webView.setLayoutParams(params);
      layout.addView(webView);
    }
      
    String item = (String)getItem(position);
    
    WebView webView = (WebView)row.findViewById(1337);
    webView.loadData(item, "text/html", "utf-8");
    
    return row;
  }
}

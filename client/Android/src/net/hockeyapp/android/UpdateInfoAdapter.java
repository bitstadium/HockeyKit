package net.hockeyapp.android;

import org.json.JSONException;
import org.json.JSONObject;

import android.R;
import android.app.Activity;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;
import android.widget.TwoLineListItem;

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
    return 5;
  }

  public Object getItem(int position) {
    String[] item = new String[2];
    switch (position) {
    case 0:
      item[0] = "Title";
      item[1] = failSafeGetStringFromJSON(info, "title", "");
      break;
    case 1:
      try {
        PackageInfo packageInfo = activity.getPackageManager().getPackageInfo(activity.getPackageName(), PackageManager.GET_META_DATA);
        item[0] = "Package";
        item[1] = packageInfo.packageName;
      }
      catch (NameNotFoundException e) {
      }
      break;
    case 2:
      try {
        PackageInfo packageInfo = activity.getPackageManager().getPackageInfo(activity.getPackageName(), PackageManager.GET_META_DATA);
        item[0] = "Installed Version";
        item[1] = packageInfo.versionName + " (" + packageInfo.versionCode + ")";
      }
      catch (NameNotFoundException e) {
      }
      break;
    case 3:
      item[0] = "Available Version";
      item[1] = failSafeGetStringFromJSON(info, "shortversion", "") + " (" + failSafeGetStringFromJSON(info, "version", "") + ")";
      break;
    case 4:
      item[0] = "Install Update";
      break;
    }
    return item;
  }
  
  private static String failSafeGetStringFromJSON(JSONObject json, String name, String defaultValue) {
    try {
      return json.getString(name);
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
    case 4:
      return getOneLineView(position, convertView, parent);
    default:
      return getTwoLineView(position, convertView, parent);
    }
  }

  private View getOneLineView(int position, View convertView, ViewGroup parent) {
    View row = convertView;
    if (!(row instanceof TextView)) {
      LayoutInflater inflater = activity.getLayoutInflater();
      row = inflater.inflate(R.layout.simple_list_item_1, parent, false);
    }
      
    String[] item = (String[])getItem(position);
    
    TextView textView = (TextView)row.findViewById(R.id.text1);
    textView.setText(item[0]);
    textView.setTextColor(Color.BLACK);
    
    return row;
  }
  
  private View getTwoLineView(int position, View convertView, ViewGroup parent) {
    View row = convertView;
    if (!(row instanceof TwoLineListItem)) {
      LayoutInflater inflater = activity.getLayoutInflater();
      row = inflater.inflate(R.layout.simple_list_item_2, parent, false);
    }
      
    String[] item = (String[])getItem(position);
    
    TextView text1View = (TextView)row.findViewById(R.id.text1);
    text1View.setText(item[0]);
    text1View.setTextColor(Color.BLACK);
    
    TextView text2View = (TextView)row.findViewById(R.id.text2);
    text2View.setText(item[1]);
    text2View.setTextColor(Color.BLUE);
    
    return row;
  }
}

package net.hockeyapp.android;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.UUID;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

public class UpdateActivity extends ListActivity {
  public static int iconDrawableId = -1;
  public static String packageName = null;

  protected DownloadFileTask downloadTask;
  protected ResourceHelper resources;
  protected UpdateInfoAdapter adapter;
  
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    resources = new ResourceHelper("hockey", this.getPackageName());
    
    setTitle("Application Update");
    setContentView(resources.getLayoutId("update_view"));
    moveViewBelowOrBesideHeader(this, android.R.id.list, resources.getItemId("hockey_header_view"), 23);

    adapter = new UpdateInfoAdapter(this, getIntent().getStringExtra("json"));
    getListView().setDivider(null);
    setListAdapter(adapter);
    configureView();
    
    downloadTask = (DownloadFileTask)getLastNonConfigurationInstance();
    if (downloadTask != null) {
      downloadTask.attach(this);
    }
  }
  
  protected void configureView() {
    if (iconDrawableId != -1) {
      ImageView iconView = (ImageView)findViewById(resources.getItemId("icon_view"));
      iconView.setImageDrawable(getResources().getDrawable(iconDrawableId));
    }
    
    TextView versionLabel = (TextView)findViewById(resources.getItemId("version_label"));
    versionLabel.setText("Version " + adapter.getVersionString() + "\n" + adapter.getFileInfoString());

    TextView titleLabel = (TextView)findViewById(resources.getItemId("name_label"));
    titleLabel.setText(getApplicationName());
  }

  private String getApplicationName() {
    final PackageManager manager = getPackageManager();
    ApplicationInfo info = null;
    try {
      if (packageName != null) { 
        info = manager.getApplicationInfo(packageName, 0);
      }
    } 
    catch (final NameNotFoundException e) {
    }
    return (String)(info != null ? manager.getApplicationLabel(info) : "Unknown");
  }

  private void moveViewBelowOrBesideHeader(Activity activity, int viewID, int headerID, float offset) {
    ViewGroup headerView = (ViewGroup)activity.findViewById(headerID); 
    View view = (View)activity.findViewById(viewID);
    float density = activity.getResources().getDisplayMetrics().density; 
    RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT, activity.getWindowManager().getDefaultDisplay().getHeight() - headerView.getHeight() + (int)(offset * density));
    if (((String)view.getTag()).equalsIgnoreCase("right")) {
      layoutParams.addRule(RelativeLayout.RIGHT_OF, resources.getItemId("header_view"));
      layoutParams.setMargins(-(int)(offset * density), 0, 0, (int)(10 * density));
    }
    else {
      layoutParams.addRule(RelativeLayout.BELOW, resources.getItemId("header_view"));
      layoutParams.setMargins(0, -(int)(offset * density), 0, (int)(10 * density));
    }
    view.setLayoutParams(layoutParams);
  }

  @Override
  public Object onRetainNonConfigurationInstance() {
    if (downloadTask != null) {
      downloadTask.detach();
    }
    return downloadTask;
  }
  
  public void onClickUpdate(View v) {
    startDownloadTask();
  }
  
  private void startDownloadTask() {
    downloadTask = new DownloadFileTask(this, getIntent().getStringExtra("url"));
    downloadTask.execute();
  }

  private class DownloadFileTask extends AsyncTask<String, Integer, Boolean>{
    private Context context;
    private String urlString;
    private String filename;
    private String filePath;
    private ProgressDialog progressDialog;

    public DownloadFileTask(Context context, String urlString) {
      this.context = context;
      this.urlString = urlString;
      this.filename = UUID.randomUUID() + ".apk";
      this.filePath = Environment.getExternalStorageDirectory().getAbsolutePath() + "/Download";
    }
    
    public void attach(Context context) {
      this.context = context;
    }
    
    public void detach() {
      context = null;
      progressDialog = null;
    }

    @Override
    protected Boolean doInBackground(String... args) {
      try {
        URL url = new URL(getURLString());
        URLConnection connection = url.openConnection();
        connection.setRequestProperty("connection", "close");
        connection.connect();

        int lenghtOfFile = connection.getContentLength();

        File dir = new File(this.filePath);
        dir.mkdirs();
        File file = new File(dir, this.filename);

        InputStream input = new BufferedInputStream(connection.getInputStream());
        OutputStream output = new FileOutputStream(file);

        byte data[] = new byte[1024];
        int count = 0;
        long total = 0;
        while ((count = input.read(data)) != -1) {
          total += count;
          publishProgress((int)(total * 100 / lenghtOfFile));
          output.write(data, 0, count);
        }

        output.flush();
        output.close();
        input.close();
        
        return (total > 0);
      } 
      catch (Exception e) {
        e.printStackTrace();
        return false;
      }
    }
  
     @Override
     protected void onProgressUpdate(Integer... args){
       if (progressDialog == null) {
         progressDialog = new ProgressDialog(context);
         progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
         progressDialog.setMessage("Loading...");
         progressDialog.setCancelable(false);
         progressDialog.show();
       }
       progressDialog.setProgress(args[0]);
     }
     
     @Override
     protected void onPostExecute(Boolean result) {
       if (progressDialog != null) {
         progressDialog.dismiss();
       }
       
       if (result) {
         Intent intent = new Intent(Intent.ACTION_VIEW);
         intent.setDataAndType(Uri.fromFile(new File(this.filePath, this.filename)), "application/vnd.android.package-archive");
         intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
         startActivity(intent);
       }
       else {
         AlertDialog.Builder builder = new AlertDialog.Builder(context);
         builder.setTitle(resources.getStringId("download_failed_dialog_title"));
         builder.setMessage(resources.getStringId("hockey_download_failed_dialog_message"));

         builder.setNegativeButton(resources.getStringId("download_failed_dialog_negative_button"), new DialogInterface.OnClickListener() {
           public void onClick(DialogInterface dialog, int which) {
           } 
         });

         builder.setPositiveButton(resources.getStringId("download_failed_dialog_positive_button"), new DialogInterface.OnClickListener() {
           public void onClick(DialogInterface dialog, int which) {
             downloadTask = new DownloadFileTask(UpdateActivity.this, getIntent().getStringExtra("url"));
             downloadTask.execute();
           } 
         });
         
         builder.create().show();
       }
     }

     private String getURLString() {
       return urlString + "&type=apk";      
     }
  }
}

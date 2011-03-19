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
import android.app.ListActivity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
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

  private DownloadFileTask downloadTask;
  private UpdateInfoAdapter adapter;
  
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    setTitle("Application Update");
    setContentView(R.layout.update_view);
    moveViewBelowOrBesideHeader(this, android.R.id.list, R.id.header_view, 23);

    adapter = new UpdateInfoAdapter(this, getIntent().getStringExtra("json"));
    getListView().setDivider(null);
    setListAdapter(adapter);
    configureView();
    
    downloadTask = (DownloadFileTask)getLastNonConfigurationInstance();
    if (downloadTask != null) {
      downloadTask.attach(this);
    }
  }
  
  private void configureView() {
    if (iconDrawableId != -1) {
      ImageView iconView = (ImageView)findViewById(R.id.icon_view);
      iconView.setImageDrawable(getResources().getDrawable(iconDrawableId));
    }
    
    TextView versionLabel = (TextView)findViewById(R.id.version_label);
    versionLabel.setText("Version " + adapter.getVersionString() + "\n" + adapter.getFileInfoString());
  }

  private static void moveViewBelowOrBesideHeader(Activity activity, int viewID, int headerID, float offset) {
    ViewGroup headerView = (ViewGroup)activity.findViewById(headerID); 
    View view = (View)activity.findViewById(viewID);
    RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT, activity.getWindowManager().getDefaultDisplay().getHeight() - headerView.getHeight() + (int)(offset * activity.getResources().getDisplayMetrics().density));
    if (((String)view.getTag()).equalsIgnoreCase("right")) {
      layoutParams.addRule(RelativeLayout.RIGHT_OF, R.id.header_view);
      layoutParams.setMargins(-(int)(offset * activity.getResources().getDisplayMetrics().density), 0, 0, 0);
    }
    else {
      layoutParams.addRule(RelativeLayout.BELOW, R.id.header_view);
      layoutParams.setMargins(0, -(int)(offset * activity.getResources().getDisplayMetrics().density), 0, 0);
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

  private class DownloadFileTask extends AsyncTask<String, Integer, Void>{
    private Context context;
    private String urlString;
    private String filename;
    private ProgressDialog progressDialog;

    public DownloadFileTask(Context context, String urlString) {
      this.context = context;
      this.urlString = urlString;
      this.filename = "download/" + UUID.randomUUID() + ".apk";
    }
    
    public void attach(Context context) {
      this.context = context;
    }
    
    public void detach() {
      context = null;
      progressDialog = null;
    }

    @Override
    protected Void doInBackground(String... args) {
      try {
        URL url = new URL(getURLString());
        URLConnection connection = url.openConnection();
        connection.connect();

        int lenghtOfFile = connection.getContentLength();

        InputStream input = new BufferedInputStream(connection.getInputStream());
        OutputStream output = new FileOutputStream(new File(Environment.getExternalStorageDirectory(), this.filename));

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
      } 
      catch (Exception e) {
        e.printStackTrace();
      }
      return null;
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
     protected void onPostExecute(Void result) {
       if (progressDialog != null) {
         progressDialog.dismiss();
       }
       
       Intent intent = new Intent(Intent.ACTION_VIEW);
       intent.setDataAndType(Uri.fromFile(new File(Environment.getExternalStorageDirectory(), this.filename)), "application/vnd.android.package-archive");
       startActivity(intent);
     }

     private String getURLString() {
       return urlString + "&type=apk";      
     }
  }
}

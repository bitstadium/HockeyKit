package net.hockeyapp.android.demo;

import net.hockeyapp.android.CheckUpdateTask;
import net.hockeyapp.android.UpdateActivity;
import android.app.Activity;
import android.os.Bundle;

public class MainActivity extends Activity {
  private CheckUpdateTask checkUpdateTask;

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.main);
    
    UpdateActivity.iconDrawableId = R.drawable.icon;
    checkForUpdates();
  }

  private void checkForUpdates() {
    checkUpdateTask = (CheckUpdateTask)getLastNonConfigurationInstance();
    if (checkUpdateTask != null) {
      checkUpdateTask.attach(this);
    }
    else {
      checkUpdateTask = new CheckUpdateTask(this, "http://worldviewmobileapp.com/apps/demo/");
      checkUpdateTask.execute();
    }
  }

  @Override
  public Object onRetainNonConfigurationInstance() {
    checkUpdateTask.detach();
    return checkUpdateTask;
  }
}
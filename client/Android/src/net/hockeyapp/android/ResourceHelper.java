// Based on https://github.com/commonsguy/cwac-parcel/blob/master/src/com/commonsware/cwac/parcel/ParcelHelper.java

/*
  Copyright (c) 2010 CommonsWare, LLC
  
  Licensed under the Apache License, Version 2.0 (the "License"); you may
  not use this file except in compliance with the License. You may obtain
  a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

package net.hockeyapp.android;

import android.util.Log;

import java.lang.reflect.Array;
import java.lang.reflect.Field;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

public class ResourceHelper {
  private static final int CACHE_SIZE = 101;
  
  @SuppressWarnings("rawtypes")
  private Class resources = null;
  
  private Map<String, Integer> cache = null;
  private String id = null;

  public ResourceHelper(String id, String packageName) {
    this.id = id.replace('.', '_').replace('-', '_');

    try {
      this.resources = Class.forName(packageName + ".R");
    }
    catch (Throwable t) {
      throw new RuntimeException("Exception finding R class", t);
    }

    this.cache = Collections.synchronizedMap(new Cache());
  }

  public int[] getStyleableArray(String name) {
    try {
      @SuppressWarnings("rawtypes")
      Class klass = getResourceClass("styleable");

      if (klass != null) {
        Field field = klass.getDeclaredField(name);

        if (field != null) {
          Object object = field.get(klass);

          if (object instanceof int[]) {
            int[] result = new int[Array.getLength(object)];

            for (int index = 0; index < Array.getLength(object); index++) {
              result[index] = Array.getInt(object, index);
            }

            return (result);
          }
        }
      }
    }
    catch (Throwable t) {
      throw new RuntimeException("Exception finding styleable", t);
    }

    return (new int[0]);
  }

  public int getStyleableId(String component, String attribute) {
    return (getIdentifier(component + "_" + attribute, "styleable", false));
  }

  public int getLayoutId(String layout) {
    return (getIdentifier(layout, "layout", true));
  }

  public int getItemId(String item) {
    return (getIdentifier(item, "id", true));
  }

  public int getMenuId(String menu) {
    return (getIdentifier(menu, "menu", true));
  }

  public int getDrawableId(String drawable) {
    return (getIdentifier(drawable, "drawable", true));
  }

  public int getStringId(String item) {
    return (getIdentifier(item, "string", true));
  }

  public int getIdentifier(String name, String defType) {
    return (getIdentifier(name, defType, true));
  }

  public int getIdentifier(String name, String defType, boolean mungeName) {
    int result = -1;
    StringBuilder cacheKey = new StringBuilder(name);

    cacheKey.append('|');
    cacheKey.append(defType);

    Integer cacheHit = cache.get(cacheKey.toString());

    if (cacheHit != null) {
      return (cacheHit.intValue());
    }

    if (!name.startsWith(id) && mungeName) {
      StringBuilder buffer = new StringBuilder(id);

      buffer.append('_');
      buffer.append(name);

      name = buffer.toString();
    }

    try {
      @SuppressWarnings("rawtypes")
      Class klass = getResourceClass(defType);

      if (klass != null) {
        Field field = klass.getDeclaredField(name);

        if (field != null) {
          result = field.getInt(klass);
          cache.put(cacheKey.toString(), result);
        }
      }
    }
    catch (Throwable t) {
      throw new RuntimeException("Exception finding resource identifier", t);
    }

    return(result);
  }

  @SuppressWarnings("rawtypes")
  private Class getResourceClass(String defType) {
    for (Class klass : resources.getClasses()) {
      if (defType.equals(klass.getSimpleName())) {
        Log.i("Hockey", klass.getName());
        return(klass);
      }
    }

    return (null);
  }

  @SuppressWarnings("serial")
  public class Cache extends LinkedHashMap<String,Integer> {
    public Cache() {
      super(CACHE_SIZE, 1.1f, true);
    }

    @SuppressWarnings("rawtypes")
    protected boolean removeEldestEntry(Entry eldest) {
      return (size() > CACHE_SIZE);
    }
  }
}
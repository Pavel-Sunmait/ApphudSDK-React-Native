package com.reactnativeapphudsdk

import android.view.View
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext

class ApphudSdkViewManager : SimpleViewManager<View>() {
  override fun createViewInstance(p0: ThemedReactContext): View {
    return View(p0)
  }

  override fun getName(): String = "PaywallScreenView"
}

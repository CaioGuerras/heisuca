package app.heisuca.shared

import android.content.Context
import androidx.core.content.ContextCompat
import app.heisuca.R

object ThemeHelper {
  fun themeColor(context: Context, mode: String?): Int? {
    val resource = when (mode) {
      "oled" -> R.color.splash_oled
      "dark" -> R.color.splash_dark
      "light" -> R.color.splash_light
      else -> return null
    }
    return ContextCompat.getColor(context, resource)
  }
}

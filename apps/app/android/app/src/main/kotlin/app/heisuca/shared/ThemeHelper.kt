package app.heisuca.shared

import android.graphics.Color

object ThemeHelper {
  fun themeColor(mode: String?): Int? = when (mode) {
    "oled" -> Color.BLACK
    "dark" -> Color.parseColor("#0E0B14")
    "light" -> Color.parseColor("#F7F3EC") // CGFLIX: fundo do tema Heitor
    else -> null
  }
}

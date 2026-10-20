package com.edde746.plezy.shared

import android.graphics.Color

object ThemeHelper {
  fun themeColor(mode: String?): Int? = when (mode) {
    "oled" -> Color.BLACK
    "dark" -> Color.parseColor("#0E0F12")
    "light" -> Color.parseColor("#F4FCEE") // CGFLIX: fundo do tema Heitor
    else -> null
  }
}

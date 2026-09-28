# Release minify (isMinifyEnabled). Flutter plugin kendi keep'lerini enjekte eder.
# Flutter engine / Play Core bilinen uyarıları:
-dontwarn com.google.android.play.core.**

# Shizuku UserService: server süreci sınıfı KENDİ ADIYLA yükler (ComponentName
# üzerinden reflection) — R8 isim kısaltmayı kırar (emülatör E2E'de
# InstantiationException: Class<D.h> olarak gözlendi). AIDL arayüzü de
# binder transact için korunmalı.
-keep class com.zoriasoft.zoriapause.PauseGrantService { *; }
-keep class com.zoriasoft.zoriapause.IPauseGrantService { *; }
-keep class com.zoriasoft.zoriapause.IPauseGrantService$* { *; }

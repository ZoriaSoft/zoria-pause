// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Zoria Pause';

  @override
  String get statusHeading => 'PRIVATE DNS';

  @override
  String get statusProtectionOn => 'Koruma açık';

  @override
  String get statusAuto => 'Otomatik';

  @override
  String get statusPaused => 'Duraklatıldı';

  @override
  String get controlHeading => 'REKLAM ENGELLEME';

  @override
  String get controlOn => 'AÇIK';

  @override
  String get controlAuto => 'OTOMATİK';

  @override
  String get controlPaused => 'DURAKLATILDI';

  @override
  String get controlTapPause => 'dokun: duraklat';

  @override
  String get controlTapResume => 'dokun: geri aç';

  @override
  String get errorNotGranted =>
      'Kurulum gerekli: önce tek seferlik izni vermelisin.';

  @override
  String get errorUnsupported =>
      'Bu cihaz desteklenmiyor (Android 9+ gerekir).';

  @override
  String get errorGeneric => 'Durum okunamadı.';

  @override
  String get statusReading => 'Durum okunuyor';

  @override
  String get statusNoHostname => 'yok';

  @override
  String get setupTitle => 'Kurulum';

  @override
  String get setupTabSetup => 'KURULUM';

  @override
  String get setupTabGuide => 'ADIM ADIM';

  @override
  String get setupIntro =>
      'Reklam engelleyen Private DNS ayarını geçici duraklatmak için Android\'den tek seferlik bir izin gerekiyor. Bir kez vermen yeterli; uygulama başka hiçbir şeye dokunmaz, internet üzerinden hiçbir şey göndermez. En kolay yol telefonda tamamlanır ve Wi-Fi ağına bağlı olmayı ister.';

  @override
  String get setupPathShizukuTitle => '1. YOL · TELEFON YETER (ÖNERİLEN)';

  @override
  String get setupLegacyAndroidNote =>
      'Telefonla tek başına kurulum Android 11 veya üzeri gerektirdiği için bu telefonda yok. Kaybettiğin bir şey yok: telefonu USB ile bir bilgisayara bir kez bağlat ve aşağıdaki komutu çalıştır — izin her iki yolda da kalıcıdır.';

  @override
  String get setupPathShizukuSteps =>
      '1. Aşağıdaki butonla Shizuku\'yu Play Store\'dan kur (ücretsiz, güvenilir bir yardımcı).\n2. Shizuku\'yu aç ve \'Kablosuz hata ayıklama ile başlat\' adımlarını izle. Telefon Wi-Fi ağına bağlı olmalı.\n3. Zoria Pause\'a geri dön ve aşağıdaki İZİN VER\'e bas. Adımların tamamı adım adım rehberde.';

  @override
  String get setupGuideButton => 'ADIM ADIM REHBER';

  @override
  String get shizukuNeedInstall =>
      'Telefonla tek başına kurmak için küçük bir yardımcı uygulama gerekiyor: Shizuku. Play Store\'dan ücretsiz kurulur; işi bittikten sonra silsen bile olur.';

  @override
  String get shizukuInstallButton => 'PLAY STORE\'DAN KUR';

  @override
  String get shizukuStartHint =>
      'Shizuku kurulu ama henüz başlatılmamış. Shizuku\'yu aç, \'Kablosuz hata ayıklama\' yöntemiyle başlat ve buraya geri dön. Döndüğünde bu sayfa kendini günceller.';

  @override
  String get shizukuOpenButton => 'SHIZUKU\'YU AÇ';

  @override
  String get shizukuReady => 'Shizuku hazır. Tek dokunuşla izin verilebilir.';

  @override
  String get shizukuGrantButton => 'İZİN VER';

  @override
  String get shizukuGrantFailed =>
      'İzin verilemedi. Shizuku\'nun açık olduğundan emin ol ve tekrar dene.';

  @override
  String get setupPathPcTitle => '2. YOL · BİRİ PC İLE YARDIM EDERSE';

  @override
  String get setupPathPcSteps =>
      'Telefonu USB kablosuyla bilgisayara bağlayabilen biri varsa en hızlı yol budur. O kişi aşağıdaki komutu çalıştırır. Telefonda USB hata ayıklama açık olmalı.';

  @override
  String get setupCommandHeader => 'BİLGİSAYARDA ÇALIŞTIRILACAK KOMUT:';

  @override
  String get setupCopy => 'Komutu kopyala';

  @override
  String get setupCopied => 'Kopyalandı';

  @override
  String get advancedWirelessTitle =>
      'Gelişmiş: kablosuz bilgisayar bağlantısı (Android 11+)';

  @override
  String get setupPathWirelessSteps =>
      'USB kablosu yoksa: telefonda Geliştirici seçenekleri\'nden Kablosuz hata ayıklama ile eşleştir; bilgisayardan aynı komutu kablosuz çalıştır.';

  @override
  String get devOptionsTitle => 'Geliştirici seçenekleri kapalı mı?';

  @override
  String get devOptionsSteps =>
      '1. Ayarlar → Telefon hakkında.\n2. Derleme numarasına 7 kez dokun.\n3. \'Artık geliştiricisin\' yazınca geri dön; Geliştirici seçenekleri Ayarlar listesine eklenmiş olur.';

  @override
  String get setupCheckAgain => 'Yeniden kontrol et';

  @override
  String get guideIntro =>
      'Telefonla kurulumun tam rehberi. Yaklaşık 5 dakika sürer ve yalnızca bir kez yapılır.';

  @override
  String get guideStep1Title => 'Wi-Fi ağına bağlan';

  @override
  String get guideStep1Body =>
      'Kablosuz hata ayıklama Wi-Fi üzerinden çalışır; kurulum boyunca telefon Wi-Fi\'ye bağlı kalmalı.';

  @override
  String get guideStep2Title => 'Geliştirici seçeneklerini aç';

  @override
  String get guideStep2Body =>
      'Ayarlar → Telefon hakkında → Derleme numarasına 7 kez dokun. \'Artık geliştiricisin\' yazısı gelince hazır.';

  @override
  String get guideStep3Title => 'Kablosuz hata ayıklamayı aç';

  @override
  String get guideStep3Body =>
      'Ayarlar → Geliştirici seçenekleri → Kablosuz hata ayıklama\'yı aç. İstenirse ağa izin ver.';

  @override
  String get guideStep4Title => 'Shizuku\'yu kur';

  @override
  String get guideStep4Body =>
      'Play Store\'dan ücretsiz kur. İşlem bitince silsen bile olur.';

  @override
  String get guideStep5Title => 'Shizuku\'yu başlat';

  @override
  String get guideStep5Body =>
      'Shizuku\'yu aç ve \'Kablosuz hata ayıklama üzerinden başlat\'ı seç. Telefon seni Ayarlar\'daki eşleştirme ekranına götürür; orada görünen kodu Shizuku\'ya gir.';

  @override
  String get guideStep6Title => 'Çalıştığını gör';

  @override
  String get guideStep6Body =>
      'Shizuku ana ekranında \'çalışıyor\' durumunu görene kadar bekle.';

  @override
  String get guideStep7Title => 'Zoria Pause\'a dön ve izin ver';

  @override
  String get guideStep7Body =>
      'Kurulum ekranındaki İZİN VER butonuna bas. Bu kadar: izin kalıcı, bu adımlar bir daha gerekmez.';

  @override
  String get guideRebootNote =>
      'Not: telefon yeniden başlarsa Shizuku durur ve tekrar başlatman gerekir. Zoria Pause\'a verdiğin izin ise kalıcıdır.';

  @override
  String get guideTroubleNote =>
      'Takıldın mı? Wi-Fi\'yi kapatıp aç ve eşleştirme adımını tekrarla. Eşleştirme bildirimi gelmezse Ayarlar\'dan Kablosuz hata ayıklama\'yı aç ve \'Eşleştirme koduyla cihaz eşle\'ye kendin dokun.';

  @override
  String get durationLabel => 'OTOMATİK GERİ AÇMA';

  @override
  String get durationRelabel => 'YENİDEN PLANLA';

  @override
  String get durationForever => 'Süresiz';

  @override
  String get minutesShort => 'dk';

  @override
  String get resumeAtLabel => 'Geri açma';

  @override
  String get autoResumeNote => 'Sistem alarmı yaklaşık 1 dakika sapabilir.';

  @override
  String get unscheduledNote =>
      'Otomatik geri açma yok. Geri açmak için yukarıdaki butona dokun; ya da aşağıdan bir süre planla.';

  @override
  String weeklyCount(int count) {
    return 'Bu hafta $count kez duraklattın';
  }

  @override
  String get honestDelayNote => 'Etkisi 1-2 dakika içinde görülür.';

  @override
  String get notifPermTitle => 'BİLDİRİM İZNİ';

  @override
  String get notifPermBody =>
      'Duraklatma sırasında iki küçük bildirim gönderebiliriz: geri açılma saati ve süre dolmeden uyarı. İzin vermezsen uygulama yine çalışır; yalnızca bu saatleri bildirimde göremezsin.';

  @override
  String get notifPermGrant => 'İZİN VER';

  @override
  String get notifPermLater => 'ŞİMDİ DEĞİL';

  @override
  String get notifOffNote =>
      'Bildirimler kapalı: geri açma saati bildirim olarak görünmez.';

  @override
  String get tileHintTitle => 'TEK DOKUNUŞ İÇİN';

  @override
  String get tileHintBody =>
      'Ekranı iki parmakla aşağı kaydırıp hızlı ayarlar panelini aç. DÜZENLE\'ye bas, Zoria Pause\'u bul ve yukarı taşı. Artık uygulamayı açmadan duraklatabilirsin.';

  @override
  String get tileHintDone => 'TAMAM, EKLEDİM';

  @override
  String get reminderBandTitle => 'SÜRE DOLMAK ÜZERE';

  @override
  String get reminderBandExtend => '+5 DK UZAT';

  @override
  String get providerCardTitle => 'REKLAM ENGELLEME KURULMAMIŞ';

  @override
  String get providerCardBody =>
      'Telefonunda henüz bir engelleyici DNS tanımlı değil; uygulama duraklatılacak bir koruma bulamıyor. Ücretsiz ve hesapsız AdGuard DNS tek dokunuşla kurulabilir.';

  @override
  String get providerSetupButton => 'ADGUARD\'LA KUR';

  @override
  String get providerManualLink => 'Kendi DNS sunucun mu var? Elle gir';

  @override
  String get providerManualTitle => 'DNS ADRESİ';

  @override
  String get providerManualHint => 'örn. dns.adguard.com';

  @override
  String get providerManualApply => 'KUR';

  @override
  String get providerManualCancel => 'VAZGEÇ';

  @override
  String get providerManualInvalid =>
      'Geçerli bir adres gir; örneğin dns.adguard.com';

  @override
  String get infoTitle => 'NELER ENGELLENİYOR?';

  @override
  String get infoBlocksLabel => 'ENGELLER';

  @override
  String get infoBlocks =>
      'Web\'de banner ve açılır pencereler, uygulamalarda reklam bantları ve geçiş reklamları, izleyici/analitik etiketleri — bilinen reklam sunucularından gelen her şey.';

  @override
  String get infoLimitsLabel => 'ENGELLEMEZ';

  @override
  String get infoLimits =>
      'İçeriğin kendisiyle aynı kaynaktan gelen reklamlar: YouTube video reklamları, Instagram benzeri akış reklamları.';

  @override
  String get infoHowLabel => 'NASIL ÇALIŞIR';

  @override
  String get infoHow =>
      'Bilinen reklam sunucularının adı \'yok\' olarak yanıtlanır; reklam yüklenemez. Bağlantın şifreli kalır, trafiğin içeriğine dokunulmaz.';

  @override
  String get homeSetupTooltip => 'Kurulum rehberi';
}

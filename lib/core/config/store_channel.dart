enum StoreChannel {
  googlePlay,
  huaweiAppGallery,
  appStore,
  development;

  static StoreChannel fromName(String value) {
    return switch (value) {
      'googlePlay' => StoreChannel.googlePlay,
      'huaweiAppGallery' => StoreChannel.huaweiAppGallery,
      'appStore' => StoreChannel.appStore,
      _ => StoreChannel.development,
    };
  }
}

class AppEnvironment {
  const AppEnvironment({required this.storeChannel});

  factory AppEnvironment.fromDefines() {
    const channel = String.fromEnvironment(
      'STORE_CHANNEL',
      defaultValue: 'googlePlay',
    );
    return AppEnvironment(storeChannel: StoreChannel.fromName(channel));
  }

  final StoreChannel storeChannel;

  bool get usesGoogleServices => storeChannel == StoreChannel.googlePlay;
  bool get usesHuaweiServices => storeChannel == StoreChannel.huaweiAppGallery;
  bool get usesAppleServices => storeChannel == StoreChannel.appStore;
}

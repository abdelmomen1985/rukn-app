import { View, ScrollView, Pressable } from "react-native";
import { Text } from "@/components/ui/text";
import { TitleBar } from "@/components/title-bar";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import * as Haptics from "expo-haptics";
import { useI18n, type Lang } from "@/lib/i18n";
import { useRouter } from "expo-router";

export default function ProfileScreen() {
  const colors = useColors();
  const { t, lang, setLang, isRTL } = useI18n();
  const router = useRouter();

  const menuItems = [
    { icon: "person", title: t("accountSettings"), subtitle: t("accountSettingsSubtitle"), route: null },
    { icon: "box", title: t("orderHistory"), subtitle: t("orderHistorySubtitle"), route: "/order-history" },
    { icon: "heart", title: t("savedAddresses"), subtitle: t("savedAddressesSubtitle"), route: null },
    { icon: "creditcard", title: t("paymentMethods"), subtitle: t("paymentMethodsSubtitle"), route: null },
    { icon: "bell", title: t("notifications"), subtitle: t("notificationsSubtitle"), route: null },
    { icon: "help", title: t("helpSupport"), subtitle: t("helpSupportSubtitle"), route: null },
  ];

  const handleMenuPress = (route: string | null, title: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (route) router.push(route as any);
    else console.log("Menu pressed:", title);
  };

  const handleLangSwitch = (newLang: Lang) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setLang(newLang);
  };

  return (
    <ScreenContainer className="bg-background">
      <TitleBar />
      <ScrollView className="flex-1 px-6 py-6" showsVerticalScrollIndicator={false}>

        {/* User Card */}
        <View className="bg-surface rounded-2xl p-6 mb-6 gap-4">
          <View className="w-20 h-20 bg-primary rounded-full items-center justify-center self-center">
            <IconSymbol name="person" size={40} color={colors.darkGreen} />
          </View>
          <View className="items-center gap-1">
            <Text className="text-foreground text-2xl font-bold" style={{ fontFamily: "Cormorant_Garamond" }}>
              {t("guestUser")}
            </Text>
            <Text className="text-muted text-sm">{t("signInSubtitle")}</Text>
          </View>
          <Pressable
            onPress={() => handleMenuPress("Sign In")}
            style={({ pressed }) => ({
              opacity: pressed ? 0.9 : 1,
              transform: [{ scale: pressed ? 0.97 : 1 }],
            })}
            className="bg-primary py-3 rounded-full items-center"
          >
            <Text className="text-darkGreen text-base font-bold">{t("signIn")}</Text>
          </Pressable>
        </View>

        {/* Language Switcher */}
        <View className="bg-surface rounded-2xl p-4 mb-6">
          <Text
            className="text-foreground text-base font-semibold mb-3"
            style={{ textAlign: isRTL ? "right" : "left" }}
          >
            {t("language")}
          </Text>
          <View className="flex-row gap-3">
            <Pressable
              onPress={() => handleLangSwitch("en")}
              style={({ pressed }) => ({ opacity: pressed ? 0.8 : 1, flex: 1 })}
              className={`py-2.5 rounded-full items-center border ${
                lang === "en" ? "bg-primary border-primary" : "bg-background border-border"
              }`}
            >
              <Text className={`text-sm font-bold ${lang === "en" ? "text-darkGreen" : "text-foreground"}`}>
                English
              </Text>
            </Pressable>
            <Pressable
              onPress={() => handleLangSwitch("ar")}
              style={({ pressed }) => ({ opacity: pressed ? 0.8 : 1, flex: 1 })}
              className={`py-2.5 rounded-full items-center border ${
                lang === "ar" ? "bg-primary border-primary" : "bg-background border-border"
              }`}
            >
              <Text className={`text-sm font-bold ${lang === "ar" ? "text-darkGreen" : "text-foreground"}`}>
                العربية
              </Text>
            </Pressable>
          </View>
        </View>

        {/* Menu Items */}
        <View className="gap-2">
          {menuItems.map((item, index) => (
            <Pressable
              key={index}
              onPress={() => handleMenuPress(item.route, item.title)}
              style={({ pressed }) => ({
                opacity: pressed ? 0.7 : 1,
                flexDirection: isRTL ? "row-reverse" : "row",
                alignItems: "center",
                gap: 16,
                backgroundColor: colors.surface,
                borderRadius: 12,
                padding: 16,
              })}
            >
              <View className="w-10 h-10 bg-cream rounded-full items-center justify-center">
                <IconSymbol name={item.icon as any} size={20} color={colors.foreground} />
              </View>
              <View style={{ flex: 1, gap: 4 }}>
                <Text
                  className="text-foreground text-base font-semibold"
                  style={{ textAlign: isRTL ? "right" : "left" }}
                >
                  {item.title}
                </Text>
                <Text
                  className="text-muted text-sm"
                  style={{ textAlign: isRTL ? "right" : "left" }}
                >
                  {item.subtitle}
                </Text>
              </View>
              <IconSymbol
                name={isRTL ? "chevron.left" : "chevron.right"}
                size={20}
                color={colors.muted}
              />
            </Pressable>
          ))}
        </View>

        <View className="mt-8 items-center gap-2">
          <Text className="text-muted text-sm">{t("version")}</Text>
          <Text className="text-muted text-xs">{t("copyright")}</Text>
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}

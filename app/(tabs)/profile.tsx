import { View, ScrollView, Pressable, Modal, Linking, Alert } from "react-native";
import { Text } from "@/components/ui/text";
import { TitleBar } from "@/components/title-bar";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import * as Haptics from "expo-haptics";
import { useI18n, type Lang } from "@/lib/i18n";
import { useRouter, useFocusEffect } from "expo-router";
import { useCallback, useState } from "react";
import {
  deleteAccount,
  getCustomerToken,
  getMe,
  logout,
  type Customer,
} from "@/lib/medusa";
import { wipeDeviceData } from "@/lib/local-data";
import { WEB } from "@/lib/brand";

export default function ProfileScreen() {
  const colors = useColors();
  const { t, lang, setLang, isRTL } = useI18n();
  const router = useRouter();
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  useFocusEffect(
    useCallback(() => {
      getCustomerToken().then((token) => {
        if (!token) {
          setCustomer(null);
          return;
        }
        getMe()
          .then(setCustomer)
          .catch(() => setCustomer(null));
      });
    }, [])
  );

  const handleAuthPress = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    if (customer) {
      await logout();
      setCustomer(null);
    } else {
      router.push("/auth" as any);
    }
  };

  const menuItems = [
    { icon: "box", title: t("orderHistory"), subtitle: t("orderHistorySubtitle"), action: "orders" },
    { icon: "help", title: t("helpSupport"), subtitle: t("helpSupportSubtitle"), action: "support" },
    // Both stores open this link during review, so never render it while it
    // still points at the placeholder origin (see lib/brand.ts).
    ...(WEB.isConfigured
      ? [{ icon: "lock.shield", title: t("privacyPolicy"), subtitle: t("privacyPolicySubtitle"), action: "privacy" }]
      : []),
  ];

  const openExternal = async (url: string) => {
    try {
      await Linking.openURL(url);
    } catch {
      Alert.alert(t("helpSupport"), WEB.support);
    }
  };

  const handleMenuPress = (action: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (action === "orders") router.push("/order-history" as any);
    else if (action === "support") void openExternal(`mailto:${WEB.support}`);
    else if (action === "privacy") void openExternal(WEB.privacyPolicy);
  };

  /**
   * Account deletion — required by Google Play (all apps with sign-in) and App
   * Store Guideline 5.1.1(v). Server-side records go through Medusa; everything
   * this device holds is cleared with wipeDeviceData().
   */
  const runDeleteAccount = async () => {
    setDeleting(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
    const result = customer ? await deleteAccount() : { status: "no_session" as const };

    // Only erase what is on the device once the server side is actually gone.
    // Wiping on a failed delete would destroy the user's portfolio, wishlist and
    // trips while their account and orders still exist on the backend.
    const serverSideDone = result.status === "deleted" || result.status === "no_session";
    if (serverSideDone) {
      await wipeDeviceData();
      setCustomer(null);
    }

    setDeleting(false);
    setConfirmDelete(false);

    if (result.status === "deleted") {
      Alert.alert(t("deleteAccount"), t("deleteAccountDone"));
      return;
    }
    if (result.status === "no_session") {
      // Nothing was signed in: this path only erased the local copy.
      Alert.alert(t("deleteAccount"), t("deviceDataWiped"));
      return;
    }

    // Deletion failed. Hand over a channel that actually works instead of a tick.
    const buttons = [
      { text: t("deleteAccountCancel"), style: "cancel" as const },
      { text: t("emailSupport"), onPress: () => void openExternal(`mailto:${WEB.support}`) },
      ...(WEB.isConfigured
        ? [{ text: t("openWebDeletion"), onPress: () => void openExternal(WEB.accountDeletion) }]
        : []),
    ];
    Alert.alert(t("deleteAccount"), t("deleteAccountFailed"), buttons);
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
              {customer
                ? [customer.first_name, customer.last_name].filter(Boolean).join(" ") || customer.email
                : t("guestUser")}
            </Text>
            <Text className="text-muted text-sm">
              {customer ? customer.email : t("signInSubtitle")}
            </Text>
          </View>
          <Pressable
            onPress={handleAuthPress}
            style={({ pressed }) => ({
              opacity: pressed ? 0.9 : 1,
              transform: [{ scale: pressed ? 0.97 : 1 }],
            })}
            className="bg-primary py-3 rounded-full items-center"
          >
            <Text className="text-darkGreen text-base font-bold">
              {customer ? t("signOut") : t("signIn")}
            </Text>
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
              onPress={() => handleMenuPress(item.action)}
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

        {/* Account deletion — must be reachable from inside the app, not just a web page */}
        <Pressable
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
            setConfirmDelete(true);
          }}
          style={({ pressed }) => ({
            opacity: pressed ? 0.7 : 1,
            flexDirection: isRTL ? "row-reverse" : "row",
            alignItems: "center",
            gap: 16,
            backgroundColor: colors.surface,
            borderRadius: 12,
            padding: 16,
            marginTop: 8,
            borderWidth: 1,
            borderColor: colors.error,
          })}
        >
          <View className="w-10 h-10 rounded-full items-center justify-center" style={{ backgroundColor: colors.background }}>
            <IconSymbol name="trash" size={20} color={colors.error} />
          </View>
          <View style={{ flex: 1, gap: 4 }}>
            <Text
              className="text-base font-semibold"
              style={{ color: colors.error, textAlign: isRTL ? "right" : "left" }}
            >
              {t("deleteAccount")}
            </Text>
            <Text
              className="text-muted text-sm"
              style={{ textAlign: isRTL ? "right" : "left" }}
            >
              {t("deleteAccountSubtitle")}
            </Text>
          </View>
          <IconSymbol
            name={isRTL ? "chevron.left" : "chevron.right"}
            size={20}
            color={colors.muted}
          />
        </Pressable>

        <View className="mt-8 items-center gap-2">
          <Text className="text-muted text-sm">{t("version")}</Text>
          <Text className="text-muted text-xs">{t("copyright")}</Text>
        </View>
      </ScrollView>

      <Modal
        visible={confirmDelete}
        transparent
        animationType="fade"
        onRequestClose={() => setConfirmDelete(false)}
      >
        <View className="flex-1 items-center justify-center px-6" style={{ backgroundColor: "rgba(0,0,0,0.55)" }}>
          <View
            className="w-full max-w-[420px] p-6 gap-4"
            style={{
              backgroundColor: colors.surface,
              borderRadius: 24,
              borderWidth: 1,
              borderColor: colors.border,
            }}
          >
            <Text className="text-foreground text-xl font-bold">
              {customer ? t("deleteAccountTitle") : t("notSignedInDeleteTitle")}
            </Text>
            <Text className="text-muted text-sm" style={{ lineHeight: 21 }}>
              {customer ? t("deleteAccountBody") : t("notSignedInDeleteBody")}
            </Text>
            <Pressable
              disabled={deleting}
              onPress={() => void runDeleteAccount()}
              style={({ pressed }) => ({
                opacity: pressed || deleting ? 0.7 : 1,
                backgroundColor: colors.error,
                borderRadius: 14,
                paddingVertical: 16,
                alignItems: "center",
              })}
            >
              <Text className="text-base font-bold" style={{ color: "#FFFFFF" }}>
                {deleting
                  ? t("deleteAccountSubmitting")
                  : customer
                    ? t("deleteAccountConfirm")
                    : t("wipeDeviceData")}
              </Text>
            </Pressable>
            <Pressable
              onPress={() => setConfirmDelete(false)}
              style={({ pressed }) => ({ opacity: pressed ? 0.7 : 1, alignItems: "center", paddingVertical: 12 })}
            >
              <Text className="text-foreground text-base font-semibold">
                {t("deleteAccountCancel")}
              </Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </ScreenContainer>
  );
}

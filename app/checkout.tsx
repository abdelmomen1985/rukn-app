import { View, ScrollView, TextInput, Pressable } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { CTAButton } from "@/components/cta-button";
import { useStoreCatalog } from "@/hooks/use-store-catalog";
import { getCustomerToken, getMe, placeOrder } from "@/lib/medusa";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useRouter } from "expo-router";
import { useEffect, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";

export default function CheckoutScreen() {
  const colors = useColors();
  const { t, isRTL } = useI18n();
  const router = useRouter();
  const { products } = useStoreCatalog();

  const [cartIds, setCartIds] = useState<string[]>([]);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [city, setCity] = useState("");
  const [address, setAddress] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [orderNumber, setOrderNumber] = useState<string | null>(null);

  useEffect(() => {
    AsyncStorage.getItem("cart")
      .then((data) => setCartIds(data ? JSON.parse(data) : []))
      .catch(() => setCartIds([]));
    // Prefill from the logged-in customer, if any.
    getCustomerToken().then((token) => {
      if (!token) return;
      getMe()
        .then((customer) => {
          setEmail((v) => v || customer.email);
          setName((v) => v || [customer.first_name, customer.last_name].filter(Boolean).join(" "));
          setPhone((v) => v || customer.phone || "");
        })
        .catch(() => {
          // Stale token — guest checkout still works.
        });
    });
  }, []);

  const cartProducts = products.filter((p) => cartIds.includes(p.id));
  const orderable = cartProducts.filter((p) => p.variantId);
  const total = cartProducts.reduce((sum, p) => sum + p.price, 0);
  const canSubmit =
    orderable.length > 0 && name && email && phone && city && address && !submitting;

  async function handlePlaceOrder() {
    if (!canSubmit) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setSubmitting(true);
    setError(null);
    try {
      const order = await placeOrder(
        orderable.map((p) => ({ variantId: p.variantId!, quantity: 1 })),
        { name, email, phone, city, address },
      );
      await AsyncStorage.setItem("cart", JSON.stringify([]));
      setOrderNumber(`#${order.displayId}`);
    } catch {
      setError(t("orderFailed"));
    } finally {
      setSubmitting(false);
    }
  }

  const inputStyle = {
    backgroundColor: colors.surface,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    color: colors.foreground,
    fontSize: 15,
    textAlign: (isRTL ? "right" : "left") as "right" | "left",
  };

  // Success view
  if (orderNumber) {
    return (
      <ScreenContainer className="bg-background">
        <View className="flex-1 items-center justify-center px-8 gap-4">
          <IconSymbol name="checkmark.circle" size={72} color={colors.primary} />
          <Text className="text-foreground text-2xl font-bold text-center">
            {t("orderSuccessTitle")}
          </Text>
          <Text className="text-muted text-base text-center">
            {t("orderSuccessSubtitle")}
          </Text>
          <View className="bg-surface rounded-xl px-6 py-4 items-center gap-1">
            <Text className="text-muted text-xs">{t("orderNumberLabel")}</Text>
            <Text className="text-foreground text-xl font-bold">{orderNumber}</Text>
          </View>
          <CTAButton
            title={t("continueShopping")}
            onPress={() => router.replace("/(tabs)")}
          />
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer className="bg-background">
      {/* Header */}
      <View
        style={{
          flexDirection: isRTL ? "row-reverse" : "row",
          alignItems: "center",
          gap: 12,
          paddingHorizontal: 24,
          paddingVertical: 16,
        }}
      >
        <Pressable
          onPress={() => router.back()}
          style={({ pressed }) => ({
            opacity: pressed ? 0.6 : 1,
            width: 36,
            height: 36,
            borderRadius: 18,
            backgroundColor: colors.surface,
            alignItems: "center",
            justifyContent: "center",
          })}
        >
          <IconSymbol
            name={isRTL ? "chevron.right" : "chevron.left"}
            size={20}
            color={colors.foreground}
          />
        </Pressable>
        <Text className="text-foreground text-xl font-bold">{t("checkout")}</Text>
      </View>

      <ScrollView
        contentContainerStyle={{ padding: 24, gap: 14 }}
        showsVerticalScrollIndicator={false}
      >
        {orderable.length < cartProducts.length && (
          <Text className="text-muted text-sm">{t("demoItemsInCart")}</Text>
        )}

        <TextInput
          style={inputStyle}
          placeholder={t("fullName")}
          placeholderTextColor={colors.muted}
          value={name}
          onChangeText={setName}
        />
        <TextInput
          style={inputStyle}
          placeholder={t("email")}
          placeholderTextColor={colors.muted}
          keyboardType="email-address"
          autoCapitalize="none"
          value={email}
          onChangeText={setEmail}
        />
        <TextInput
          style={inputStyle}
          placeholder={t("phoneNumber")}
          placeholderTextColor={colors.muted}
          keyboardType="phone-pad"
          value={phone}
          onChangeText={setPhone}
        />
        <TextInput
          style={inputStyle}
          placeholder={t("city")}
          placeholderTextColor={colors.muted}
          value={city}
          onChangeText={setCity}
        />
        <TextInput
          style={[inputStyle, { minHeight: 80 }]}
          placeholder={t("deliveryAddress")}
          placeholderTextColor={colors.muted}
          multiline
          value={address}
          onChangeText={setAddress}
        />

        {/* Summary */}
        <View className="bg-surface rounded-xl p-4 gap-2">
          {cartProducts.map((p) => (
            <View
              key={p.id}
              style={{
                flexDirection: isRTL ? "row-reverse" : "row",
                justifyContent: "space-between",
              }}
            >
              <Text className="text-muted text-sm" numberOfLines={1} style={{ flex: 1 }}>
                {p.name}
              </Text>
              <Text className="text-foreground text-sm font-semibold">
                {p.currency === "SAR" ? `${p.price.toLocaleString()} ر.س` : `$${p.price.toFixed(2)}`}
              </Text>
            </View>
          ))}
          <View
            style={{
              flexDirection: isRTL ? "row-reverse" : "row",
              justifyContent: "space-between",
              borderTopWidth: 1,
              borderTopColor: colors.border,
              paddingTop: 8,
              marginTop: 4,
            }}
          >
            <Text className="text-foreground text-base font-bold">{t("cartTotal")}</Text>
            <Text className="text-primary text-base font-bold">
              {total.toLocaleString()} ر.س
            </Text>
          </View>
        </View>

        {error && <Text style={{ color: colors.error }}>{error}</Text>}

        <CTAButton
          title={submitting ? "…" : t("placeOrder")}
          onPress={handlePlaceOrder}
          disabled={!canSubmit}
        />
      </ScrollView>
    </ScreenContainer>
  );
}

import { View, TextInput, Pressable, ScrollView } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { CTAButton } from "@/components/cta-button";
import { login, register } from "@/lib/medusa";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useRouter } from "expo-router";
import { useState } from "react";
import * as Haptics from "expo-haptics";

type Mode = "login" | "register";

export default function AuthScreen() {
  const colors = useColors();
  const { t, isRTL } = useI18n();
  const router = useRouter();

  const [mode, setMode] = useState<Mode>("login");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(false);

  const canSubmit =
    email &&
    password.length >= 8 &&
    (mode === "login" || (firstName && lastName)) &&
    !busy;

  async function handleSubmit() {
    if (!canSubmit) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setBusy(true);
    setError(false);
    try {
      if (mode === "login") {
        await login(email, password);
      } else {
        await register({ email, password, firstName, lastName, phone: phone || undefined });
      }
      router.back();
    } catch {
      setError(true);
    } finally {
      setBusy(false);
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
        <Text className="text-foreground text-xl font-bold">
          {mode === "login" ? t("signIn") : t("createAccount")}
        </Text>
      </View>

      <ScrollView
        contentContainerStyle={{ padding: 24, gap: 14 }}
        showsVerticalScrollIndicator={false}
      >
        {mode === "register" && (
          <>
            <TextInput
              style={inputStyle}
              placeholder={t("firstName")}
              placeholderTextColor={colors.muted}
              value={firstName}
              onChangeText={setFirstName}
            />
            <TextInput
              style={inputStyle}
              placeholder={t("lastName")}
              placeholderTextColor={colors.muted}
              value={lastName}
              onChangeText={setLastName}
            />
            <TextInput
              style={inputStyle}
              placeholder={t("phoneNumber")}
              placeholderTextColor={colors.muted}
              keyboardType="phone-pad"
              value={phone}
              onChangeText={setPhone}
            />
          </>
        )}
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
          placeholder={t("password")}
          placeholderTextColor={colors.muted}
          secureTextEntry
          value={password}
          onChangeText={setPassword}
        />

        {error && <Text style={{ color: colors.error }}>{t("authFailed")}</Text>}

        <CTAButton
          title={busy ? "…" : mode === "login" ? t("signIn") : t("createAccount")}
          onPress={handleSubmit}
          disabled={!canSubmit}
        />

        <Pressable
          onPress={() => {
            setError(false);
            setMode(mode === "login" ? "register" : "login");
          }}
          style={({ pressed }) => ({ opacity: pressed ? 0.6 : 1 })}
        >
          <Text className="text-primary text-sm text-center font-semibold">
            {mode === "login" ? t("needAccount") : t("haveAccount")}
          </Text>
        </Pressable>
      </ScrollView>
    </ScreenContainer>
  );
}

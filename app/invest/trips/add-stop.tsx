import { View, ScrollView, Pressable, TextInput, Alert, Platform, Switch } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useTrips } from "@/lib/trips-provider";
import { usePortfolio } from "@/lib/portfolio-provider";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useMemo, useState } from "react";
import * as Haptics from "expo-haptics";
import {
  evaluateFairPrice,
  TRIP_PURITIES,
  type FairnessVerdict,
  type Origin,
} from "@/data/market-trips";
import { formatSAR, getPurePerGramSAR } from "@/lib/portfolio-utils";

const FALLBACK_PURE_PER_GRAM_SAR = 428; // 24K mid-market reference if spot fetch is unavailable

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  const colors = useColors();
  return (
    <View style={{ gap: 8 }}>
      <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "700", textTransform: "uppercase", letterSpacing: 0.5 }}>
        {title}
      </Text>
      {children}
    </View>
  );
}

function BannerForVerdict({ verdict }: { verdict: FairnessVerdict }) {
  const { t } = useI18n();
  const { bg, border, text, label, hint, icon } =
    verdict === "excellent"
      ? {
          bg: "#22C55E",
          border: "#16A34A",
          text: "#FFFFFF",
          label: t("excellentDealBanner"),
          hint: t("fairPriceHintExcellent"),
          icon: "checkmark.circle" as const,
        }
      : verdict === "fair"
        ? {
            bg: "#0EA5E910",
            border: "#0EA5E9",
            text: "#0369A1",
            label: t("fairDealBanner"),
            hint: t("fairPriceHintFair"),
            icon: "checkmark.circle" as const,
          }
        : {
            bg: "#FEF3C7",
            border: "#F59E0B",
            text: "#92400E",
            label: t("highDealBanner"),
            hint: t("fairPriceHintHigh"),
            icon: "info.circle" as const,
          };

  return (
    <View
      style={{
        backgroundColor: bg,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: border,
        paddingHorizontal: 14,
        paddingVertical: 12,
        flexDirection: "row",
        alignItems: "center",
        gap: 10,
      }}
    >
      <IconSymbol name={icon} size={22} color={text} />
      <View style={{ flex: 1 }}>
        <Text style={{ color: text, fontSize: 15, fontWeight: "800" }}>{label}</Text>
        <Text style={{ color: text, opacity: 0.85, fontSize: 12, marginTop: 2 }}>{hint}</Text>
      </View>
    </View>
  );
}

export default function AddStopScreen() {
  const colors = useColors();
  const router = useRouter();
  const { t, lang, isRTL } = useI18n();
  const { tripId } = useLocalSearchParams<{ tripId: string }>();
  const { getTripById, addStop } = useTrips();
  const { spotPrices } = usePortfolio();
  const trip = getTripById(tripId);

  // Default purity matches trip default
  const initialPurityIdx = useMemo(() => {
    if (!trip) return 2;
    const idx = TRIP_PURITIES.findIndex((p) => p.label === trip.purityLabel);
    return idx >= 0 ? idx : 2;
  }, [trip]);

  const [storeName, setStoreName] = useState("");
  const [location, setLocation] = useState("");
  const [purityIdx, setPurityIdx] = useState(initialPurityIdx);
  const [origin, setOrigin] = useState<Origin>("local");
  const [weight, setWeight] = useState(trip?.weightGrams ? String(trip.weightGrams) : "");
  const [price, setPrice] = useState("");
  const [vatIncluded, setVatIncluded] = useState(false);

  const purity = TRIP_PURITIES[purityIdx];
  const weightNum = parseFloat(weight) || 0;
  const priceNum = parseFloat(price) || 0;

  // Pure per-gram SAR — from spot prices if available, otherwise a sensible fallback.
  const purePerGramSAR = spotPrices ? getPurePerGramSAR(spotPrices, "XAU") : FALLBACK_PURE_PER_GRAM_SAR;

  const evaluation = useMemo(() => {
    if (priceNum <= 0 || weightNum <= 0) return null;
    return evaluateFairPrice({
      totalPriceSAR: priceNum,
      weightGrams: weightNum,
      purityFactor: purity.factor,
      vatIncluded,
      purePerGramSAR,
    });
  }, [priceNum, weightNum, purity.factor, vatIncluded, purePerGramSAR]);

  if (!trip) {
    return (
      <ScreenContainer className="bg-background">
        <View style={{ flex: 1, alignItems: "center", justifyContent: "center" }}>
          <Text style={{ color: colors.muted }}>{t("tripsEmptyTitle")}</Text>
        </View>
      </ScreenContainer>
    );
  }

  const handleSave = async () => {
    if (!storeName.trim()) {
      Alert.alert(t("storeName"), t("storeNamePlaceholder"));
      return;
    }
    if (!evaluation) {
      Alert.alert(t("storeQuotedPrice"), t("storeQuotedPrice"));
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    await addStop(trip.id, {
      storeName: storeName.trim(),
      location: location.trim() || undefined,
      totalPriceSAR: priceNum,
      weightGrams: weightNum,
      purityLabel: purity.label,
      purityFactor: purity.factor,
      vatIncluded,
      origin,
      visitedAt: new Date().toISOString(),
      verdict: evaluation.verdict,
      makingPerGramSAR: evaluation.makingPerGramSAR,
      marketReferencePerGramSAR: evaluation.marketReferencePerGramSAR,
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.back();
  };

  return (
    <ScreenContainer className="bg-background">
      {/* Header */}
      <View
        style={{
          flexDirection: "row",
          alignItems: "center",
          paddingHorizontal: 16,
          paddingVertical: 12,
          borderBottomWidth: 0.5,
          borderBottomColor: colors.border,
          gap: 12,
        }}
      >
        <Pressable
          onPress={() => router.back()}
          testID="back-button"
          style={({ pressed }) => ({ opacity: pressed ? 0.7 : 1, padding: 4 })}
        >
          <IconSymbol name="chevron.left" size={24} color={colors.foreground} />
        </Pressable>
        <View style={{ flex: 1 }}>
          <Text style={{ color: colors.foreground, fontSize: 17, fontWeight: "700" }}>
            {t("addStopTitle")}
          </Text>
          <Text style={{ color: colors.muted, fontSize: 12 }} numberOfLines={1}>
            {trip.name}
          </Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, gap: 20, paddingBottom: 24 }}>
        {/* Store name */}
        <Section title={t("storeName")}>
          <TextInput
            value={storeName}
            onChangeText={setStoreName}
            placeholder={t("storeNamePlaceholder")}
            placeholderTextColor={colors.muted}
            testID="store-name-input"
            style={{
              backgroundColor: colors.surface,
              borderWidth: 1,
              borderColor: colors.border,
              borderRadius: 12,
              paddingHorizontal: 14,
              paddingVertical: Platform.OS === "ios" ? 14 : 10,
              color: colors.foreground,
              fontSize: 15,
              textAlign: isRTL ? "right" : "left",
            }}
          />
        </Section>

        {/* Location */}
        <Section title={t("storeLocation")}>
          <TextInput
            value={location}
            onChangeText={setLocation}
            placeholder={t("storeLocationPlaceholder")}
            placeholderTextColor={colors.muted}
            testID="store-location-input"
            style={{
              backgroundColor: colors.surface,
              borderWidth: 1,
              borderColor: colors.border,
              borderRadius: 12,
              paddingHorizontal: 14,
              paddingVertical: Platform.OS === "ios" ? 14 : 10,
              color: colors.foreground,
              fontSize: 15,
              textAlign: isRTL ? "right" : "left",
            }}
          />
        </Section>

        {/* Purity */}
        <Section title={t("tripPurity")}>
          <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
            {TRIP_PURITIES.map((p, idx) => {
              const active = idx === purityIdx;
              return (
                <Pressable
                  key={p.label}
                  onPress={() => {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                    setPurityIdx(idx);
                  }}
                  testID={`purity-${p.label}`}
                  style={{
                    paddingHorizontal: 18,
                    paddingVertical: 12,
                    borderRadius: 14,
                    backgroundColor: active ? "#A4313F" : colors.surface,
                    borderWidth: 1,
                    borderColor: active ? "#A4313F" : colors.border,
                    minWidth: 80,
                    alignItems: "center",
                    gap: 2,
                  }}
                >
                  <Text style={{ color: active ? "#FFFFFF" : colors.foreground, fontSize: 14, fontWeight: "800" }}>
                    {p.label}
                  </Text>
                  <Text style={{ color: active ? "#FFFFFF" : colors.muted, fontSize: 10, opacity: 0.8 }}>
                    {(purePerGramSAR * p.factor).toFixed(0)} {lang === "ar" ? "ر.س/غ" : "SAR/g"}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </Section>

        {/* Origin */}
        <Section title={t("storeMakingOrigin")}>
          <View style={{ flexDirection: "row", gap: 10 }}>
            {([
              { id: "local" as Origin, label: t("originLocal"), flag: "🇸🇦" },
              { id: "imported" as Origin, label: t("originImported"), flag: "🌍" },
            ]).map((opt) => {
              const active = origin === opt.id;
              return (
                <Pressable
                  key={opt.id}
                  onPress={() => {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                    setOrigin(opt.id);
                  }}
                  testID={`origin-${opt.id}`}
                  style={({ pressed }) => ({
                    opacity: pressed ? 0.85 : 1,
                    flex: 1,
                    backgroundColor: active ? "#A4313F" : colors.surface,
                    borderRadius: 12,
                    borderWidth: 1,
                    borderColor: active ? "#A4313F" : colors.border,
                    paddingVertical: 12,
                    alignItems: "center",
                    flexDirection: "row",
                    justifyContent: "center",
                    gap: 8,
                  })}
                >
                  <Text style={{ fontSize: 16 }}>{opt.flag}</Text>
                  <Text style={{ color: active ? "#FFFFFF" : colors.foreground, fontSize: 13, fontWeight: "700" }}>
                    {opt.label}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </Section>

        {/* Weight */}
        <Section title={t("storeWeight")}>
          <TextInput
            value={weight}
            onChangeText={setWeight}
            placeholder="50"
            placeholderTextColor={colors.muted}
            keyboardType="decimal-pad"
            testID="weight-input"
            style={{
              backgroundColor: colors.surface,
              borderWidth: 1,
              borderColor: colors.border,
              borderRadius: 12,
              paddingHorizontal: 14,
              paddingVertical: Platform.OS === "ios" ? 14 : 10,
              color: colors.foreground,
              fontSize: 16,
              fontWeight: "600",
              textAlign: isRTL ? "right" : "left",
            }}
          />
        </Section>

        {/* Quoted price */}
        <Section title={t("storeQuotedPrice")}>
          <TextInput
            value={price}
            onChangeText={setPrice}
            placeholder="0"
            placeholderTextColor={colors.muted}
            keyboardType="decimal-pad"
            testID="price-input"
            style={{
              backgroundColor: colors.surface,
              borderWidth: 1,
              borderColor: "#A4313F",
              borderRadius: 12,
              paddingHorizontal: 14,
              paddingVertical: Platform.OS === "ios" ? 14 : 10,
              color: colors.foreground,
              fontSize: 16,
              fontWeight: "700",
              textAlign: isRTL ? "right" : "left",
            }}
          />
        </Section>

        {/* VAT toggle */}
        <View
          style={{
            flexDirection: "row",
            alignItems: "center",
            justifyContent: "space-between",
            backgroundColor: colors.surface,
            borderWidth: 1,
            borderColor: colors.border,
            borderRadius: 12,
            paddingHorizontal: 14,
            paddingVertical: 10,
          }}
        >
          <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "600", flex: 1 }}>
            {t("vatIncluded")}
          </Text>
          <Switch
            value={vatIncluded}
            onValueChange={(v) => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              setVatIncluded(v);
            }}
            trackColor={{ false: colors.border, true: "#A4313F" }}
            thumbColor={vatIncluded ? "#FFFFFF" : "#FFFFFF"}
            testID="vat-switch"
          />
        </View>

        {/* Evaluation banner + breakdown */}
        {evaluation && (
          <>
            <BannerForVerdict verdict={evaluation.verdict} />
            <View
              style={{
                backgroundColor: colors.surface,
                borderRadius: 16,
                borderWidth: 1,
                borderColor: colors.border,
                padding: 14,
                gap: 8,
              }}
            >
              <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                <Text style={{ color: colors.muted, fontSize: 13 }}>{t("breakdownGoldValue")}</Text>
                <Text style={{ color: colors.foreground, fontSize: 13, fontWeight: "700" }}>
                  {formatSAR(evaluation.goldValueSAR, lang)}
                </Text>
              </View>
              <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                <Text style={{ color: colors.muted, fontSize: 13 }}>{t("breakdownMaking")}</Text>
                <Text style={{ color: colors.foreground, fontSize: 13, fontWeight: "700" }}>
                  {formatSAR(evaluation.preTaxTotalSAR - evaluation.goldValueSAR, lang)}
                </Text>
              </View>
              {vatIncluded && (
                <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                  <Text style={{ color: colors.muted, fontSize: 13 }}>{t("breakdownVAT")}</Text>
                  <Text style={{ color: colors.foreground, fontSize: 13, fontWeight: "700" }}>
                    {formatSAR(evaluation.vatAmountSAR, lang)}
                  </Text>
                </View>
              )}
              <View style={{ height: 1, backgroundColor: colors.border, marginVertical: 4 }} />
              <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "700" }}>
                  {t("breakdownStorePrice")}
                </Text>
                <Text style={{ color: colors.foreground, fontSize: 16, fontWeight: "800" }}>
                  {formatSAR(priceNum, lang)}
                </Text>
              </View>
              <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                <Text style={{ color: colors.muted, fontSize: 12 }}>
                  {t("breakdownMakingPerGram")}
                </Text>
                <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "700" }}>
                  {evaluation.makingPerGramSAR.toFixed(1)} {lang === "ar" ? "ر.س/غ" : "SAR/g"}
                </Text>
              </View>
            </View>
          </>
        )}
      </ScrollView>

      {/* Save CTA */}
      <View
        style={{
          paddingHorizontal: 16,
          paddingVertical: 12,
          borderTopWidth: 0.5,
          borderTopColor: colors.border,
          backgroundColor: colors.background,
          flexDirection: "row",
          gap: 10,
        }}
      >
        <Pressable
          onPress={() => router.back()}
          testID="close-stop-button"
          style={({ pressed }) => ({
            opacity: pressed ? 0.85 : 1,
            paddingVertical: 14,
            paddingHorizontal: 18,
            borderRadius: 16,
            backgroundColor: colors.surface,
            borderWidth: 1,
            borderColor: colors.border,
            alignItems: "center",
            justifyContent: "center",
          })}
        >
          <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "700" }}>
            {t("close")}
          </Text>
        </Pressable>
        <Pressable
          onPress={handleSave}
          disabled={!evaluation || !storeName.trim()}
          testID="save-stop-button"
          style={({ pressed }) => ({
            opacity: !evaluation || !storeName.trim() ? 0.4 : pressed ? 0.85 : 1,
            flex: 1,
            backgroundColor: "#22C55E",
            paddingVertical: 14,
            borderRadius: 16,
            flexDirection: "row",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
          })}
        >
          <IconSymbol name="plus.circle.fill" size={18} color="#FFFFFF" />
          <Text style={{ color: "#FFFFFF", fontSize: 15, fontWeight: "800" }}>
            {t("addToTrip")}
          </Text>
        </Pressable>
      </View>
    </ScreenContainer>
  );
}

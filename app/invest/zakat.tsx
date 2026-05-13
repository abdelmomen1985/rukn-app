import { View, ScrollView, Pressable } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { usePortfolio } from "@/lib/portfolio-provider";
import { calculateZakat, getCurrentValueSAR, formatSAR, getGoldPerGramSAR } from "@/lib/portfolio-utils";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useRouter } from "expo-router";
import { useMemo } from "react";

function InfoRow({ label, value, highlight, color }: { label: string; value: string; highlight?: boolean; color?: string }) {
  const colors = useColors();
  return (
    <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", paddingVertical: 10 }}>
      <Text style={{ color: highlight ? colors.foreground : colors.muted, fontSize: 14, fontWeight: highlight ? "600" : "400", flex: 1 }}>
        {label}
      </Text>
      <Text style={{ color: color ?? (highlight ? colors.foreground : colors.foreground), fontSize: 14, fontWeight: highlight ? "700" : "500" }}>
        {value}
      </Text>
    </View>
  );
}

export default function ZakatScreen() {
  const { assets, spotPrices, metals } = usePortfolio();
  const colors = useColors();
  const { t, lang } = useI18n();
  const router = useRouter();

  const zakatInfo = useMemo(() => {
    if (!spotPrices) return null;
    return calculateZakat(assets, spotPrices, metals);
  }, [assets, spotPrices, metals]);

  const perAssetValues = useMemo(() => {
    if (!spotPrices) return [];
    return assets.map((a) => {
      const metal = metals.find(m => m.id === a.metalType);
      return {
        ...a,
        currentValue: metal ? getCurrentValueSAR(a, spotPrices, metal) : 0,
      };
    });
  }, [assets, spotPrices, metals]);

  const goldPerGram24KSAR = useMemo(() => {
    if (!spotPrices) return null;
    return getGoldPerGramSAR(spotPrices, 24);
  }, [spotPrices]);

  return (
    <ScreenContainer edges={["top", "left", "right", "bottom"]} className="bg-background">
      {/* Header */}
      <View
        style={{
          flexDirection: "row",
          alignItems: "center",
          gap: 12,
          paddingHorizontal: 16,
          paddingVertical: 12,
          borderBottomWidth: 0.5,
          borderBottomColor: colors.border,
        }}
      >
        <Pressable onPress={() => router.back()} style={({ pressed }) => ({ opacity: pressed ? 0.6 : 1 })}>
          <IconSymbol name="chevron.left" size={24} color={colors.foreground} />
        </Pressable>
        <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700" }}>{t("zakat")}</Text>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, gap: 16, paddingBottom: 40 }}>

        {!spotPrices && (
          <View style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 20, alignItems: "center", borderWidth: 1, borderColor: colors.border }}>
            <Text style={{ color: colors.muted, fontSize: 14 }}>{t("loadingPriceData")}</Text>
          </View>
        )}

        {zakatInfo && (
          <>
            {/* Status card */}
            <View
              style={{
                backgroundColor: zakatInfo.isAboveNisab ? "#FFFBEB" : "#F0FDF4",
                borderRadius: 20,
                padding: 20,
                alignItems: "center",
                borderWidth: 1,
                borderColor: zakatInfo.isAboveNisab ? "#FCD34D" : "#86EFAC",
                gap: 8,
              }}
            >
              <Text style={{ fontSize: 40 }}>{zakatInfo.isAboveNisab ? "⚖️" : "✅"}</Text>
              <Text style={{
                color: zakatInfo.isAboveNisab ? "#92400E" : "#166534",
                fontSize: 16,
                fontWeight: "700",
                textAlign: "center",
              }}>
                {zakatInfo.isAboveNisab ? t("nisabAlert") : t("belowNisab")}
              </Text>
              {zakatInfo.isAboveNisab && (
                <View style={{ backgroundColor: "#FEF3C7", borderRadius: 12, paddingHorizontal: 16, paddingVertical: 8, marginTop: 4 }}>
                  <Text style={{ color: "#92400E", fontSize: 13, textAlign: "center" }}>
                    {t("zakatObligatory")}
                  </Text>
                </View>
              )}
            </View>

            {/* Calculation breakdown */}
            <View style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 16, borderWidth: 1, borderColor: colors.border }}>
              <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "700", textTransform: "uppercase", letterSpacing: 0.5, marginBottom: 8 }}>
                {t("nisabCalculation")}
              </Text>
              {goldPerGram24KSAR && (
                <InfoRow label={t("goldPerGram24K")} value={formatSAR(goldPerGram24KSAR, lang)} />
              )}
              <InfoRow label={t("nisabEquals85g")} value="" />
              <View style={{ height: 1, backgroundColor: colors.border, marginVertical: 4 }} />
              <InfoRow label={t("nisabThreshold")} value={formatSAR(zakatInfo.nisabThresholdSAR, lang)} highlight />
              <InfoRow label={t("zakatableValue")} value={formatSAR(zakatInfo.totalZakatableValue, lang)} highlight />

              {zakatInfo.isAboveNisab && (
                <>
                  <View style={{ height: 1, backgroundColor: colors.border, marginVertical: 8 }} />
                  <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "700", textTransform: "uppercase", letterSpacing: 0.5, marginBottom: 8 }}>
                    {t("zakatDue25")}
                  </Text>
                  <View style={{ backgroundColor: "#07352b", borderRadius: 12, padding: 16, alignItems: "center" }}>
                    <Text style={{ color: "rgba(255,255,255,0.7)", fontSize: 13, marginBottom: 4 }}>{t("zakatDue")}</Text>
                    <Text style={{ color: "#D4AF37", fontSize: 28, fontWeight: "700" }}>
                      {formatSAR(zakatInfo.zakatDue, lang)}
                    </Text>
                    <Text style={{ color: "rgba(255,255,255,0.6)", fontSize: 12, marginTop: 4 }}>
                      {formatSAR(zakatInfo.totalZakatableValue, lang)} × 2.5%
                    </Text>
                  </View>
                </>
              )}
            </View>

            {/* Per-asset breakdown */}
            <View style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 16, borderWidth: 1, borderColor: colors.border }}>
              <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "700", textTransform: "uppercase", letterSpacing: 0.5, marginBottom: 8 }}>
                {t("assetBreakdown")}
              </Text>
              {perAssetValues.map((asset) => (
                <View key={asset.id}>
                  <InfoRow
                    label={asset.nameAr && lang === "ar" ? asset.nameAr : asset.name}
                    value={formatSAR(asset.currentValue, lang)}
                  />
                </View>
              ))}
              {perAssetValues.length === 0 && (
                <Text style={{ color: colors.muted, fontSize: 14, textAlign: "center", paddingVertical: 8 }}>
                  {t("noAssetsInPortfolio")}
                </Text>
              )}
            </View>

            {/* Disclaimer */}
            <View style={{ backgroundColor: colors.surface, borderRadius: 12, padding: 14, borderWidth: 1, borderColor: colors.border }}>
              <View style={{ flexDirection: "row", gap: 8, alignItems: "flex-start" }}>
                <IconSymbol name="info.circle" size={16} color={colors.muted} />
                <Text style={{ color: colors.muted, fontSize: 12, flex: 1, lineHeight: 18 }}>
                  {t("disclaimer")}
                </Text>
              </View>
            </View>
          </>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}

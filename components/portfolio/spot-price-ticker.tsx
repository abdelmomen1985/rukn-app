import { View, Pressable, ActivityIndicator, ScrollView } from "react-native";
import { Text } from "@/components/ui/text";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { usePortfolio } from "@/lib/portfolio-provider";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { getPurePerGramSAR } from "@/lib/portfolio-utils";
import * as Haptics from "expo-haptics";

const USD_TO_SAR = 3.75;
const GRAMS_PER_OZ = 31.1035;

export function SpotPriceTicker() {
  const { metals, spotPrices, isLoadingPrices, isOffline, refreshPrices } = usePortfolio();
  const colors = useColors();
  const { t } = useI18n();

  // Only show metals that have an API symbol (i.e., live price)
  const pricedMetals = metals.filter((m) => m.apiSymbol);

  const lastUpdatedText = () => {
    if (!spotPrices) return "";
    const diff = Math.floor((Date.now() - new Date(spotPrices.fetchedAt).getTime()) / 1000);
    if (diff < 60) return `${diff}s ago`;
    return `${Math.floor(diff / 60)}m ago`;
  };

  const handleRefresh = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    refreshPrices();
  };

  return (
    <View
      style={{
        backgroundColor: colors.surface,
        borderRadius: 16,
        padding: 16,
        marginHorizontal: 16,
        marginTop: 12,
        borderWidth: 1,
        borderColor: colors.border,
      }}
    >
      {/* Header row */}
      <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
        <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
          {isOffline && <IconSymbol name="wifi.slash" size={14} color={colors.warning} />}
          <Text style={{ color: colors.muted, fontSize: 12 }}>
            {isOffline ? "Offline · " : ""}{t("lastUpdated")}: {lastUpdatedText()}
          </Text>
        </View>
        <Pressable
          onPress={handleRefresh}
          style={({ pressed }) => ({ opacity: pressed ? 0.6 : 1, padding: 4 })}
        >
          {isLoadingPrices ? (
            <ActivityIndicator size="small" color={colors.primary} />
          ) : (
            <IconSymbol name="arrow.clockwise" size={16} color={colors.primary} />
          )}
        </Pressable>
      </View>

      {/* Scrollable metal price chips */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 10 }}>
        {pricedMetals.map((metal) => {
          const perGramSAR = spotPrices
            ? getPurePerGramSAR(spotPrices, metal.apiSymbol)
            : null;

          return (
            <View
              key={metal.id}
              style={{
                minWidth: 110,
                backgroundColor: metal.bgColor,
                borderRadius: 12,
                padding: 12,
                borderWidth: 1,
                borderColor: metal.borderColor,
              }}
            >
              <View style={{ flexDirection: "row", alignItems: "center", gap: 4, marginBottom: 4 }}>
                <Text style={{ fontSize: 14 }}>{metal.emoji}</Text>
                <Text style={{ color: metal.textColor, fontSize: 11, fontWeight: "600" }}>
                  {metal.name}
                </Text>
              </View>
              <Text style={{ color: metal.textColor, fontSize: 17, fontWeight: "700" }}>
                {perGramSAR ? perGramSAR.toFixed(2) : "—"}
              </Text>
              <Text style={{ color: metal.textColor, fontSize: 10, opacity: 0.7 }}>
                SAR{t("perGram")}
              </Text>
            </View>
          );
        })}
      </ScrollView>
    </View>
  );
}

import { View, Pressable } from "react-native";
import { Text } from "@/components/ui/text";
import { IconSymbol } from "@/components/ui/icon-symbol";
import type { PortfolioAsset } from "@/data/portfolio";
import { usePortfolio } from "@/lib/portfolio-provider";
import { useColors } from "@/hooks/use-colors";
import { formatSAR, getWeightInGrams } from "@/lib/portfolio-utils";
import { useI18n } from "@/lib/i18n";
import * as Haptics from "expo-haptics";

interface AssetCardProps {
  asset: PortfolioAsset;
  onPress: (asset: PortfolioAsset) => void;
}

const CATEGORY_ICONS: Record<string, string> = {
  ring: "⭕",
  bracelet: "🔗",
  necklace: "📿",
  earring: "💎",
  bar: "🟨",
  coin: "🪙",
};

export function AssetCard({ asset, onPress }: AssetCardProps) {
  const { getAssetCurrentValue, getMetalById } = usePortfolio();
  const colors = useColors();
  const { lang } = useI18n();

  const metal = getMetalById(asset.metalType);
  const currentValue = getAssetCurrentValue(asset);
  const totalCost = asset.purchasePrice + asset.makingCharges + asset.vatAmount;
  const gainLoss = currentValue - totalCost;
  const isPositive = gainLoss >= 0;
  const pctReturn = totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;
  const weightGrams = getWeightInGrams(asset.weightValue, asset.weightUnit);
  const displayName = lang === "ar" && asset.nameAr ? asset.nameAr : asset.name;

  return (
    <Pressable
      onPress={() => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        onPress(asset);
      }}
      style={({ pressed }) => ({
        opacity: pressed ? 0.85 : 1,
        transform: [{ scale: pressed ? 0.98 : 1 }],
      })}
    >
      <View
        style={{
          backgroundColor: colors.surface,
          borderRadius: 14,
          padding: 14,
          marginBottom: 8,
          flexDirection: "row",
          alignItems: "center",
          gap: 12,
          borderWidth: 1,
          borderColor: colors.border,
        }}
      >
        {/* Metal icon circle */}
        <View
          style={{
            width: 44,
            height: 44,
            borderRadius: 22,
            backgroundColor: metal?.bgColor ?? "#F5F5F5",
            alignItems: "center",
            justifyContent: "center",
            borderWidth: 1,
            borderColor: metal?.borderColor ?? "#DDD",
          }}
        >
          <Text style={{ fontSize: 20 }}>{CATEGORY_ICONS[asset.category] ?? "💍"}</Text>
        </View>

        {/* Asset info */}
        <View style={{ flex: 1, gap: 2 }}>
          <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "600" }} numberOfLines={1}>
            {displayName}
          </Text>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
            {metal && (
              <View
                style={{
                  backgroundColor: metal.bgColor,
                  paddingHorizontal: 6,
                  paddingVertical: 2,
                  borderRadius: 6,
                  borderWidth: 1,
                  borderColor: metal.borderColor,
                }}
              >
                <Text style={{ color: metal.textColor, fontSize: 11, fontWeight: "600" }}>
                  {metal.emoji} {asset.purityLabel}
                </Text>
              </View>
            )}
            <Text style={{ color: colors.muted, fontSize: 12 }}>
              {weightGrams.toFixed(1)}g
            </Text>
          </View>
        </View>

        {/* Value & P&L */}
        <View style={{ alignItems: "flex-end", gap: 2 }}>
          <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "700" }}>
            {formatSAR(currentValue, lang)}
          </Text>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 2 }}>
            <IconSymbol
              name={isPositive ? "arrow.up.right" : "arrow.down.right"}
              size={10}
              color={isPositive ? "#16a34a" : "#dc2626"}
            />
            <Text style={{ color: isPositive ? "#16a34a" : "#dc2626", fontSize: 12, fontWeight: "600" }}>
              {isPositive ? "+" : ""}{pctReturn.toFixed(1)}%
            </Text>
          </View>
        </View>

        <IconSymbol name="chevron.right" size={16} color={colors.muted} />
      </View>
    </Pressable>
  );
}

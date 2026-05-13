import { View, ScrollView, Pressable, Alert } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { PnLBreakdown } from "@/components/portfolio/pnl-breakdown";
import { usePortfolio } from "@/lib/portfolio-provider";
import { calculatePnL, formatSAR, getWeightInGrams, getWeightUnitLabel } from "@/lib/portfolio-utils";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useRouter, useLocalSearchParams } from "expo-router";
import * as Haptics from "expo-haptics";

const CATEGORY_ICONS: Record<string, string> = {
  ring: "⭕",
  bracelet: "🔗",
  necklace: "📿",
  earring: "💎",
  bar: "🟨",
  coin: "🪙",
};

export default function AssetDetailScreen() {
  const { assets, spotPrices, deleteAsset } = usePortfolio();
  const colors = useColors();
  const { t, lang } = useI18n();
  const router = useRouter();
  const { assetId } = useLocalSearchParams<{ assetId: string }>();

  const asset = assets.find((a) => a.id === assetId);

  if (!asset) {
    return (
      <ScreenContainer edges={["top", "left", "right", "bottom"]} className="bg-background">
        <View style={{ flex: 1, alignItems: "center", justifyContent: "center" }}>
          <Text style={{ color: colors.muted }}>{t("assetNotFound")}</Text>
        </View>
      </ScreenContainer>
    );
  }

  const displayName = lang === "ar" && asset.nameAr ? asset.nameAr : asset.name;
  const pnl = spotPrices ? calculatePnL(asset, spotPrices) : null;
  const weightGrams = getWeightInGrams(asset.weightValue, asset.weightUnit);
  const purityLabel = asset.metalType === "gold" ? `${asset.karat}K Gold` : `${asset.silverPurity} Silver`;
  const purchasedOn = new Date(asset.purchaseDate).toLocaleDateString(lang === "ar" ? "ar-SA" : "en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  const handleDelete = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    Alert.alert(
      t("deleteAsset"),
      `${t("deleteConfirm")} "${displayName}"?`,
      [
        { text: t("cancel"), style: "cancel" },
        {
          text: t("deleteAsset"),
          style: "destructive",
          onPress: async () => {
            await deleteAsset(asset.id);
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            router.back();
          },
        },
      ],
    );
  };

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
        <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700", flex: 1 }} numberOfLines={1}>
          {displayName}
        </Text>
        {/* Edit button */}
        <Pressable
          onPress={() => router.push({ pathname: "/invest/add-asset", params: { assetId: asset.id } })}
          style={({ pressed }) => ({
            opacity: pressed ? 0.6 : 1,
            width: 36,
            height: 36,
            borderRadius: 18,
            backgroundColor: colors.surface,
            alignItems: "center",
            justifyContent: "center",
            borderWidth: 1,
            borderColor: colors.border,
          })}
        >
          <IconSymbol name="pencil" size={16} color={colors.foreground} />
        </Pressable>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, gap: 16, paddingBottom: 40 }}>
        {/* Asset hero */}
        <View
          style={{
            backgroundColor: asset.metalType === "gold" ? "#FFF9E6" : "#F5F5F5",
            borderRadius: 20,
            padding: 20,
            alignItems: "center",
            borderWidth: 1,
            borderColor: asset.metalType === "gold" ? "#F5D766" : "#C0C0C0",
          }}
        >
          <Text style={{ fontSize: 48, marginBottom: 8 }}>{CATEGORY_ICONS[asset.category] ?? "💍"}</Text>
          <Text style={{ fontSize: 20, fontWeight: "700", color: asset.metalType === "gold" ? "#5A460A" : "#333", marginBottom: 4 }}>
            {displayName}
          </Text>
          <View style={{ flexDirection: "row", gap: 8, flexWrap: "wrap", justifyContent: "center" }}>
            <View style={{ backgroundColor: asset.metalType === "gold" ? "#FEF3C7" : "#E5E7EB", paddingHorizontal: 10, paddingVertical: 4, borderRadius: 20 }}>
              <Text style={{ color: asset.metalType === "gold" ? "#92400E" : "#374151", fontSize: 13, fontWeight: "600" }}>
                {purityLabel}
              </Text>
            </View>
            <View style={{ backgroundColor: colors.surface, paddingHorizontal: 10, paddingVertical: 4, borderRadius: 20, borderWidth: 1, borderColor: colors.border }}>
              <Text style={{ color: colors.muted, fontSize: 13 }}>
                {weightGrams.toFixed(2)}g
              </Text>
            </View>
            <View style={{ backgroundColor: colors.surface, paddingHorizontal: 10, paddingVertical: 4, borderRadius: 20, borderWidth: 1, borderColor: colors.border }}>
              <Text style={{ color: colors.muted, fontSize: 13 }}>
                {t(asset.category as any)}
              </Text>
            </View>
          </View>
        </View>

        {/* Weight detail */}
        <View
          style={{
            backgroundColor: colors.surface,
            borderRadius: 16,
            padding: 16,
            borderWidth: 1,
            borderColor: colors.border,
          }}
        >
          <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "600", textTransform: "uppercase", letterSpacing: 0.5, marginBottom: 12 }}>
            {t("details")}
          </Text>
          <View style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 }}>
            <Text style={{ color: colors.muted, fontSize: 14 }}>{t("weight")}</Text>
            <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "600" }}>
              {asset.weightValue} {asset.weightUnit} ({weightGrams.toFixed(2)}g)
            </Text>
          </View>
          <View style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 }}>
            <Text style={{ color: colors.muted, fontSize: 14 }}>{t("purity")}</Text>
            <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "600" }}>{purityLabel}</Text>
          </View>
          <View style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 }}>
            <Text style={{ color: colors.muted, fontSize: 14 }}>{t("purchaseDate")}</Text>
            <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "600" }}>{purchasedOn}</Text>
          </View>
          {asset.notes && (
            <View style={{ paddingVertical: 6 }}>
              <Text style={{ color: colors.muted, fontSize: 14, marginBottom: 2 }}>{t("notes")}</Text>
              <Text style={{ color: colors.foreground, fontSize: 14 }}>{asset.notes}</Text>
            </View>
          )}
        </View>

        {/* P&L breakdown */}
        {pnl ? (
          <PnLBreakdown
            pnl={pnl}
            purchasePrice={asset.purchasePrice}
            makingCharges={asset.makingCharges}
            vatAmount={asset.vatAmount}
          />
        ) : (
          <View style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 20, alignItems: "center", borderWidth: 1, borderColor: colors.border }}>
            <Text style={{ color: colors.muted, fontSize: 14 }}>{t("loadingPriceData")}</Text>
          </View>
        )}

        {/* Delete button */}
        <Pressable
          onPress={handleDelete}
          style={({ pressed }) => ({
            opacity: pressed ? 0.7 : 1,
            borderRadius: 14,
            paddingVertical: 14,
            alignItems: "center",
            borderWidth: 1,
            borderColor: "#dc2626",
          })}
        >
          <Text style={{ color: "#dc2626", fontSize: 15, fontWeight: "600" }}>
            {t("deleteAsset")}
          </Text>
        </Pressable>
      </ScrollView>
    </ScreenContainer>
  );
}

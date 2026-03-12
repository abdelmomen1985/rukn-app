import { View, ScrollView, Pressable, RefreshControl } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { SpotPriceTicker } from "@/components/portfolio/spot-price-ticker";
import { PortfolioSummaryCard } from "@/components/portfolio/portfolio-summary-card";
import { PortfolioPieChart } from "@/components/portfolio/pie-chart";
import { AssetCard } from "@/components/portfolio/asset-card";
import { SortFilterBar, type SortKey, type FilterKey } from "@/components/portfolio/sort-filter-bar";
import { NisabAlertBanner } from "@/components/portfolio/nisab-alert-banner";
import { usePortfolio } from "@/lib/portfolio-provider";
import { calculateZakat, getCurrentValueSAR } from "@/lib/portfolio-utils";
import { useI18n } from "@/lib/i18n";
import { useColors } from "@/hooks/use-colors";
import { useRouter } from "expo-router";
import { useState, useMemo } from "react";
import type { PortfolioAsset } from "@/data/portfolio";
import * as Haptics from "expo-haptics";

export default function PortfolioScreen() {
  const { assets, metals, spotPrices, refreshPrices, isLoadingPrices, getSummary, getAssetCurrentValue } = usePortfolio();
  const { t } = useI18n();
  const colors = useColors();
  const router = useRouter();
  const [sort, setSort] = useState<SortKey>("value");
  const [filter, setFilter] = useState<FilterKey>("all");
  const [refreshing, setRefreshing] = useState(false);

  const summary = getSummary();

  const zakatInfo = useMemo(() => {
    if (!spotPrices) return null;
    return calculateZakat(assets, spotPrices, metals);
  }, [assets, spotPrices, metals]);

  const showNisabAlert = zakatInfo?.isAboveNisab ?? false;

  // Pie chart entries — one per metal that has any value
  const pieEntries = useMemo(() => {
    return metals
      .map((m) => ({ metal: m, value: summary.metalValues[m.id] ?? 0 }))
      .filter((e) => e.value > 0);
  }, [metals, summary.metalValues]);

  // Filtered & sorted assets
  const displayedAssets = useMemo(() => {
    const filtered = filter === "all" ? assets : assets.filter((a) => a.metalType === filter);
    return [...filtered].sort((a, b) => {
      if (sort === "value") return getAssetCurrentValue(b) - getAssetCurrentValue(a);
      if (sort === "date") return new Date(b.purchaseDate).getTime() - new Date(a.purchaseDate).getTime();
      if (sort === "gain") {
        const aGain = getAssetCurrentValue(a) - (a.purchasePrice + a.makingCharges + a.vatAmount);
        const bGain = getAssetCurrentValue(b) - (b.purchasePrice + b.makingCharges + b.vatAmount);
        return bGain - aGain;
      }
      return 0;
    });
  }, [assets, filter, sort, getAssetCurrentValue]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await refreshPrices();
    setRefreshing(false);
  };

  const handleAssetPress = (asset: PortfolioAsset) => {
    router.push({ pathname: "/portfolio/asset-detail", params: { assetId: asset.id } });
  };

  // For the sort/filter bar: filter options are dynamic per existing metal types
  const usedMetalTypes = useMemo(() => [...new Set(assets.map((a) => a.metalType))], [assets]);

  return (
    <ScreenContainer edges={["top", "left", "right"]} className="bg-background">
      {/* Header */}
      <View
        style={{
          flexDirection: "row",
          justifyContent: "space-between",
          alignItems: "center",
          paddingHorizontal: 16,
          paddingVertical: 12,
          borderBottomWidth: 0.5,
          borderBottomColor: colors.border,
        }}
      >
        <Text style={{ color: colors.foreground, fontSize: 22, fontWeight: "700" }}>
          {t("portfolioTitle")}
        </Text>
        <View style={{ flexDirection: "row", gap: 8 }}>
          {/* Converter */}
          <Pressable
            onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.push("/portfolio/converter"); }}
            style={({ pressed }) => ({
              opacity: pressed ? 0.7 : 1,
              width: 36, height: 36, borderRadius: 18,
              backgroundColor: colors.surface,
              alignItems: "center", justifyContent: "center",
              borderWidth: 1, borderColor: colors.border,
            })}
          >
            <IconSymbol name="arrow.left.arrow.right" size={18} color={colors.primary} />
          </Pressable>
          {/* Zakat */}
          <Pressable
            onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); router.push("/portfolio/zakat"); }}
            style={({ pressed }) => ({
              opacity: pressed ? 0.7 : 1,
              width: 36, height: 36, borderRadius: 18,
              backgroundColor: colors.surface,
              alignItems: "center", justifyContent: "center",
              borderWidth: 1, borderColor: colors.border,
            })}
          >
            <IconSymbol name="scale" size={18} color="#D97706" />
          </Pressable>
        </View>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} tintColor={colors.primary} />}
        contentContainerStyle={{ paddingBottom: 100 }}
      >
        <SpotPriceTicker />
        <NisabAlertBanner visible={showNisabAlert} />
        <PortfolioSummaryCard />

        {/* Allocation pie chart */}
        {pieEntries.length > 0 && (
          <View
            style={{
              marginHorizontal: 16, marginTop: 12,
              backgroundColor: colors.surface,
              borderRadius: 16, padding: 16,
              borderWidth: 1, borderColor: colors.border,
            }}
          >
            <Text style={{ color: colors.foreground, fontSize: 15, fontWeight: "600", marginBottom: 8 }}>
              {t("allocation")}
            </Text>
            <PortfolioPieChart entries={pieEntries} />
          </View>
        )}

        {/* Asset list */}
        <View style={{ marginTop: 16 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", paddingHorizontal: 16, marginBottom: 4 }}>
            <Text style={{ color: colors.foreground, fontSize: 15, fontWeight: "600" }}>
              {t("assets")} ({displayedAssets.length})
            </Text>
          </View>

          <SortFilterBar
            sort={sort}
            filter={filter}
            onSortChange={setSort}
            onFilterChange={setFilter}
            metalTypes={usedMetalTypes}
            metals={metals}
          />

          {displayedAssets.length === 0 ? (
            <View style={{ alignItems: "center", paddingVertical: 48, gap: 8 }}>
              <Text style={{ fontSize: 40 }}>💎</Text>
              <Text style={{ color: colors.foreground, fontSize: 16, fontWeight: "600" }}>{t("noAssets")}</Text>
              <Text style={{ color: colors.muted, fontSize: 14, textAlign: "center", paddingHorizontal: 32 }}>
                {t("noAssetsSubtitle")}
              </Text>
            </View>
          ) : (
            <View style={{ paddingHorizontal: 16, marginTop: 4 }}>
              {displayedAssets.map((asset) => (
                <AssetCard key={asset.id} asset={asset} onPress={handleAssetPress} />
              ))}
            </View>
          )}
        </View>

        {/* Add Asset */}
        <View style={{ paddingHorizontal: 16, marginTop: 8 }}>
          <Pressable
            onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium); router.push("/portfolio/add-asset"); }}
            style={({ pressed }) => ({
              opacity: pressed ? 0.85 : 1,
              transform: [{ scale: pressed ? 0.97 : 1 }],
              backgroundColor: "#07352b",
              borderRadius: 14, paddingVertical: 16,
              alignItems: "center", flexDirection: "row", justifyContent: "center", gap: 8,
            })}
          >
            <IconSymbol name="plus.circle.fill" size={20} color="#D4AF37" />
            <Text style={{ color: "#D4AF37", fontSize: 16, fontWeight: "700" }}>{t("addAsset")}</Text>
          </Pressable>
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}

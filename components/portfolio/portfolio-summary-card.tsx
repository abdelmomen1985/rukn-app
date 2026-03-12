import { View } from "react-native";
import { Text } from "@/components/ui/text";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { usePortfolio } from "@/lib/portfolio-provider";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { formatSAR } from "@/lib/portfolio-utils";

export function PortfolioSummaryCard() {
  const { getSummary, isLoadingPrices } = usePortfolio();
  const colors = useColors();
  const { t, lang } = useI18n();

  const summary = getSummary();
  const isPositive = summary.gainLoss >= 0;

  return (
    <View
      style={{
        backgroundColor: "#07352b",
        borderRadius: 20,
        padding: 20,
        marginHorizontal: 16,
        marginTop: 12,
      }}
    >
      {/* Total value */}
      <Text style={{ color: "rgba(255,255,255,0.7)", fontSize: 13, marginBottom: 4 }}>
        {t("totalValue")}
      </Text>
      <Text style={{ color: "#D4AF37", fontSize: 36, fontWeight: "700", marginBottom: 16 }}>
        {isLoadingPrices ? "…" : formatSAR(summary.totalValue, lang)}
      </Text>

      {/* Gain/Loss row */}
      <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
        <View>
          <Text style={{ color: "rgba(255,255,255,0.6)", fontSize: 12, marginBottom: 2 }}>
            {t("gainLoss")}
          </Text>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 4 }}>
            <IconSymbol
              name={isPositive ? "arrow.up.right" : "arrow.down.right"}
              size={14}
              color={isPositive ? "#4ade80" : "#f87171"}
            />
            <Text style={{ color: isPositive ? "#4ade80" : "#f87171", fontSize: 16, fontWeight: "700" }}>
              {isPositive ? "+" : ""}{formatSAR(summary.gainLoss, lang)}
            </Text>
          </View>
          <Text style={{ color: isPositive ? "#4ade80" : "#f87171", fontSize: 12 }}>
            {isPositive ? "+" : ""}{summary.gainLossPercent.toFixed(1)}%
          </Text>
        </View>

        {/* Asset count */}
        <View style={{ alignItems: "flex-end" }}>
          <Text style={{ color: "rgba(255,255,255,0.6)", fontSize: 12, marginBottom: 2 }}>
            Assets
          </Text>
          <Text style={{ color: "white", fontSize: 20, fontWeight: "700" }}>
            {summary.assetCount}
          </Text>
        </View>
      </View>
    </View>
  );
}

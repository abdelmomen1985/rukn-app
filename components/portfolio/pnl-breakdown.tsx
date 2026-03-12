import { View } from "react-native";
import { Text } from "@/components/ui/text";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { formatSAR } from "@/lib/portfolio-utils";
import type { PnLResult } from "@/lib/portfolio-utils";

interface PnLBreakdownProps {
  pnl: PnLResult;
  purchasePrice: number;
  makingCharges: number;
  vatAmount: number;
}

function Row({ label, value, highlight, color }: { label: string; value: string; highlight?: boolean; color?: string }) {
  const colors = useColors();
  return (
    <View
      style={{
        flexDirection: "row",
        justifyContent: "space-between",
        alignItems: "center",
        paddingVertical: 8,
      }}
    >
      <Text style={{ color: highlight ? colors.foreground : colors.muted, fontSize: 14, fontWeight: highlight ? "600" : "400" }}>
        {label}
      </Text>
      <Text style={{ color: color ?? (highlight ? colors.foreground : colors.foreground), fontSize: 14, fontWeight: highlight ? "700" : "500" }}>
        {value}
      </Text>
    </View>
  );
}

export function PnLBreakdown({ pnl, purchasePrice, makingCharges, vatAmount }: PnLBreakdownProps) {
  const colors = useColors();
  const { t, lang } = useI18n();
  const isPositive = pnl.absoluteGainLoss >= 0;

  return (
    <View
      style={{
        backgroundColor: colors.surface,
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: colors.border,
      }}
    >
      {/* Cost breakdown */}
      <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "600", marginBottom: 4, textTransform: "uppercase", letterSpacing: 0.5 }}>
        Cost Breakdown
      </Text>
      <Row label={t("purchaseCost")} value={formatSAR(purchasePrice, lang)} />
      {makingCharges > 0 && <Row label={t("makingCharges")} value={formatSAR(makingCharges, lang)} />}
      {vatAmount > 0 && <Row label={t("vatAmount")} value={formatSAR(vatAmount, lang)} />}

      <View style={{ height: 1, backgroundColor: colors.border, marginVertical: 8 }} />

      <Row label={t("totalCost")} value={formatSAR(pnl.totalCost, lang)} highlight />

      <View style={{ height: 1, backgroundColor: colors.border, marginVertical: 8 }} />

      {/* Performance */}
      <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "600", marginBottom: 4, textTransform: "uppercase", letterSpacing: 0.5 }}>
        Performance
      </Text>
      <Row label={t("currentValue")} value={formatSAR(pnl.currentValue, lang)} highlight />
      <Row
        label={t("gainLoss")}
        value={`${isPositive ? "+" : ""}${formatSAR(pnl.absoluteGainLoss, lang)}`}
        color={isPositive ? "#16a34a" : "#dc2626"}
        highlight
      />
      <Row
        label={t("returnPercent")}
        value={`${isPositive ? "+" : ""}${pnl.percentReturn.toFixed(2)}%`}
        color={isPositive ? "#16a34a" : "#dc2626"}
      />
      <Row
        label={t("annualizedReturn")}
        value={`${pnl.annualizedReturn >= 0 ? "+" : ""}${pnl.annualizedReturn.toFixed(1)}% / yr`}
        color={pnl.annualizedReturn >= 0 ? "#16a34a" : "#dc2626"}
      />
      <Row label="Holding Period" value={`${pnl.holdingDays} days`} />
    </View>
  );
}

import { View, ScrollView } from "react-native";
import { Text } from "@/components/ui/text";
import Svg, { Circle, G } from "react-native-svg";
import type { MetalDefinition } from "@/data/portfolio";

interface Segment {
  label: string;
  value: number;
  color: string;
}

interface PieChartProps {
  segments: Segment[];
  size?: number;
  strokeWidth?: number;
}

export function PieChart({ segments, size = 120, strokeWidth = 22 }: PieChartProps) {
  const total = segments.reduce((s, seg) => s + seg.value, 0);
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const cx = size / 2;
  const cy = size / 2;

  if (total === 0) {
    return (
      <Svg width={size} height={size}>
        <Circle cx={cx} cy={cy} r={radius} fill="none" stroke="#E5E7EB" strokeWidth={strokeWidth} />
      </Svg>
    );
  }

  let cumulativePercent = 0;
  return (
    <Svg width={size} height={size} style={{ transform: [{ rotate: "-90deg" }] }}>
      <G>
        {segments.map((seg, i) => {
          const percent = seg.value / total;
          const strokeDasharray = `${circumference * percent} ${circumference * (1 - percent)}`;
          const strokeDashoffset = -circumference * cumulativePercent;
          cumulativePercent += percent;
          return (
            <Circle
              key={i}
              cx={cx} cy={cy} r={radius}
              fill="none"
              stroke={seg.color}
              strokeWidth={strokeWidth}
              strokeDasharray={strokeDasharray}
              strokeDashoffset={strokeDashoffset}
              strokeLinecap="butt"
            />
          );
        })}
      </G>
    </Svg>
  );
}

interface MetalValueEntry {
  metal: MetalDefinition;
  value: number;
}

interface PortfolioPieChartProps {
  entries: MetalValueEntry[];
}

export function PortfolioPieChart({ entries }: PortfolioPieChartProps) {
  const total = entries.reduce((s, e) => s + e.value, 0);
  const nonZero = entries.filter((e) => e.value > 0);

  const segments: Segment[] = nonZero.map((e) => ({
    label: e.metal.name,
    value: e.value,
    color: e.metal.color,
  }));

  // Largest slice label shown in center
  const dominant = nonZero.reduce((a, b) => (a.value >= b.value ? a : b), nonZero[0]);

  return (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 16 }}>
      {/* Donut */}
      <View style={{ width: 120, height: 120, alignItems: "center", justifyContent: "center" }}>
        <PieChart segments={segments} />
        {dominant && (
          <View style={{ position: "absolute", alignItems: "center" }}>
            <Text style={{ fontSize: 18 }}>{dominant.metal.emoji}</Text>
            <Text style={{ fontSize: 11, fontWeight: "700", color: dominant.metal.color }}>
              {total > 0 ? `${((dominant.value / total) * 100).toFixed(0)}%` : ""}
            </Text>
          </View>
        )}
      </View>

      {/* Legend */}
      <ScrollView style={{ flex: 1, maxHeight: 120 }} showsVerticalScrollIndicator={false}>
        {nonZero.map((e) => (
          <View key={e.metal.id} style={{ flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 6 }}>
            <View style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: e.metal.color }} />
            <Text style={{ fontSize: 13, color: "#555", flex: 1 }}>{e.metal.name}</Text>
            <Text style={{ fontSize: 13, fontWeight: "600", color: "#333" }}>
              {total > 0 ? `${((e.value / total) * 100).toFixed(0)}%` : "—"}
            </Text>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}

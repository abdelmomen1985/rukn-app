import { View, Pressable, ScrollView } from "react-native";
import { Text } from "@/components/ui/text";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import * as Haptics from "expo-haptics";

export type SortKey = "value" | "date" | "gain";
export type FilterKey = "all" | "gold" | "silver" | "platinum" | "palladium";

interface SortFilterBarProps {
  sort: SortKey;
  filter: FilterKey;
  onSortChange: (s: SortKey) => void;
  onFilterChange: (f: FilterKey) => void;
  metalTypes: string[];
  metals: any[];
}

interface SortFilterBarProps {
  sort: SortKey;
  filter: FilterKey;
  onSortChange: (s: SortKey) => void;
  onFilterChange: (f: FilterKey) => void;
  metalTypes: string[];
  metals: any[];
}

export function SortFilterBar({ sort, filter, onSortChange, onFilterChange, metalTypes, metals }: SortFilterBarProps) {
  const colors = useColors();
  const { t, lang } = useI18n();

  // Build filter options dynamically based on available metal types
  const filters: { key: FilterKey; label: string }[] = [
    { key: "all", label: t("all") },
    ...metalTypes.map(type => {
      const metal = metals.find(m => m.id === type);
      return {
        key: type as FilterKey,
        label: metal ? (lang === "ar" ? metal.nameAr : metal.name) : type,
      };
    }),
  ];

  const sorts: { key: SortKey; label: string }[] = [
    { key: "value", label: t("currentValue") },
    { key: "gain", label: t("gainLoss") },
    { key: "date", label: t("purchaseDate") },
  ];

  return (
    <View style={{ paddingHorizontal: 16, paddingVertical: 8, gap: 8 }}>
      {/* Filter pills */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 6 }}>
        {filters.map((f) => (
          <Pressable
            key={f.key}
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              onFilterChange(f.key);
            }}
            style={{
              paddingHorizontal: 14,
              paddingVertical: 6,
              borderRadius: 20,
              backgroundColor: filter === f.key ? colors.primary : colors.surface,
              borderWidth: 1,
              borderColor: filter === f.key ? colors.primary : colors.border,
            }}
          >
            <Text
              style={{
                fontSize: 13,
                fontWeight: "600",
                color: filter === f.key ? "#07352b" : colors.foreground,
              }}
            >
              {f.label}
            </Text>
          </Pressable>
        ))}

        <View style={{ width: 1, backgroundColor: colors.border, marginHorizontal: 4 }} />

        {sorts.map((s) => (
          <Pressable
            key={s.key}
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              onSortChange(s.key);
            }}
            style={{
              paddingHorizontal: 12,
              paddingVertical: 6,
              borderRadius: 20,
              backgroundColor: sort === s.key ? "#07352b" : colors.surface,
              borderWidth: 1,
              borderColor: sort === s.key ? "#07352b" : colors.border,
              flexDirection: "row",
              alignItems: "center",
              gap: 4,
            }}
          >
            <Text
              style={{
                fontSize: 12,
                color: sort === s.key ? "white" : colors.muted,
              }}
            >
              ↕
            </Text>
            <Text
              style={{
                fontSize: 13,
                fontWeight: "600",
                color: sort === s.key ? "white" : colors.foreground,
              }}
            >
              {s.label}
            </Text>
          </Pressable>
        ))}
      </ScrollView>
    </View>
  );
}

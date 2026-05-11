import { View, ScrollView, Pressable, TextInput, Alert, Platform } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useTrips } from "@/lib/trips-provider";
import { useRouter } from "expo-router";
import { useMemo, useState } from "react";
import * as Haptics from "expo-haptics";
import {
  POPULAR_CITIES_AR,
  TRIP_CATEGORIES,
  TRIP_PURITIES,
  type JewelryCategory,
  type TripGoal,
} from "@/data/market-trips";

const CATEGORY_EMOJI: Record<JewelryCategory, string> = {
  ring: "💍",
  bracelet: "🔗",
  necklace: "📿",
  earring: "💎",
  bar: "🟨",
  coin: "🪙",
};

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

export default function NewTripScreen() {
  const colors = useColors();
  const router = useRouter();
  const { t, lang, isRTL } = useI18n();
  const { addTrip } = useTrips();

  const [name, setName] = useState("");
  const [city, setCity] = useState<string>("riyadh");
  const [citySearch, setCitySearch] = useState("");
  const [goal, setGoal] = useState<TripGoal>("compare");
  const [category, setCategory] = useState<JewelryCategory>("ring");
  const [purityIdx, setPurityIdx] = useState(2); // 21K by default
  const [weight, setWeight] = useState("");

  const filteredCities = useMemo(() => {
    const q = citySearch.trim().toLowerCase();
    if (!q) return POPULAR_CITIES_AR;
    return POPULAR_CITIES_AR.filter(
      (c) => c.nameAr.toLowerCase().includes(q) || c.nameEn.toLowerCase().includes(q),
    );
  }, [citySearch]);

  const purity = TRIP_PURITIES[purityIdx];

  const canSubmit = name.trim().length > 0 && !!city;

  const handleSubmit = async () => {
    if (!canSubmit) {
      Alert.alert(t("tripName"), t("tripNamePlaceholder"));
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    const trip = await addTrip({
      name: name.trim(),
      city,
      goal,
      category,
      purityLabel: purity.label,
      purityFactor: purity.factor,
      weightGrams: weight ? parseFloat(weight) : undefined,
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.replace({ pathname: "/invest/trips/[tripId]", params: { tripId: trip.id } });
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
          style={({ pressed }) => ({ opacity: pressed ? 0.7 : 1, padding: 4 })}
          testID="back-button"
        >
          <IconSymbol name="chevron.left" size={24} color={colors.foreground} />
        </Pressable>
        <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700", flex: 1 }}>
          {t("newTrip")}
        </Text>
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, gap: 20, paddingBottom: 24 }}>
        {/* Trip name */}
        <Section title={t("tripName")}>
          <TextInput
            value={name}
            onChangeText={setName}
            placeholder={t("tripNamePlaceholder")}
            placeholderTextColor={colors.muted}
            testID="trip-name-input"
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

        {/* City */}
        <Section title={t("tripCity")}>
          <View
            style={{
              flexDirection: "row",
              alignItems: "center",
              gap: 8,
              backgroundColor: colors.surface,
              borderWidth: 1,
              borderColor: colors.border,
              borderRadius: 12,
              paddingHorizontal: 12,
            }}
          >
            <IconSymbol name="magnifyingglass" size={16} color={colors.muted} />
            <TextInput
              value={citySearch}
              onChangeText={setCitySearch}
              placeholder={t("citySearchPlaceholder")}
              placeholderTextColor={colors.muted}
              testID="city-search-input"
              style={{
                flex: 1,
                paddingVertical: Platform.OS === "ios" ? 14 : 10,
                color: colors.foreground,
                fontSize: 14,
                textAlign: isRTL ? "right" : "left",
              }}
            />
          </View>
          <View style={{ gap: 8 }}>
            {filteredCities.map((c) => {
              const active = city === c.id;
              const label = lang === "ar" ? c.nameAr : c.nameEn;
              return (
                <Pressable
                  key={c.id}
                  onPress={() => {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                    setCity(c.id);
                  }}
                  testID={`city-option-${c.id}`}
                  style={({ pressed }) => ({
                    opacity: pressed ? 0.7 : 1,
                    backgroundColor: active ? "#07352b08" : colors.surface,
                    borderWidth: 1,
                    borderColor: active ? "#07352b" : colors.border,
                    borderRadius: 12,
                    paddingHorizontal: 14,
                    paddingVertical: 12,
                    flexDirection: "row",
                    alignItems: "center",
                    gap: 10,
                  })}
                >
                  <IconSymbol name="location" size={16} color={active ? "#07352b" : colors.muted} />
                  <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: active ? "700" : "500", flex: 1 }}>
                    {label}
                  </Text>
                  {active && <IconSymbol name="checkmark.circle" size={18} color="#07352b" />}
                </Pressable>
              );
            })}
          </View>
        </Section>

        {/* Goal */}
        <Section title={t("tripGoal")}>
          <View style={{ flexDirection: "row", gap: 10 }}>
            {[
              { id: "compare" as TripGoal, label: t("goalCompare"), icon: "magnifyingglass" },
              { id: "buy-today" as TripGoal, label: t("goalBuyToday"), icon: "sparkles" },
            ].map((opt) => {
              const active = goal === opt.id;
              return (
                <Pressable
                  key={opt.id}
                  onPress={() => {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                    setGoal(opt.id);
                  }}
                  testID={`goal-${opt.id}`}
                  style={({ pressed }) => ({
                    opacity: pressed ? 0.85 : 1,
                    flex: 1,
                    backgroundColor: active ? "#07352b" : colors.surface,
                    borderRadius: 12,
                    borderWidth: 1,
                    borderColor: active ? "#07352b" : colors.border,
                    paddingVertical: 16,
                    alignItems: "center",
                    gap: 6,
                  })}
                >
                  <IconSymbol name={opt.icon as any} size={20} color={active ? "#D4AF37" : colors.foreground} />
                  <Text style={{ color: active ? "#D4AF37" : colors.foreground, fontSize: 13, fontWeight: "700" }}>
                    {opt.label}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </Section>

        {/* Category */}
        <Section title={t("tripCategory")}>
          <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
            {TRIP_CATEGORIES.map((cat) => {
              const active = category === cat;
              return (
                <Pressable
                  key={cat}
                  onPress={() => {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                    setCategory(cat);
                  }}
                  testID={`category-${cat}`}
                  style={{
                    paddingHorizontal: 14,
                    paddingVertical: 10,
                    borderRadius: 20,
                    backgroundColor: active ? "#07352b" : colors.surface,
                    borderWidth: 1,
                    borderColor: active ? "#07352b" : colors.border,
                    flexDirection: "row",
                    alignItems: "center",
                    gap: 6,
                  }}
                >
                  <Text style={{ fontSize: 14 }}>{CATEGORY_EMOJI[cat]}</Text>
                  <Text style={{ color: active ? "#D4AF37" : colors.foreground, fontSize: 13, fontWeight: "600" }}>
                    {t(cat as any)}
                  </Text>
                </Pressable>
              );
            })}
          </View>
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
                    paddingHorizontal: 16,
                    paddingVertical: 10,
                    borderRadius: 12,
                    backgroundColor: active ? "#07352b" : colors.surface,
                    borderWidth: 1,
                    borderColor: active ? "#07352b" : colors.border,
                    minWidth: 64,
                    alignItems: "center",
                  }}
                >
                  <Text style={{ color: active ? "#D4AF37" : colors.foreground, fontSize: 14, fontWeight: "700" }}>
                    {p.label}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </Section>

        {/* Optional weight */}
        <Section title={t("tripExpectedWeight")}>
          <TextInput
            value={weight}
            onChangeText={setWeight}
            placeholder="0"
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
              fontSize: 15,
              textAlign: isRTL ? "right" : "left",
            }}
          />
        </Section>
      </ScrollView>

      {/* Submit CTA */}
      <View
        style={{
          paddingHorizontal: 16,
          paddingVertical: 12,
          borderTopWidth: 0.5,
          borderTopColor: colors.border,
          backgroundColor: colors.background,
        }}
      >
        <Pressable
          onPress={handleSubmit}
          disabled={!canSubmit}
          testID="start-trip-button"
          style={({ pressed }) => ({
            opacity: !canSubmit ? 0.4 : pressed ? 0.85 : 1,
            backgroundColor: "#07352b",
            paddingVertical: 14,
            borderRadius: 16,
            flexDirection: "row",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
          })}
        >
          <Text style={{ color: "#D4AF37", fontSize: 15, fontWeight: "700" }}>
            {t("startTrip")}
          </Text>
          <IconSymbol name={isRTL ? "chevron.left" : "chevron.right"} size={16} color="#D4AF37" />
        </Pressable>
      </View>
    </ScreenContainer>
  );
}

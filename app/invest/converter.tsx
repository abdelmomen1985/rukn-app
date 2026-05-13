import { View, ScrollView, Pressable, TextInput } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { usePortfolio } from "@/lib/portfolio-provider";
import { convertWeight, getGoldPerGramSAR, getSilverPerGramSAR, getWeightInGrams, formatSAR } from "@/lib/portfolio-utils";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useRouter } from "expo-router";
import { useState } from "react";
import type { WeightUnit, GoldKarat, SilverPurity } from "@/data/portfolio";
import * as Haptics from "expo-haptics";

const WEIGHT_UNITS: WeightUnit[] = ["grams", "tolas", "ounces", "mithqal"];
const GOLD_KARATS: GoldKarat[] = [24, 22, 21, 18, 14];
const SILVER_PURITIES: SilverPurity[] = [999, 925, 900, 800];

function PillButton<T extends string | number>({ value, selected, onPress, label }: { value: T; selected: T; onPress: (v: T) => void; label: string }) {
  const colors = useColors();
  const active = value === selected;
  return (
    <Pressable
      onPress={() => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        onPress(value);
      }}
      style={{
        paddingHorizontal: 12,
        paddingVertical: 7,
        borderRadius: 20,
        backgroundColor: active ? "#07352b" : colors.surface,
        borderWidth: 1,
        borderColor: active ? "#07352b" : colors.border,
      }}
    >
      <Text style={{ color: active ? "#D4AF37" : colors.foreground, fontSize: 13, fontWeight: "600" }}>{label}</Text>
    </Pressable>
  );
}

function SectionCard({ title, children }: { title: string; children: React.ReactNode }) {
  const colors = useColors();
  return (
    <View style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 16, borderWidth: 1, borderColor: colors.border, gap: 12 }}>
      <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "700", textTransform: "uppercase", letterSpacing: 0.5 }}>{title}</Text>
      {children}
    </View>
  );
}

export default function ConverterScreen() {
  const { spotPrices } = usePortfolio();
  const colors = useColors();
  const { t, lang } = useI18n();
  const router = useRouter();

  // Weight converter state
  const [wInput, setWInput] = useState("");
  const [wFrom, setWFrom] = useState<WeightUnit>("tolas");
  const [wTo, setWTo] = useState<WeightUnit>("grams");

  // Gold value calculator
  const [gInput, setGInput] = useState("");
  const [gUnit, setGUnit] = useState<WeightUnit>("grams");
  const [gKarat, setGKarat] = useState<GoldKarat>(21);

  // Silver value calculator
  const [sInput, setSInput] = useState("");
  const [sUnit, setSUnit] = useState<WeightUnit>("grams");
  const [sPurity, setSPurity] = useState<SilverPurity>(925);

  // Weight conversion result
  const weightResult = wInput && !isNaN(parseFloat(wInput))
    ? convertWeight(parseFloat(wInput), wFrom, wTo)
    : null;

  // Gold value result
  const goldResult = gInput && !isNaN(parseFloat(gInput)) && spotPrices
    ? getWeightInGrams(parseFloat(gInput), gUnit) * getGoldPerGramSAR(spotPrices, gKarat)
    : null;

  // Silver value result
  const silverResult = sInput && !isNaN(parseFloat(sInput)) && spotPrices
    ? getWeightInGrams(parseFloat(sInput), sUnit) * getSilverPerGramSAR(spotPrices, sPurity)
    : null;

  const inputStyle = {
    backgroundColor: colors.background,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 12,
    color: colors.foreground,
    fontSize: 16,
    fontWeight: "600" as const,
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
        <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700" }}>{t("converter")}</Text>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, gap: 16, paddingBottom: 40 }}>

        {/* Weight converter */}
        <SectionCard title={t("weightConverter")}>
          <TextInput
            value={wInput}
            onChangeText={setWInput}
            placeholder={t("amountPlaceholder")}
            placeholderTextColor={colors.muted}
            keyboardType="decimal-pad"
            style={inputStyle}
          />
          <View>
            <Text style={{ color: colors.muted, fontSize: 12, marginBottom: 6 }}>{t("convertFrom")}</Text>
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6 }}>
              {WEIGHT_UNITS.map((u) => (
                <PillButton key={u} value={u} selected={wFrom} onPress={setWFrom} label={t(u as any)} />
              ))}
            </View>
          </View>
          <View>
            <Text style={{ color: colors.muted, fontSize: 12, marginBottom: 6 }}>{t("convertTo")}</Text>
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6 }}>
              {WEIGHT_UNITS.map((u) => (
                <PillButton key={u} value={u} selected={wTo} onPress={setWTo} label={t(u as any)} />
              ))}
            </View>
          </View>
          {weightResult !== null && (
            <View style={{ backgroundColor: "#07352b", borderRadius: 12, padding: 14, alignItems: "center" }}>
              <Text style={{ color: "rgba(255,255,255,0.7)", fontSize: 12 }}>
                {wInput} {wFrom} =
              </Text>
              <Text style={{ color: "#D4AF37", fontSize: 24, fontWeight: "700" }}>
                {weightResult.toFixed(4)} {wTo}
              </Text>
            </View>
          )}
        </SectionCard>

        {/* Gold value calculator */}
        <SectionCard title={t("goldValueCalculator")}>
          {!spotPrices && (
            <Text style={{ color: colors.muted, fontSize: 13 }}>{t("loadingPrices")}</Text>
          )}
          <TextInput
            value={gInput}
            onChangeText={setGInput}
            placeholder={t("weightInputPlaceholder")}
            placeholderTextColor={colors.muted}
            keyboardType="decimal-pad"
            style={inputStyle}
          />
          <View>
            <Text style={{ color: colors.muted, fontSize: 12, marginBottom: 6 }}>{t("unit")}</Text>
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6 }}>
              {WEIGHT_UNITS.map((u) => (
                <PillButton key={u} value={u} selected={gUnit} onPress={setGUnit} label={t(u as any)} />
              ))}
            </View>
          </View>
          <View>
            <Text style={{ color: colors.muted, fontSize: 12, marginBottom: 6 }}>{t("karat")}</Text>
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6 }}>
              {GOLD_KARATS.map((k) => (
                <PillButton key={k} value={k} selected={gKarat} onPress={setGKarat} label={`${k}K`} />
              ))}
            </View>
          </View>
          {goldResult !== null && (
            <View style={{ backgroundColor: "#FFF9E6", borderRadius: 12, padding: 14, alignItems: "center", borderWidth: 1, borderColor: "#F5D766" }}>
              <Text style={{ color: "#92710B", fontSize: 12 }}>
                {gInput} {t(gUnit as any)} {t(gKarat + "K" as any)} {t("ofGold")} =
              </Text>
              <Text style={{ color: "#5A460A", fontSize: 24, fontWeight: "700" }}>
                {formatSAR(goldResult, lang)}
              </Text>
            </View>
          )}
        </SectionCard>

        {/* Silver value calculator */}
        <SectionCard title={t("silverValueCalculator")}>
          {!spotPrices && (
            <Text style={{ color: colors.muted, fontSize: 13 }}>{t("loadingPrices")}</Text>
          )}
          <TextInput
            value={sInput}
            onChangeText={setSInput}
            placeholder={t("weightInputPlaceholder")}
            placeholderTextColor={colors.muted}
            keyboardType="decimal-pad"
            style={inputStyle}
          />
          <View>
            <Text style={{ color: colors.muted, fontSize: 12, marginBottom: 6 }}>{t("unit")}</Text>
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6 }}>
              {WEIGHT_UNITS.map((u) => (
                <PillButton key={u} value={u} selected={sUnit} onPress={setSUnit} label={t(u as any)} />
              ))}
            </View>
          </View>
          <View>
            <Text style={{ color: colors.muted, fontSize: 12, marginBottom: 6 }}>{t("purity")}</Text>
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6 }}>
              {SILVER_PURITIES.map((p) => (
                <PillButton key={p} value={p} selected={sPurity} onPress={setSPurity} label={String(p)} />
              ))}
            </View>
          </View>
          {silverResult !== null && (
            <View style={{ backgroundColor: "#F5F5F5", borderRadius: 12, padding: 14, alignItems: "center", borderWidth: 1, borderColor: "#C0C0C0" }}>
              <Text style={{ color: "#666", fontSize: 12 }}>
                {sInput} {t(sUnit as any)} {t("ofSilver")} {sPurity} =
              </Text>
              <Text style={{ color: "#333", fontSize: 24, fontWeight: "700" }}>
                {formatSAR(silverResult, lang)}
              </Text>
            </View>
          )}
        </SectionCard>
      </ScrollView>
    </ScreenContainer>
  );
}

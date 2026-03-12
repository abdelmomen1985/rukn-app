import { View, ScrollView, TextInput, Pressable, Alert } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { usePortfolio } from "@/lib/portfolio-provider";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useState, useEffect } from "react";
import type { MetalType, WeightUnit, GoldKarat, SilverPurity } from "@/data/portfolio";
import * as Haptics from "expo-haptics";

const CATEGORIES = ["ring", "bracelet", "necklace", "earring", "bar", "coin"];
const GOLD_KARATS: GoldKarat[] = [24, 22, 21, 18, 14];
const SILVER_PURITIES: SilverPurity[] = [999, 925, 900, 800];
const WEIGHT_UNITS: WeightUnit[] = ["grams", "tolas", "ounces", "mithqal"];

function Label({ text }: { text: string }) {
  const colors = useColors();
  return <Text style={{ color: colors.muted, fontSize: 12, fontWeight: "600", textTransform: "uppercase", letterSpacing: 0.5, marginBottom: 6 }}>{text}</Text>;
}

function StyledInput({ value, onChangeText, placeholder, keyboardType, multiline }: any) {
  const colors = useColors();
  return (
    <TextInput
      value={value}
      onChangeText={onChangeText}
      placeholder={placeholder}
      placeholderTextColor={colors.muted}
      keyboardType={keyboardType}
      multiline={multiline}
      style={{
        backgroundColor: colors.surface,
        borderRadius: 10,
        borderWidth: 1,
        borderColor: colors.border,
        padding: 12,
        color: colors.foreground,
        fontSize: 15,
        minHeight: multiline ? 72 : undefined,
        textAlignVertical: multiline ? "top" : undefined,
      }}
    />
  );
}

function PillSelector<T extends string | number>({ options, selected, onSelect, labelFn }: {
  options: T[];
  selected: T | null;
  onSelect: (v: T) => void;
  labelFn?: (v: T) => string;
}) {
  const colors = useColors();
  return (
    <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
      {options.map((opt) => {
        const active = opt === selected;
        return (
          <Pressable
            key={String(opt)}
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              onSelect(opt);
            }}
            style={{
              paddingHorizontal: 14,
              paddingVertical: 8,
              borderRadius: 20,
              backgroundColor: active ? "#07352b" : colors.surface,
              borderWidth: 1,
              borderColor: active ? "#07352b" : colors.border,
            }}
          >
            <Text style={{ color: active ? "#D4AF37" : colors.foreground, fontSize: 13, fontWeight: "600" }}>
              {labelFn ? labelFn(opt) : String(opt)}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export default function AddAssetScreen() {
  const { assets, addAsset, updateAsset } = usePortfolio();
  const colors = useColors();
  const { t } = useI18n();
  const router = useRouter();
  const { assetId } = useLocalSearchParams<{ assetId?: string }>();

  const editingAsset = assetId ? assets.find((a) => a.id === assetId) : null;

  // Form state
  const [metalType, setMetalType] = useState<MetalType>(editingAsset?.metalType ?? "gold");
  const [name, setName] = useState(editingAsset?.name ?? "");
  const [category, setCategory] = useState<string>(editingAsset?.category ?? "ring");
  const [weightValue, setWeightValue] = useState(editingAsset?.weightValue.toString() ?? "");
  const [weightUnit, setWeightUnit] = useState<WeightUnit>(editingAsset?.weightUnit ?? "grams");
  const [karat, setKarat] = useState<GoldKarat | null>(editingAsset?.karat ?? 21);
  const [silverPurity, setSilverPurity] = useState<SilverPurity | null>(editingAsset?.silverPurity ?? 925);
  const [purchasePrice, setPurchasePrice] = useState(editingAsset?.purchasePrice.toString() ?? "");
  const [purchaseDate, setPurchaseDate] = useState(editingAsset?.purchaseDate ?? new Date().toISOString().split("T")[0]);
  const [makingCharges, setMakingCharges] = useState(editingAsset?.makingCharges.toString() ?? "0");
  const [vatAmount, setVatAmount] = useState(editingAsset?.vatAmount.toString() ?? "0");
  const [notes, setNotes] = useState(editingAsset?.notes ?? "");
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert("Error", "Please enter an asset name");
      return;
    }
    if (!weightValue || isNaN(parseFloat(weightValue)) || parseFloat(weightValue) <= 0) {
      Alert.alert("Error", "Please enter a valid weight");
      return;
    }
    if (!purchasePrice || isNaN(parseFloat(purchasePrice))) {
      Alert.alert("Error", "Please enter a valid purchase price");
      return;
    }

    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setSaving(true);
    try {
      const assetData = {
        metalType,
        name: name.trim(),
        category,
        weightValue: parseFloat(weightValue),
        weightUnit,
        karat: metalType === "gold" ? karat : null,
        silverPurity: metalType === "silver" ? silverPurity : null,
        purchasePrice: parseFloat(purchasePrice),
        purchaseDate,
        makingCharges: parseFloat(makingCharges) || 0,
        vatAmount: parseFloat(vatAmount) || 0,
        notes: notes.trim() || undefined,
      };

      if (editingAsset) {
        await updateAsset(editingAsset.id, assetData);
      } else {
        await addAsset(assetData);
      }
      router.back();
    } finally {
      setSaving(false);
    }
  };

  return (
    <ScreenContainer className="bg-background">
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
        <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700", flex: 1 }}>
          {editingAsset ? t("editAsset") : t("addAsset")}
        </Text>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, gap: 20, paddingBottom: 40 }}>

        {/* Metal type toggle */}
        <View>
          <Label text={t("metalType")} />
          <View style={{ flexDirection: "row", gap: 10 }}>
            {(["gold", "silver"] as MetalType[]).map((m) => (
              <Pressable
                key={m}
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setMetalType(m);
                }}
                style={{
                  flex: 1,
                  paddingVertical: 12,
                  borderRadius: 12,
                  backgroundColor: metalType === m ? (m === "gold" ? "#FFF9E6" : "#F5F5F5") : colors.surface,
                  borderWidth: 2,
                  borderColor: metalType === m ? (m === "gold" ? "#D4AF37" : "#A8A8A8") : colors.border,
                  alignItems: "center",
                  gap: 4,
                }}
              >
                <Text style={{ fontSize: 22 }}>{m === "gold" ? "🥇" : "🥈"}</Text>
                <Text style={{ color: metalType === m ? (m === "gold" ? "#92710B" : "#4B5563") : colors.foreground, fontWeight: "700", fontSize: 14 }}>
                  {t(m)}
                </Text>
              </Pressable>
            ))}
          </View>
        </View>

        {/* Name */}
        <View>
          <Label text={t("assetName")} />
          <StyledInput value={name} onChangeText={setName} placeholder={t("assetNamePlaceholder")} />
        </View>

        {/* Category */}
        <View>
          <Label text={t("category")} />
          <PillSelector
            options={CATEGORIES}
            selected={category}
            onSelect={setCategory}
            labelFn={(c) => t(c as any)}
          />
        </View>

        {/* Weight */}
        <View>
          <Label text={t("weight")} />
          <View style={{ flexDirection: "row", gap: 10, marginBottom: 8 }}>
            <View style={{ flex: 1 }}>
              <StyledInput
                value={weightValue}
                onChangeText={setWeightValue}
                placeholder={t("weightPlaceholder")}
                keyboardType="decimal-pad"
              />
            </View>
          </View>
          <PillSelector
            options={WEIGHT_UNITS}
            selected={weightUnit}
            onSelect={setWeightUnit}
            labelFn={(u) => t(u as any)}
          />
        </View>

        {/* Karat / Purity */}
        {metalType === "gold" ? (
          <View>
            <Label text={t("karat")} />
            <PillSelector
              options={GOLD_KARATS}
              selected={karat}
              onSelect={setKarat}
              labelFn={(k) => `${k}K`}
            />
          </View>
        ) : (
          <View>
            <Label text={t("purity")} />
            <PillSelector
              options={SILVER_PURITIES}
              selected={silverPurity}
              onSelect={setSilverPurity}
              labelFn={(p) => String(p)}
            />
          </View>
        )}

        {/* Purchase Price */}
        <View>
          <Label text={t("purchasePrice")} />
          <StyledInput value={purchasePrice} onChangeText={setPurchasePrice} placeholder={t("weightPlaceholder")} keyboardType="decimal-pad" />
        </View>

        {/* Purchase Date */}
        <View>
          <Label text={t("purchaseDate")} />
          <StyledInput value={purchaseDate} onChangeText={setPurchaseDate} placeholder={t("datePlaceholder")} />
        </View>

        {/* Making Charges */}
        <View>
          <Label text={t("makingCharges")} />
          <StyledInput value={makingCharges} onChangeText={setMakingCharges} placeholder={t("weightPlaceholder")} keyboardType="decimal-pad" />
        </View>

        {/* VAT */}
        <View>
          <Label text={t("vatAmount")} />
          <StyledInput value={vatAmount} onChangeText={setVatAmount} placeholder={t("weightPlaceholder")} keyboardType="decimal-pad" />
        </View>

        {/* Notes */}
        <View>
          <Label text={t("notes")} />
          <StyledInput value={notes} onChangeText={setNotes} placeholder={t("notesPlaceholder")} multiline />
        </View>

        {/* Save button */}
        <Pressable
          onPress={handleSave}
          disabled={saving}
          style={({ pressed }) => ({
            opacity: pressed || saving ? 0.8 : 1,
            transform: [{ scale: pressed ? 0.97 : 1 }],
            backgroundColor: "#07352b",
            borderRadius: 14,
            paddingVertical: 16,
            alignItems: "center",
            marginTop: 8,
          })}
        >
          <Text style={{ color: "#D4AF37", fontSize: 16, fontWeight: "700" }}>
            {saving ? t("loadingPriceData") : t("saveAsset")}
          </Text>
        </Pressable>
      </ScrollView>
    </ScreenContainer>
  );
}

import { View, ScrollView, Pressable, TextInput, Alert } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useRouter } from "expo-router";
import { useState } from "react";
import * as Haptics from "expo-haptics";

// ── Types ────────────────────────────────────────────────────────────────────

interface TimeSlot {
  id: string;
  time: string;
  available: boolean;
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const CONSULTANTS = [
  {
    id: "c1",
    name: "Dr. Ahmed Al-Rashidi",
    nameAr: "د. أحمد الراشدي",
    title: "Senior Gold Investment Advisor",
    titleAr: "مستشار استثمار ذهب أول",
    rating: 4.9,
    reviews: 312,
    pricePerSession: 350,
    avatar: "💼",
    specialties: ["Market Analysis", "Portfolio Strategy", "Gold ETFs"],
    specialtiesAr: ["تحليل السوق", "استراتيجية المحفظة", "صناديق الذهب"],
  },
];

const CONSULTANT = CONSULTANTS[0];

function buildWeekDays(): { date: Date; label: string; dayLabel: string }[] {
  const today = new Date();
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() + i + 1); // start from tomorrow
    return {
      date: d,
      label: d.getDate().toString(),
      dayLabel: d.toLocaleDateString("en-US", { weekday: "short" }),
    };
  });
}

const WEEK_DAYS = buildWeekDays();

const TIME_SLOTS: TimeSlot[] = [
  { id: "t1", time: "09:00", available: true },
  { id: "t2", time: "10:00", available: false },
  { id: "t3", time: "11:00", available: true },
  { id: "t4", time: "12:00", available: true },
  { id: "t5", time: "14:00", available: false },
  { id: "t6", time: "15:00", available: true },
  { id: "t7", time: "16:00", available: true },
  { id: "t8", time: "17:00", available: false },
];

// ── Sub-components ────────────────────────────────────────────────────────────

function SectionLabel({ title }: { title: string }) {
  const colors = useColors();
  return (
    <Text
      style={{
        color: colors.muted,
        fontSize: 12,
        fontWeight: "700",
        textTransform: "uppercase",
        letterSpacing: 0.5,
        marginBottom: 10,
      }}
    >
      {title}
    </Text>
  );
}

function Card({ children, style }: { children: React.ReactNode; style?: object }) {
  const colors = useColors();
  return (
    <View
      style={[
        {
          backgroundColor: colors.surface,
          borderRadius: 16,
          padding: 16,
          borderWidth: 1,
          borderColor: colors.border,
        },
        style,
      ]}
    >
      {children}
    </View>
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

type Step = "schedule" | "payment" | "confirmed";

export default function ConsultationScreen() {
  const colors = useColors();
  const { t, lang } = useI18n();
  const router = useRouter();

  const [selectedDayIdx, setSelectedDayIdx] = useState<number | null>(null);
  const [selectedSlot, setSelectedSlot] = useState<TimeSlot | null>(null);
  const [step, setStep] = useState<Step>("schedule");

  // Payment form state
  const [cardHolder, setCardHolder] = useState("");
  const [cardNumber, setCardNumber] = useState("");
  const [expiry, setExpiry] = useState("");
  const [cvv, setCvv] = useState("");
  const [processing, setProcessing] = useState(false);

  const isRTL = lang === "ar";
  const consultant = CONSULTANT;

  const handleDayPress = (idx: number) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setSelectedDayIdx(idx);
    setSelectedSlot(null);
  };

  const handleSlotPress = (slot: TimeSlot) => {
    if (!slot.available) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setSelectedSlot(slot);
  };

  const handleProceedToPayment = () => {
    if (selectedDayIdx === null || !selectedSlot) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setStep("payment");
  };

  const handlePay = () => {
    if (!cardHolder.trim() || cardNumber.replace(/\s/g, "").length < 16 || expiry.length < 5 || cvv.length < 3) {
      Alert.alert(t("consultationPaymentError"), t("consultationPaymentErrorMsg"));
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    setProcessing(true);
    setTimeout(() => {
      setProcessing(false);
      setStep("confirmed");
    }, 1800);
  };

  const formatCardNumber = (text: string) => {
    const digits = text.replace(/\D/g, "").slice(0, 16);
    return digits.replace(/(.{4})/g, "$1 ").trim();
  };

  const formatExpiry = (text: string) => {
    const digits = text.replace(/\D/g, "").slice(0, 4);
    if (digits.length >= 3) return digits.slice(0, 2) + "/" + digits.slice(2);
    return digits;
  };

  const selectedDay = selectedDayIdx !== null ? WEEK_DAYS[selectedDayIdx] : null;

  const inputStyle = {
    backgroundColor: colors.background,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 14,
    color: colors.foreground,
    fontSize: 15,
    fontWeight: "500" as const,
  };

  // ── Confirmed screen ──────────────────────────────────────────────────────

  if (step === "confirmed") {
    return (
      <ScreenContainer className="bg-background">
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
          <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700" }}>
            {t("consultationTitle")}
          </Text>
        </View>

        <ScrollView contentContainerStyle={{ padding: 24, alignItems: "center", gap: 20, paddingBottom: 60 }}>
          <View style={{ width: 100, height: 100, borderRadius: 50, backgroundColor: "#D1FAE5", alignItems: "center", justifyContent: "center" }}>
            <Text style={{ fontSize: 48 }}>✅</Text>
          </View>
          <Text style={{ color: colors.foreground, fontSize: 22, fontWeight: "700", textAlign: "center" }}>
            {t("consultationConfirmedTitle")}
          </Text>
          <Text style={{ color: colors.muted, fontSize: 15, textAlign: "center", lineHeight: 22 }}>
            {t("consultationConfirmedSubtitle")}
          </Text>

          {/* Booking summary */}
          <Card style={{ width: "100%" }}>
            <SectionLabel title={t("consultationBookingSummary")} />
            <View style={{ gap: 10 }}>
              <Row label={t("consultationConsultant")} value={lang === "ar" ? consultant.nameAr : consultant.name} />
              <Row
                label={t("consultationDate")}
                value={selectedDay ? selectedDay.date.toLocaleDateString(lang === "ar" ? "ar-SA" : "en-US", { weekday: "long", month: "long", day: "numeric" }) : ""}
              />
              <Row label={t("consultationTime")} value={selectedSlot?.time ?? ""} />
              <Row label={t("consultationFee")} value={`${consultant.pricePerSession} SAR`} highlight />
            </View>
          </Card>

          <Text style={{ color: colors.muted, fontSize: 13, textAlign: "center", lineHeight: 20 }}>
            {t("consultationConfirmationNote")}
          </Text>

          <Pressable
            onPress={() => router.back()}
            style={({ pressed }) => ({
              opacity: pressed ? 0.85 : 1,
              backgroundColor: "#07352b",
              borderRadius: 14,
              paddingVertical: 16,
              paddingHorizontal: 40,
              alignItems: "center",
              width: "100%",
            })}
          >
            <Text style={{ color: "#D4AF37", fontSize: 16, fontWeight: "700" }}>{t("consultationBackToPortfolio")}</Text>
          </Pressable>
        </ScrollView>
      </ScreenContainer>
    );
  }

  // ── Payment screen ────────────────────────────────────────────────────────

  if (step === "payment") {
    return (
      <ScreenContainer className="bg-background">
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
          <Pressable onPress={() => setStep("schedule")} style={({ pressed }) => ({ opacity: pressed ? 0.6 : 1 })}>
            <IconSymbol name="chevron.left" size={24} color={colors.foreground} />
          </Pressable>
          <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700" }}>
            {t("consultationPayment")}
          </Text>
        </View>

        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, gap: 16, paddingBottom: 60 }}>

          {/* Booking summary pill */}
          <Card>
            <SectionLabel title={t("consultationBookingSummary")} />
            <Row label={t("consultationConsultant")} value={lang === "ar" ? consultant.nameAr : consultant.name} />
            <Row
              label={t("consultationDate")}
              value={selectedDay ? selectedDay.date.toLocaleDateString(lang === "ar" ? "ar-SA" : "en-US", { weekday: "short", month: "short", day: "numeric" }) : ""}
            />
            <Row label={t("consultationTime")} value={selectedSlot?.time ?? ""} />
            <View style={{ height: 1, backgroundColor: colors.border, marginVertical: 8 }} />
            <Row label={t("consultationFee")} value={`${consultant.pricePerSession} SAR`} highlight />
          </Card>

          {/* Card form */}
          <Card>
            <SectionLabel title={t("consultationCardDetails")} />

            {/* Card visual */}
            <View
              style={{
                backgroundColor: "#07352b",
                borderRadius: 16,
                padding: 20,
                marginBottom: 16,
                gap: 12,
              }}
            >
              <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                <Text style={{ color: "rgba(255,255,255,0.6)", fontSize: 12 }}>{t("consultationCard")}</Text>
                <Text style={{ color: "#D4AF37", fontSize: 18 }}>💳</Text>
              </View>
              <Text style={{ color: "#D4AF37", fontSize: 20, fontWeight: "700", letterSpacing: 3 }}>
                {cardNumber || "•••• •••• •••• ••••"}
              </Text>
              <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                <Text style={{ color: "rgba(255,255,255,0.8)", fontSize: 13 }}>{cardHolder || t("consultationCardHolderPlaceholder")}</Text>
                <Text style={{ color: "rgba(255,255,255,0.8)", fontSize: 13 }}>{expiry || "MM/YY"}</Text>
              </View>
            </View>

            <View style={{ gap: 12 }}>
              <TextInput
                value={cardHolder}
                onChangeText={setCardHolder}
                placeholder={t("consultationCardHolder")}
                placeholderTextColor={colors.muted}
                autoCapitalize="characters"
                style={inputStyle}
              />
              <TextInput
                value={cardNumber}
                onChangeText={(t) => setCardNumber(formatCardNumber(t))}
                placeholder={t("consultationCardNumber")}
                placeholderTextColor={colors.muted}
                keyboardType="number-pad"
                maxLength={19}
                style={inputStyle}
              />
              <View style={{ flexDirection: "row", gap: 12 }}>
                <TextInput
                  value={expiry}
                  onChangeText={(t) => setExpiry(formatExpiry(t))}
                  placeholder="MM/YY"
                  placeholderTextColor={colors.muted}
                  keyboardType="number-pad"
                  maxLength={5}
                  style={[inputStyle, { flex: 1 }]}
                />
                <TextInput
                  value={cvv}
                  onChangeText={(t) => setCvv(t.replace(/\D/g, "").slice(0, 4))}
                  placeholder="CVV"
                  placeholderTextColor={colors.muted}
                  keyboardType="number-pad"
                  secureTextEntry
                  maxLength={4}
                  style={[inputStyle, { flex: 1 }]}
                />
              </View>
            </View>
          </Card>

          {/* Secure note */}
          <View style={{ flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 4 }}>
            <IconSymbol name="lock.fill" size={13} color={colors.muted} />
            <Text style={{ color: colors.muted, fontSize: 12 }}>{t("consultationSecurePayment")}</Text>
          </View>

          {/* Pay button */}
          <Pressable
            onPress={handlePay}
            disabled={processing}
            style={({ pressed }) => ({
              opacity: pressed || processing ? 0.8 : 1,
              transform: [{ scale: pressed ? 0.98 : 1 }],
              backgroundColor: "#07352b",
              borderRadius: 14,
              paddingVertical: 18,
              alignItems: "center",
            })}
          >
            <Text style={{ color: "#D4AF37", fontSize: 16, fontWeight: "700" }}>
              {processing ? t("consultationProcessing") : `${t("consultationPay")} ${consultant.pricePerSession} SAR`}
            </Text>
          </Pressable>
        </ScrollView>
      </ScreenContainer>
    );
  }

  // ── Schedule screen (default) ─────────────────────────────────────────────

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
        <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700" }}>
          {t("consultationTitle")}
        </Text>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, gap: 16, paddingBottom: 60 }}>

        {/* Consultant card */}
        <View
          style={{
            backgroundColor: "#07352b",
            borderRadius: 20,
            padding: 20,
            gap: 12,
          }}
        >
          <View style={{ flexDirection: "row", alignItems: "center", gap: 14 }}>
            <View
              style={{
                width: 60,
                height: 60,
                borderRadius: 30,
                backgroundColor: "rgba(212,175,55,0.15)",
                alignItems: "center",
                justifyContent: "center",
                borderWidth: 2,
                borderColor: "#D4AF37",
              }}
            >
              <Text style={{ fontSize: 28 }}>{consultant.avatar}</Text>
            </View>
            <View style={{ flex: 1 }}>
              <Text style={{ color: "#D4AF37", fontSize: 17, fontWeight: "700" }}>
                {lang === "ar" ? consultant.nameAr : consultant.name}
              </Text>
              <Text style={{ color: "rgba(255,255,255,0.75)", fontSize: 13, marginTop: 2 }}>
                {lang === "ar" ? consultant.titleAr : consultant.title}
              </Text>
            </View>
          </View>

          <View style={{ flexDirection: "row", gap: 8, flexWrap: "wrap" }}>
            {(lang === "ar" ? consultant.specialtiesAr : consultant.specialties).map((s) => (
              <View
                key={s}
                style={{
                  backgroundColor: "rgba(212,175,55,0.12)",
                  borderRadius: 20,
                  paddingHorizontal: 10,
                  paddingVertical: 4,
                  borderWidth: 1,
                  borderColor: "rgba(212,175,55,0.3)",
                }}
              >
                <Text style={{ color: "#D4AF37", fontSize: 11, fontWeight: "600" }}>{s}</Text>
              </View>
            ))}
          </View>

          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 4 }}>
              <Text style={{ color: "#FBBF24", fontSize: 14 }}>★</Text>
              <Text style={{ color: "#fff", fontSize: 14, fontWeight: "600" }}>{consultant.rating}</Text>
              <Text style={{ color: "rgba(255,255,255,0.5)", fontSize: 13 }}>({consultant.reviews})</Text>
            </View>
            <View style={{ alignItems: isRTL ? "flex-start" : "flex-end" }}>
              <Text style={{ color: "rgba(255,255,255,0.5)", fontSize: 11 }}>{t("consultationPerSession")}</Text>
              <Text style={{ color: "#D4AF37", fontSize: 20, fontWeight: "700" }}>
                {consultant.pricePerSession} SAR
              </Text>
            </View>
          </View>
        </View>

        {/* Day picker */}
        <Card>
          <SectionLabel title={t("consultationSelectDate")} />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8 }}>
            {WEEK_DAYS.map((day, idx) => {
              const selected = selectedDayIdx === idx;
              return (
                <Pressable
                  key={idx}
                  onPress={() => handleDayPress(idx)}
                  style={{
                    width: 56,
                    paddingVertical: 10,
                    borderRadius: 14,
                    alignItems: "center",
                    backgroundColor: selected ? "#07352b" : colors.background,
                    borderWidth: 1,
                    borderColor: selected ? "#07352b" : colors.border,
                    gap: 4,
                  }}
                >
                  <Text style={{ color: selected ? "rgba(255,255,255,0.65)" : colors.muted, fontSize: 11, fontWeight: "600" }}>
                    {day.dayLabel}
                  </Text>
                  <Text style={{ color: selected ? "#D4AF37" : colors.foreground, fontSize: 18, fontWeight: "700" }}>
                    {day.label}
                  </Text>
                </Pressable>
              );
            })}
          </ScrollView>
        </Card>

        {/* Time slots */}
        {selectedDayIdx !== null && (
          <Card>
            <SectionLabel title={t("consultationSelectTime")} />
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10 }}>
              {TIME_SLOTS.map((slot) => {
                const selected = selectedSlot?.id === slot.id;
                return (
                  <Pressable
                    key={slot.id}
                    onPress={() => handleSlotPress(slot)}
                    disabled={!slot.available}
                    style={{
                      width: "22%",
                      paddingVertical: 10,
                      borderRadius: 12,
                      alignItems: "center",
                      backgroundColor: !slot.available
                        ? colors.background
                        : selected
                        ? "#07352b"
                        : colors.background,
                      borderWidth: 1,
                      borderColor: !slot.available
                        ? colors.border
                        : selected
                        ? "#07352b"
                        : colors.border,
                      opacity: slot.available ? 1 : 0.4,
                    }}
                  >
                    <Text
                      style={{
                        color: selected ? "#D4AF37" : colors.foreground,
                        fontSize: 13,
                        fontWeight: "600",
                      }}
                    >
                      {slot.time}
                    </Text>
                  </Pressable>
                );
              })}
            </View>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 16, marginTop: 8 }}>
              <View style={{ flexDirection: "row", alignItems: "center", gap: 5 }}>
                <View style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: "#07352b" }} />
                <Text style={{ color: colors.muted, fontSize: 11 }}>{t("consultationAvailable")}</Text>
              </View>
              <View style={{ flexDirection: "row", alignItems: "center", gap: 5 }}>
                <View style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: colors.border }} />
                <Text style={{ color: colors.muted, fontSize: 11 }}>{t("consultationBooked")}</Text>
              </View>
            </View>
          </Card>
        )}

        {/* What to expect */}
        <Card>
          <SectionLabel title={t("consultationWhatToExpect")} />
          {[
            { icon: "chart.line.uptrend.xyaxis", labelKey: "consultationExpect1" as const },
            { icon: "lightbulb", labelKey: "consultationExpect2" as const },
            { icon: "lock.shield", labelKey: "consultationExpect3" as const },
          ].map(({ icon, labelKey }) => (
            <View key={labelKey} style={{ flexDirection: "row", alignItems: "flex-start", gap: 10, paddingVertical: 6 }}>
              <IconSymbol name={icon as any} size={18} color="#D4AF37" />
              <Text style={{ color: colors.foreground, fontSize: 13, flex: 1, lineHeight: 18 }}>{t(labelKey)}</Text>
            </View>
          ))}
        </Card>

        {/* CTA */}
        <Pressable
          onPress={handleProceedToPayment}
          disabled={selectedDayIdx === null || !selectedSlot}
          style={({ pressed }) => ({
            opacity: selectedDayIdx === null || !selectedSlot ? 0.45 : pressed ? 0.85 : 1,
            transform: [{ scale: pressed ? 0.97 : 1 }],
            backgroundColor: "#07352b",
            borderRadius: 14,
            paddingVertical: 18,
            alignItems: "center",
          })}
        >
          <Text style={{ color: "#D4AF37", fontSize: 16, fontWeight: "700" }}>
            {t("consultationBookAndPay")}
          </Text>
        </Pressable>
      </ScrollView>
    </ScreenContainer>
  );
}

// ── Helper ────────────────────────────────────────────────────────────────────

function Row({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) {
  const colors = useColors();
  return (
    <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", paddingVertical: 5 }}>
      <Text style={{ color: colors.muted, fontSize: 13, flex: 1 }}>{label}</Text>
      <Text style={{ color: highlight ? "#D4AF37" : colors.foreground, fontSize: 14, fontWeight: highlight ? "700" : "500" }}>
        {value}
      </Text>
    </View>
  );
}

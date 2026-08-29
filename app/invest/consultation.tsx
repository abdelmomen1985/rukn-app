import { View, ScrollView, Pressable, TextInput, Alert, Linking, Platform } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useRouter } from "expo-router";
import { useState } from "react";
import * as Haptics from "expo-haptics";
import { trpc } from "@/lib/trpc";
import { WEB } from "@/lib/brand";

// ── Specialist profile ───────────────────────────────────────────────────────
// ⚠️ Both stores treat this card as a factual claim. A made-up advisor name or
// credential is Apple Guideline 2.3.1 / 4.2 and Play "misleading claims".
//
// So the person is NOT hard-coded here. Supply the real advisor through the EAS
// production profile / .env; until then the card shows a generic, truthful
// label ("Rukn Thamin gold specialist") rather than inventing someone:
//
//   EXPO_PUBLIC_CONSULTANT_NAME=…        EXPO_PUBLIC_CONSULTANT_NAME_AR=…
//   EXPO_PUBLIC_CONSULTANT_TITLE=…       EXPO_PUBLIC_CONSULTANT_TITLE_AR=…
//   EXPO_PUBLIC_CONSULTATION_FEE_SAR=350
//
// Replace the avatar emoji with a photo the business has the rights to.
// Fabricated reviews/ratings were deleted — Apple Guideline 4.2 & 2.1 both bite.

const CONSULTANT_NAME = process.env.EXPO_PUBLIC_CONSULTANT_NAME?.trim() || "";
const CONSULTANT = {
  /** False until a real advisor is configured; the UI then stays generic. */
  isNamed: CONSULTANT_NAME.length > 0,
  name: CONSULTANT_NAME,
  nameAr: process.env.EXPO_PUBLIC_CONSULTANT_NAME_AR?.trim() || CONSULTANT_NAME,
  title: process.env.EXPO_PUBLIC_CONSULTANT_TITLE?.trim() || "",
  titleAr: process.env.EXPO_PUBLIC_CONSULTANT_TITLE_AR?.trim() || "",
  pricePerSession: Number(process.env.EXPO_PUBLIC_CONSULTATION_FEE_SAR ?? 350),
  avatar: "💼",
  specialties: ["Market Analysis", "Portfolio Strategy", "Buying & Selling"],
  specialtiesAr: ["تحليل السوق", "استراتيجية المحفظة", "الشراء والبيع"],
};

/** The session is paid for off-platform (human service — Play/Apple IAP exempt). */
const SESSION_DURATION_LABEL = "45 min";

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

/** Times the customer can *ask* for. Not an availability calendar. */
const PREFERRED_TIMES = ["09:00", "10:00", "11:00", "12:00", "14:00", "15:00", "16:00", "17:00", "19:00", "20:00"];

// ── Small building blocks ────────────────────────────────────────────────────

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

function Row({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) {
  const colors = useColors();
  return (
    <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
      <Text style={{ color: colors.muted, fontSize: 13 }}>{label}</Text>
      <Text
        style={{
          color: highlight ? "#D4AF37" : colors.foreground,
          fontSize: highlight ? 16 : 13,
          fontWeight: highlight ? "700" : "600",
        }}
      >
        {value}
      </Text>
    </View>
  );
}

function HeaderBar({ title, onBack }: { title: string; onBack: () => void }) {
  const colors = useColors();
  return (
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
      <Pressable onPress={onBack} style={({ pressed }) => ({ opacity: pressed ? 0.6 : 1 })}>
        <IconSymbol name="chevron.left" size={24} color={colors.foreground} />
      </Pressable>
      <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700" }}>{title}</Text>
    </View>
  );
}

function GoldButton({
  label,
  onPress,
  disabled,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => ({
        opacity: pressed || disabled ? 0.75 : 1,
        backgroundColor: "#07352b",
        borderRadius: 14,
        paddingVertical: 18,
        alignItems: "center",
      })}
    >
      <Text style={{ color: "#D4AF37", fontSize: 16, fontWeight: "700" }}>{label}</Text>
    </Pressable>
  );
}

// ── Screen ───────────────────────────────────────────────────────────────────

type Status = "idle" | "sending" | "sent" | "failed";

export default function ConsultationScreen() {
  const colors = useColors();
  const { t, lang } = useI18n();
  const router = useRouter();
  const isRTL = lang === "ar";

  // Falls back to a generic label while no real advisor is configured, so the
  // app never presents an invented person as a credentialled specialist.
  const consultantName = CONSULTANT.isNamed
    ? (lang === "ar" ? CONSULTANT.nameAr : CONSULTANT.name)
    : t("consultationSpecialistGeneric");
  const consultantTitle = CONSULTANT.isNamed
    ? (lang === "ar" ? CONSULTANT.titleAr : CONSULTANT.title)
    : "";

  const [selectedDayIdx, setSelectedDayIdx] = useState<number | null>(null);
  const [times, setTimes] = useState<string[]>([]);
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [notes, setNotes] = useState("");
  const [status, setStatus] = useState<Status>("idle");
  const [reference, setReference] = useState<string | null>(null);

  const mutation = trpc.consultation.request.useMutation({
    onSuccess: (result) => {
      if (result.received && "reference" in result && result.reference) {
        setReference(result.reference);
        setStatus("sent");
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      } else {
        setStatus("failed");
      }
    },
    onError: () => setStatus("failed"),
  });

  const selectedDay = selectedDayIdx !== null ? WEEK_DAYS[selectedDayIdx] : null;

  const toggleTime = (time: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setTimes((prev) =>
      prev.includes(time) ? prev.filter((x) => x !== time) : [...prev, time].sort(),
    );
  };

  const summaryText = () =>
    [
      `Name: ${fullName}`,
      `Email: ${email || "-"}`,
      `Phone: ${phone || "-"}`,
      `Preferred date: ${selectedDay ? selectedDay.date.toDateString() : "-"}`,
      `Preferred times: ${times.join(", ") || "-"}`,
      `Notes: ${notes || "-"}`,
    ].join("\n");

  const contactFallback = (channel: "email" | "whatsapp") => {
    const subject = encodeURIComponent("Gold consultation request");
    const body = encodeURIComponent(summaryText());
    const url =
      channel === "email"
        ? `mailto:${WEB.support}?subject=${subject}&body=${body}`
        : `https://wa.me/${WEB.whatsapp}?text=${encodeURIComponent(
            `${subject}: ${isRTL ? "طلب استشارة" : "Consultation request"}\n\n${summaryText()}`,
          )}`;
    Linking.openURL(url).catch(() =>
      Alert.alert(t("consultationFailedTitle"), t("consultationSendFailed")),
    );
  };

  const handleSubmit = () => {
    const hasContact =
      email.includes("@") || phone.replace(/\D/g, "").length >= 8;
    if (fullName.trim().length < 2 || !hasContact) {
      Alert.alert(t("consultationFailedTitle"), t("consultationRequiredFields"));
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setStatus("sending");
    mutation.mutate({
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      preferredDate: selectedDay ? selectedDay.date.toISOString().slice(0, 10) : undefined,
      preferredTimes: times,
      notes: notes.trim() || undefined,
      language: lang,
      sessionFeeSar: CONSULTANT.pricePerSession,
    });
  };

  const inputStyle = {
    backgroundColor: colors.background,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 14,
    color: colors.foreground,
    fontSize: 15,
    fontWeight: "500" as const,
    writingDirection: isRTL ? ("rtl" as const) : ("ltr" as const),
  };

  // ── Sent screen ─────────────────────────────────────────────────────────────

  if (status === "sent") {
    return (
      <ScreenContainer edges={["top", "left", "right", "bottom"]} className="bg-background">
        <HeaderBar title={t("consultationTitle")} onBack={() => router.back()} />
        <ScrollView
          contentContainerStyle={{ padding: 24, alignItems: "center", gap: 20, paddingBottom: 60 }}
        >
          <View
            style={{
              width: 96,
              height: 96,
              borderRadius: 48,
              backgroundColor: "rgba(212,175,55,0.12)",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <IconSymbol name="checkmark.circle" size={44} color="#D4AF37" />
          </View>
          <Text
            style={{ color: colors.foreground, fontSize: 22, fontWeight: "700", textAlign: "center" }}
          >
            {t("consultationRequestedTitle")}
          </Text>
          <Text
            style={{ color: colors.muted, fontSize: 15, textAlign: "center", lineHeight: 22 }}
          >
            {t("consultationRequestedSubtitle")}
          </Text>

          <Card style={{ width: "100%" }}>
            <SectionLabel title={t("consultationBookingSummary")} />
            <View style={{ gap: 10 }}>
              {reference ? (
                <Row label={t("consultationReference")} value={reference} />
              ) : null}
              <Row
                label={t("consultationConsultant")}
                value={consultantName}
              />
              <Row
                label={t("consultationDate")}
                value={
                  selectedDay
                    ? selectedDay.date.toLocaleDateString(lang === "ar" ? "ar-SA" : "en-US", {
                        weekday: "long",
                        month: "long",
                        day: "numeric",
                      })
                    : "—"
                }
              />
              <Row label={t("consultationTime")} value={times.join(", ") || "—"} />
              <Row
                label={t("consultationFee")}
                value={`${CONSULTANT.pricePerSession} SAR`}
                highlight
              />
            </View>
          </Card>

          <Text style={{ color: colors.muted, fontSize: 13, textAlign: "center", lineHeight: 20 }}>
            {t("consultationFeeNote").replace("{fee}", String(CONSULTANT.pricePerSession))}
          </Text>

          <View style={{ width: "100%", gap: 12 }}>
            <GoldButton
              label={t("consultationBackToPortfolio")}
              onPress={() => router.back()}
            />
            <Pressable onPress={() => setStatus("idle")} style={{ paddingVertical: 8 }}>
              <Text style={{ color: colors.muted, fontSize: 14, textAlign: "center" }}>
                {t("consultationNewRequest")}
              </Text>
            </Pressable>
          </View>
        </ScrollView>
      </ScreenContainer>
    );
  }

  // ── Request form ────────────────────────────────────────────────────────────

  return (
    <ScreenContainer edges={["top", "left", "right", "bottom"]} className="bg-background">
      <HeaderBar title={t("consultationTitle")} onBack={() => router.back()} />

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 16, gap: 16, paddingBottom: 60 }}>
        {/* Specialist card */}
        <View style={{ backgroundColor: "#07352b", borderRadius: 20, padding: 20, gap: 12 }}>
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
              <Text style={{ fontSize: 28 }}>{CONSULTANT.avatar}</Text>
            </View>
            <View style={{ flex: 1 }}>
              <Text style={{ color: "#D4AF37", fontSize: 17, fontWeight: "700" }}>
                {consultantName}
              </Text>
              {consultantTitle ? (
                <Text style={{ color: "rgba(255,255,255,0.75)", fontSize: 13, marginTop: 2 }}>
                  {consultantTitle}
                </Text>
              ) : null}
              <Text style={{ color: "rgba(255,255,255,0.5)", fontSize: 12, marginTop: 2 }}>
                {SESSION_DURATION_LABEL} · {t("consultationPerSession")}
              </Text>
            </View>
          </View>

          <View style={{ flexDirection: "row", gap: 8, flexWrap: "wrap" }}>
            {(lang === "ar" ? CONSULTANT.specialtiesAr : CONSULTANT.specialties).map((s) => (
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

          <View style={{ flexDirection: "row", justifyContent: "flex-end" }}>
            <View style={{ alignItems: isRTL ? "flex-start" : "flex-end" }}>
              <Text style={{ color: "#D4AF37", fontSize: 20, fontWeight: "700" }}>
                {CONSULTANT.pricePerSession} SAR
              </Text>
            </View>
          </View>
        </View>

        {/* Preferred date */}
        <Card>
          <SectionLabel title={t("consultationSelectDate")} />
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8 }}>
            {WEEK_DAYS.map((day, idx) => {
              const selected = selectedDayIdx === idx;
              return (
                <Pressable
                  key={idx}
                  onPress={() => {
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                    setSelectedDayIdx(idx);
                  }}
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
                  <Text
                    style={{
                      color: selected ? "rgba(255,255,255,0.65)" : colors.muted,
                      fontSize: 11,
                      fontWeight: "600",
                    }}
                  >
                    {day.dayLabel}
                  </Text>
                  <Text
                    style={{ color: selected ? "#D4AF37" : colors.foreground, fontSize: 17, fontWeight: "700" }}
                  >
                    {day.label}
                  </Text>
                </Pressable>
              );
            })}
          </ScrollView>
        </Card>

        {/* Preferred times */}
        <Card>
          <SectionLabel title={t("consultationPreferredTimes")} />
          <Text style={{ color: colors.muted, fontSize: 12, lineHeight: 18, marginBottom: 12 }}>
            {t("consultationPreferredTimesHint")}
          </Text>
          <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
            {PREFERRED_TIMES.map((time) => {
              const selected = times.includes(time);
              return (
                <Pressable
                  key={time}
                  onPress={() => toggleTime(time)}
                  style={{
                    paddingHorizontal: 14,
                    paddingVertical: 9,
                    borderRadius: 12,
                    backgroundColor: selected ? "#07352b" : colors.background,
                    borderWidth: 1,
                    borderColor: selected ? "#07352b" : colors.border,
                  }}
                >
                  <Text style={{ color: selected ? "#D4AF37" : colors.foreground, fontSize: 13, fontWeight: "600" }}>
                    {time}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </Card>

        {/* What the session covers */}
        <Card>
          <SectionLabel title={t("consultationWhatToExpect")} />
          <View style={{ gap: 10 }}>
            {[t("consultationExpect1"), t("consultationExpect2"), t("consultationExpect3")].map(
              (item) => (
                <View key={item} style={{ flexDirection: "row", gap: 8, alignItems: "flex-start" }}>
                  <IconSymbol name="checkmark.circle" size={16} color={colors.primary} />
                  <Text
                    style={{
                      color: colors.foreground,
                      fontSize: 13,
                      lineHeight: 20,
                      flex: 1,
                    }}
                  >
                    {item}
                  </Text>
                </View>
              ),
            )}
          </View>
        </Card>

        {/* Contact details */}
        <Card>
          <SectionLabel title={t("consultationYourDetails")} />
          <View style={{ gap: 12 }}>
            <TextInput
              value={fullName}
              onChangeText={setFullName}
              placeholder={t("fullName")}
              placeholderTextColor={colors.muted}
              autoCapitalize="words"
              textContentType={Platform.OS === "ios" ? "name" : undefined}
              style={inputStyle}
            />
            <TextInput
              value={email}
              onChangeText={setEmail}
              placeholder={t("email")}
              placeholderTextColor={colors.muted}
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
              textContentType={Platform.OS === "ios" ? "emailAddress" : undefined}
              style={inputStyle}
            />
            <TextInput
              value={phone}
              onChangeText={setPhone}
              placeholder={t("phoneNumber")}
              placeholderTextColor={colors.muted}
              keyboardType="phone-pad"
              autoCapitalize="none"
              textContentType={Platform.OS === "ios" ? "telephoneNumber" : undefined}
              style={inputStyle}
            />
            <TextInput
              value={notes}
              onChangeText={setNotes}
              placeholder={t("consultationNotesPlaceholder")}
              placeholderTextColor={colors.muted}
              multiline
              numberOfLines={4}
              style={[inputStyle, { minHeight: 96, textAlignVertical: "top" }]}
            />
          </View>
        </Card>

        {/* Failed: honest error + direct channels, form data is preserved */}
        {status === "failed" ? (
          <Card style={{ borderColor: colors.error, gap: 12 }}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
              <IconSymbol name="xmark.circle" size={18} color={colors.error} />
              <Text style={{ color: colors.foreground, fontSize: 15, fontWeight: "700" }}>
                {t("consultationFailedTitle")}
              </Text>
            </View>
            <Text style={{ color: colors.muted, fontSize: 13, lineHeight: 20 }}>
              {t("consultationSendFailed")}
            </Text>
            <View style={{ flexDirection: "row", gap: 10 }}>
              <View style={{ flex: 1 }}>
                <GoldButton label={t("retry")} onPress={handleSubmit} />
              </View>
              <Pressable
                onPress={() => contactFallback("email")}
                style={{
                  flex: 1,
                  borderRadius: 14,
                  borderWidth: 1,
                  borderColor: colors.border,
                  paddingVertical: 18,
                  alignItems: "center",
                }}
              >
                <Text style={{ color: colors.foreground, fontSize: 15, fontWeight: "700" }}>
                  {t("emailSupport")}
                </Text>
              </Pressable>
            </View>
            <Pressable
              onPress={() => contactFallback("whatsapp")}
              style={{ paddingVertical: 6, alignItems: "center" }}
            >
              <Text style={{ color: colors.primary, fontSize: 14, fontWeight: "600" }}>
                {t("consultationContactUs")} · WhatsApp
              </Text>
            </Pressable>
          </Card>
        ) : null}

        {/* Fee note: no card form, no fake payment */}
        <View style={{ flexDirection: "row", alignItems: "flex-start", gap: 8, paddingHorizontal: 4 }}>
          <IconSymbol name="info.circle" size={15} color={colors.muted} />
          <Text style={{ color: colors.muted, fontSize: 12, lineHeight: 18, flex: 1 }}>
            {t("consultationFeeNote").replace("{fee}", String(CONSULTANT.pricePerSession))}
          </Text>
        </View>

        <GoldButton
          label={status === "sending" ? t("consultationSubmitting") : t("consultationSubmit")}
          onPress={handleSubmit}
          disabled={status === "sending"}
        />

        <Text style={{ color: colors.muted, fontSize: 11, lineHeight: 17, textAlign: "center" }}>
          {t("consultationPriceDisclaimer")}
        </Text>
      </ScrollView>
    </ScreenContainer>
  );
}

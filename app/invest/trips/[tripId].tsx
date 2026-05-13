import { View, ScrollView, Pressable, Alert } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useTrips } from "@/lib/trips-provider";
import { useRouter, useLocalSearchParams } from "expo-router";
import { useMemo } from "react";
import * as Haptics from "expo-haptics";
import {
  averageStopTotal,
  cheapestStop,
  POPULAR_CITIES_AR,
  stopPerGramSAR,
  type FairnessVerdict,
  type TripStop,
} from "@/data/market-trips";
import { formatSAR } from "@/lib/portfolio-utils";

function VerdictBadge({ verdict }: { verdict: FairnessVerdict }) {
  const { t } = useI18n();
  const color =
    verdict === "excellent" ? "#22C55E" : verdict === "fair" ? "#0EA5E9" : "#EF4444";
  const label =
    verdict === "excellent"
      ? t("fairPriceLabelExcellent")
      : verdict === "fair"
        ? t("fairPriceLabelFair")
        : t("fairPriceLabelHigh");

  return (
    <View
      style={{
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 999,
        backgroundColor: color + "20",
      }}
    >
      <Text style={{ fontSize: 11, fontWeight: "700", color }}>{label}</Text>
    </View>
  );
}

function StopRow({
  stop,
  isBest,
  onPress,
  onLongPress,
}: {
  stop: TripStop;
  isBest: boolean;
  onPress: () => void;
  onLongPress: () => void;
}) {
  const colors = useColors();
  const { t, lang } = useI18n();
  const perGram = stopPerGramSAR(stop);

  return (
    <Pressable
      onPress={onPress}
      onLongPress={onLongPress}
      testID={`stop-row-${stop.id}`}
      style={({ pressed }) => ({
        opacity: pressed ? 0.75 : 1,
        backgroundColor: colors.surface,
        borderRadius: 14,
        borderWidth: 1,
        borderColor: isBest ? "#22C55E" : colors.border,
        padding: 12,
        gap: 10,
      })}
    >
      <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "flex-start" }}>
        <View style={{ flex: 1, gap: 4 }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
            <Text style={{ color: colors.foreground, fontSize: 15, fontWeight: "700" }} numberOfLines={1}>
              {stop.storeName}
            </Text>
            {isBest && (
              <View
                style={{
                  backgroundColor: "#22C55E",
                  paddingHorizontal: 8,
                  paddingVertical: 2,
                  borderRadius: 999,
                }}
              >
                <Text style={{ color: "#FFFFFF", fontSize: 10, fontWeight: "700" }}>
                  {t("bestStopBadge")}
                </Text>
              </View>
            )}
          </View>
          {stop.location ? (
            <View style={{ flexDirection: "row", alignItems: "center", gap: 4 }}>
              <IconSymbol name="location" size={12} color={colors.muted} />
              <Text style={{ color: colors.muted, fontSize: 12 }} numberOfLines={1}>
                {stop.location}
              </Text>
            </View>
          ) : null}
        </View>
        <VerdictBadge verdict={stop.verdict} />
      </View>

      <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
        <View style={{ gap: 2 }}>
          <Text style={{ color: colors.muted, fontSize: 11 }}>
            {stop.weightGrams} {t("grams")} · {stop.purityLabel}
          </Text>
          <Text style={{ color: colors.muted, fontSize: 11 }}>
            {formatSAR(perGram, lang)} / {t("grams")}
          </Text>
        </View>
        <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "800" }}>
          {formatSAR(stop.totalPriceSAR, lang)}
        </Text>
      </View>
    </Pressable>
  );
}

export default function TripDetailScreen() {
  const colors = useColors();
  const router = useRouter();
  const { t, lang } = useI18n();
  const { tripId } = useLocalSearchParams<{ tripId: string }>();
  const { getTripById, deleteStop, updateTrip, deleteTrip } = useTrips();
  const trip = getTripById(tripId);

  const summary = useMemo(() => {
    if (!trip) return null;
    const best = cheapestStop(trip.stops);
    const avg = averageStopTotal(trip.stops);
    const savings = best && avg > 0 ? avg - best.totalPriceSAR : 0;
    return { best, avg, savings };
  }, [trip]);

  if (!trip) {
    return (
      <ScreenContainer edges={["top", "left", "right", "bottom"]} className="bg-background">
        <View style={{ flex: 1, alignItems: "center", justifyContent: "center", gap: 8 }}>
          <Text style={{ color: colors.muted }}>{t("tripsEmptyTitle")}</Text>
          <Pressable
            onPress={() => router.replace("/invest/trips")}
            style={{ padding: 12 }}
          >
            <Text style={{ color: "#07352b", fontWeight: "700" }}>{t("tripsTitle")}</Text>
          </Pressable>
        </View>
      </ScreenContainer>
    );
  }

  const cityLabel =
    POPULAR_CITIES_AR.find((c) => c.id === trip.city)?.[lang === "ar" ? "nameAr" : "nameEn"] ?? trip.city;

  const handleDeleteStop = (stopId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    Alert.alert(
      t("deleteAsset"),
      "",
      [
        { text: t("cancel"), style: "cancel" },
        {
          text: t("deleteAsset"),
          style: "destructive",
          onPress: async () => {
            await deleteStop(trip.id, stopId);
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          },
        },
      ],
    );
  };

  const handleDeleteTrip = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    Alert.alert(
      t("deleteTrip"),
      t("deleteTripConfirm"),
      [
        { text: t("cancel"), style: "cancel" },
        {
          text: t("deleteTrip"),
          style: "destructive",
          onPress: async () => {
            await deleteTrip(trip.id);
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            router.replace("/invest/trips");
          },
        },
      ],
    );
  };

  const handleToggleStatus = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    await updateTrip(trip.id, { status: trip.status === "active" ? "completed" : "active" });
  };

  const stops = [...trip.stops].sort((a, b) => a.totalPriceSAR - b.totalPriceSAR);
  const best = summary?.best;

  return (
    <ScreenContainer edges={["top", "left", "right", "bottom"]} className="bg-background">
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
        <View style={{ flex: 1 }}>
          <Text style={{ color: colors.foreground, fontSize: 17, fontWeight: "700" }} numberOfLines={1}>
            {trip.name}
          </Text>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 6, marginTop: 2 }}>
            <IconSymbol name="location" size={12} color={colors.muted} />
            <Text style={{ color: colors.muted, fontSize: 12 }}>{cityLabel}</Text>
            <Text style={{ color: colors.muted, fontSize: 12 }}>·</Text>
            <Text style={{ color: colors.muted, fontSize: 12 }}>{trip.purityLabel}</Text>
            <Text style={{ color: colors.muted, fontSize: 12 }}>·</Text>
            <Text style={{ color: colors.muted, fontSize: 12 }}>{t(trip.category as any)}</Text>
          </View>
        </View>
        <Pressable onPress={handleDeleteTrip} testID="delete-trip-button" style={{ padding: 4 }}>
          <IconSymbol name="trash" size={20} color={colors.muted} />
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, gap: 16, paddingBottom: 96 }}>
        {/* Summary card */}
        <View
          style={{
            backgroundColor: colors.surface,
            borderRadius: 16,
            padding: 16,
            borderWidth: 1,
            borderColor: colors.border,
            gap: 12,
          }}
        >
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
            <Text style={{ color: colors.foreground, fontSize: 13, fontWeight: "700" }}>
              {t("tripStops")} · {trip.stops.length}
            </Text>
            <Pressable onPress={handleToggleStatus} testID="toggle-status-button">
              <Text style={{ color: "#07352b", fontSize: 12, fontWeight: "700" }}>
                {trip.status === "active" ? t("markTripCompleted") : t("reopenTrip")}
              </Text>
            </Pressable>
          </View>

          {best && summary ? (
            <>
              <View
                style={{
                  backgroundColor: "#22C55E10",
                  borderRadius: 12,
                  padding: 12,
                  gap: 4,
                }}
              >
                <Text style={{ color: "#15803D", fontSize: 11, fontWeight: "700" }}>
                  {t("tripBestPrice")}
                </Text>
                <Text style={{ color: colors.foreground, fontSize: 22, fontWeight: "800" }}>
                  {formatSAR(best.totalPriceSAR, lang)}
                </Text>
                <Text style={{ color: colors.muted, fontSize: 12 }} numberOfLines={1}>
                  {best.storeName}
                </Text>
              </View>
              <View style={{ flexDirection: "row", gap: 12 }}>
                <View style={{ flex: 1 }}>
                  <Text style={{ color: colors.muted, fontSize: 11 }}>{t("tripAverage")}</Text>
                  <Text style={{ color: colors.foreground, fontSize: 14, fontWeight: "700" }}>
                    {formatSAR(summary.avg, lang)}
                  </Text>
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ color: colors.muted, fontSize: 11 }}>{t("tripSavings")}</Text>
                  <Text style={{ color: summary.savings > 0 ? "#22C55E" : colors.muted, fontSize: 14, fontWeight: "700" }}>
                    {formatSAR(summary.savings, lang)}
                  </Text>
                </View>
              </View>
            </>
          ) : (
            <Text style={{ color: colors.muted, fontSize: 13, paddingVertical: 12, textAlign: "center" }}>
              {t("noStopsYet")}
            </Text>
          )}
        </View>

        {/* Stops list */}
        <View style={{ gap: 10 }}>
          {stops.map((stop) => (
            <StopRow
              key={stop.id}
              stop={stop}
              isBest={best?.id === stop.id && stops.length > 1}
              onPress={() => {
                /* tap = no-op for now; could be edit */
              }}
              onLongPress={() => handleDeleteStop(stop.id)}
            />
          ))}
        </View>
      </ScrollView>

      {/* Add stop CTA */}
      <View
        style={{
          position: "absolute",
          bottom: 16,
          left: 16,
          right: 16,
        }}
      >
        <Pressable
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
            router.push({ pathname: "/invest/trips/add-stop", params: { tripId: trip.id } });
          }}
          testID="add-stop-button"
          style={({ pressed }) => ({
            opacity: pressed ? 0.85 : 1,
            backgroundColor: "#07352b",
            paddingVertical: 14,
            borderRadius: 16,
            flexDirection: "row",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
            shadowColor: "#000",
            shadowOpacity: 0.18,
            shadowRadius: 12,
            shadowOffset: { width: 0, height: 6 },
            elevation: 4,
          })}
        >
          <IconSymbol name="plus" size={20} color="#D4AF37" />
          <Text style={{ color: "#D4AF37", fontSize: 15, fontWeight: "700" }}>
            {t("addStop")}
          </Text>
        </Pressable>
      </View>
    </ScreenContainer>
  );
}

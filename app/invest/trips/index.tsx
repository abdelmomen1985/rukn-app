import { View, ScrollView, Pressable, Alert } from "react-native";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useTrips } from "@/lib/trips-provider";
import { useRouter } from "expo-router";
import { useMemo } from "react";
import * as Haptics from "expo-haptics";
import {
  cheapestStop,
  POPULAR_CITIES_AR,
  type MarketTrip,
} from "@/data/market-trips";
import { formatSAR } from "@/lib/portfolio-utils";

function StatusPill({ status }: { status: MarketTrip["status"] }) {
  const { t } = useI18n();
  const colors = useColors();
  const active = status === "active";
  return (
    <View
      style={{
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 999,
        backgroundColor: active ? "#07352b15" : colors.surface,
        borderWidth: 1,
        borderColor: active ? "#07352b" : colors.border,
      }}
    >
      <Text style={{ fontSize: 11, fontWeight: "700", color: active ? "#07352b" : colors.muted }}>
        {active ? t("tripStatusActive") : t("tripStatusCompleted")}
      </Text>
    </View>
  );
}

function TripCard({
  trip,
  onPress,
  onLongPress,
}: {
  trip: MarketTrip;
  onPress: () => void;
  onLongPress: () => void;
}) {
  const colors = useColors();
  const { t, lang } = useI18n();
  const best = cheapestStop(trip.stops);
  const cityLabel =
    POPULAR_CITIES_AR.find((c) => c.id === trip.city)?.[lang === "ar" ? "nameAr" : "nameEn"] ?? trip.city;

  return (
    <Pressable
      onPress={() => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        onPress();
      }}
      onLongPress={onLongPress}
      style={({ pressed }) => ({
        opacity: pressed ? 0.7 : 1,
        backgroundColor: colors.surface,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: colors.border,
        padding: 14,
        gap: 10,
      })}
    >
      <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "flex-start", gap: 8 }}>
        <View style={{ flex: 1 }}>
          <Text style={{ color: colors.foreground, fontSize: 16, fontWeight: "700" }} numberOfLines={1}>
            {trip.name}
          </Text>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 6, marginTop: 4 }}>
            <IconSymbol name="location" size={13} color={colors.muted} />
            <Text style={{ color: colors.muted, fontSize: 12 }}>{cityLabel}</Text>
            <Text style={{ color: colors.muted, fontSize: 12 }}>·</Text>
            <Text style={{ color: colors.muted, fontSize: 12 }}>{trip.purityLabel}</Text>
            <Text style={{ color: colors.muted, fontSize: 12 }}>·</Text>
            <Text style={{ color: colors.muted, fontSize: 12 }}>
              {trip.stops.length} {t("tripStops")}
            </Text>
          </View>
        </View>
        <StatusPill status={trip.status} />
      </View>

      {best ? (
        <View
          style={{
            flexDirection: "row",
            justifyContent: "space-between",
            alignItems: "center",
            backgroundColor: colors.background,
            borderRadius: 10,
            paddingHorizontal: 12,
            paddingVertical: 8,
            borderWidth: 1,
            borderColor: colors.border,
          }}
        >
          <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
            <IconSymbol name="sparkles" size={14} color="#07352b" />
            <Text style={{ fontSize: 12, fontWeight: "600", color: "#07352b" }}>
              {t("tripBestPrice")}
            </Text>
          </View>
          <Text style={{ fontSize: 14, fontWeight: "700", color: colors.foreground }}>
            {formatSAR(best.totalPriceSAR, lang)}
          </Text>
        </View>
      ) : (
        <Text style={{ color: colors.muted, fontSize: 12 }}>{t("noStopsYet")}</Text>
      )}
    </Pressable>
  );
}

export default function TripsListScreen() {
  const colors = useColors();
  const router = useRouter();
  const { t } = useI18n();
  const { trips, deleteTrip } = useTrips();

  const sortedTrips = useMemo(
    () =>
      [...trips].sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()),
    [trips],
  );

  const handleDelete = (trip: MarketTrip) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
    Alert.alert(
      t("deleteTrip"),
      `${t("deleteTripConfirm")}\n\n"${trip.name}"`,
      [
        { text: t("cancel"), style: "cancel" },
        {
          text: t("deleteTrip"),
          style: "destructive",
          onPress: async () => {
            await deleteTrip(trip.id);
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          },
        },
      ],
    );
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
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            router.back();
          }}
          style={({ pressed }) => ({ opacity: pressed ? 0.7 : 1, padding: 4 })}
          testID="back-button"
        >
          <IconSymbol name="chevron.left" size={24} color={colors.foreground} />
        </Pressable>
        <View style={{ flex: 1 }}>
          <Text style={{ color: colors.foreground, fontSize: 18, fontWeight: "700" }}>
            {t("tripsTitle")}
          </Text>
          <Text style={{ color: colors.muted, fontSize: 12 }}>{t("tripsSubtitle")}</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, gap: 12, paddingBottom: 96 }}>
        {sortedTrips.length === 0 ? (
          <View style={{ alignItems: "center", paddingVertical: 64, gap: 12 }}>
            <Text style={{ fontSize: 56 }}>🛍️</Text>
            <Text style={{ color: colors.foreground, fontSize: 16, fontWeight: "700" }}>
              {t("tripsEmptyTitle")}
            </Text>
            <Text
              style={{ color: colors.muted, fontSize: 13, textAlign: "center", maxWidth: 280 }}
            >
              {t("tripsEmptySubtitle")}
            </Text>
          </View>
        ) : (
          sortedTrips.map((trip) => (
            <TripCard
              key={trip.id}
              trip={trip}
              onPress={() => router.push({ pathname: "/invest/trips/[tripId]", params: { tripId: trip.id } })}
              onLongPress={() => handleDelete(trip)}
            />
          ))
        )}
      </ScrollView>

      {/* New trip CTA */}
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
            router.push("/invest/trips/new");
          }}
          testID="new-trip-button"
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
            {t("newTrip")}
          </Text>
        </Pressable>
      </View>
    </ScreenContainer>
  );
}

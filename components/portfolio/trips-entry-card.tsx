import { View, Pressable } from "react-native";
import { Text } from "@/components/ui/text";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useI18n } from "@/lib/i18n";
import { useTrips } from "@/lib/trips-provider";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";

/**
 * Shopping-trip ("جولة تسوق") entry card on the Invest / مدخراتي screen.
 * Shows a count of active trips and links into the trips list.
 */
export function TripsEntryCard() {
  const router = useRouter();
  const { t, isRTL } = useI18n();
  const { trips } = useTrips();

  const activeCount = trips.filter((trip) => trip.status === "active").length;

  return (
    <Pressable
      onPress={() => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        router.push("/invest/trips");
      }}
      testID="trips-entry-card"
      style={({ pressed }) => ({
        opacity: pressed ? 0.85 : 1,
        marginHorizontal: 16,
        marginTop: 12,
        backgroundColor: "#A4313F",
        borderRadius: 16,
        padding: 16,
        flexDirection: "row",
        alignItems: "center",
        gap: 12,
      })}
    >
      <View
        style={{
          width: 44,
          height: 44,
          borderRadius: 22,
          backgroundColor: "#FFFFFF20",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <IconSymbol name="bag" size={22} color="#FFFFFF" />
      </View>
      <View style={{ flex: 1 }}>
        <Text style={{ color: "#FFFFFF", fontSize: 15, fontWeight: "800" }}>
          {t("tripsCardLabel")}
        </Text>
        <Text style={{ color: "#FFFFFF", opacity: 0.85, fontSize: 12, marginTop: 2 }}>
          {activeCount > 0
            ? `${activeCount} ${t("tripStatusActive")} · ${t("tripsSubtitle")}`
            : t("tripsSubtitle")}
        </Text>
      </View>
      <IconSymbol
        name={isRTL ? "chevron.left" : "chevron.right"}
        size={18}
        color="#FFFFFF"
      />
    </Pressable>
  );
}

import { View, Pressable } from "react-native";
import { Text } from "@/components/ui/text";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useI18n } from "@/lib/i18n";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";

interface NisabAlertBannerProps {
  visible: boolean;
}

export function NisabAlertBanner({ visible }: NisabAlertBannerProps) {
  const { t } = useI18n();
  const router = useRouter();

  if (!visible) return null;

  return (
    <Pressable
      onPress={() => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
        router.push("/portfolio/zakat");
      }}
      style={({ pressed }) => ({ opacity: pressed ? 0.85 : 1 })}
    >
      <View
        style={{
          backgroundColor: "#FFFBEB",
          borderRadius: 12,
          padding: 12,
          marginHorizontal: 16,
          marginTop: 10,
          flexDirection: "row",
          alignItems: "center",
          gap: 10,
          borderWidth: 1,
          borderColor: "#FCD34D",
        }}
      >
        <View
          style={{
            width: 32,
            height: 32,
            borderRadius: 16,
            backgroundColor: "#FEF3C7",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <IconSymbol name="scale" size={16} color="#D97706" />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={{ color: "#92400E", fontSize: 13, fontWeight: "600" }}>
            {t("nisabAlert")}
          </Text>
          <Text style={{ color: "#B45309", fontSize: 12 }}>
            Tap to calculate your {t("zakat")}
          </Text>
        </View>
        <IconSymbol name="chevron.right" size={16} color="#D97706" />
      </View>
    </Pressable>
  );
}

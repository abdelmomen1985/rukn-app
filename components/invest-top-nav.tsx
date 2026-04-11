import { View, Pressable, StyleSheet } from "react-native";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { useRouter } from "expo-router";
import * as Haptics from "expo-haptics";

export function InvestTopNav() {
  const colors = useColors();
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Pressable
        testID="converter-button"
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          router.push("/invest/converter");
        }}
        style={({ pressed }) => [styles.button, {
          opacity: pressed ? 0.7 : 1,
          backgroundColor: colors.surface,
          borderColor: colors.border,
        }]}
      >
        <IconSymbol name="arrow.left.arrow.right" size={20} color={colors.primary} />
      </Pressable>
      <Pressable
        testID="zakat-button"
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          router.push("/invest/zakat");
        }}
        style={({ pressed }) => [styles.button, {
          opacity: pressed ? 0.7 : 1,
          backgroundColor: colors.surface,
          borderColor: colors.border,
        }]}
      >
        <IconSymbol name="scale" size={20} color="#D97706" />
      </Pressable>
      <Pressable
        testID="consultation-button"
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          router.push("/invest/consultation");
        }}
        style={({ pressed }) => [styles.button, {
          opacity: pressed ? 0.7 : 1,
          backgroundColor: colors.surface,
          borderColor: colors.border,
        }]}
      >
        <IconSymbol name="person.fill.questionmark" size={20} color="#059669" />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
  },
  button: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
});
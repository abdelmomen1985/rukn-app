import { Pressable, type ViewStyle } from "react-native";
import { Text } from "@/components/ui/text";
import * as Haptics from "expo-haptics";

export interface CTAButtonProps {
  title: string;
  onPress?: () => void;
  variant?: "primary" | "outline";
  style?: ViewStyle;
  disabled?: boolean;
}

export function CTAButton({ title, onPress, variant = "primary", style, disabled = false }: CTAButtonProps) {
  const handlePress = () => {
    if (disabled) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onPress?.();
  };

  return (
    <Pressable
      onPress={handlePress}
      style={({ pressed }) => [
        {
          transform: [{ scale: pressed && !disabled ? 0.97 : 1 }],
          opacity: disabled ? 0.5 : pressed ? 0.9 : 1,
        },
        style,
      ]}
      className={
        variant === "primary"
          ? "bg-primary px-8 py-4 rounded-full items-center justify-center"
          : "border-2 border-primary px-8 py-4 rounded-full items-center justify-center"
      }
    >
      <Text
        className={variant === "primary" ? "text-darkGreen text-lg font-bold" : "text-primary text-lg font-bold"}
        style={{ fontFamily: "Cormorant_Garamond" }}
      >
        {title}
      </Text>
    </Pressable>
  );
}

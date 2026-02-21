import { View, Text, Pressable } from "react-native";
import * as Haptics from "expo-haptics";
import { IconSymbol } from "./ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";

export interface SectionHeaderProps {
  title: string;
  subtitle?: string;
  showViewMore?: boolean;
  onViewMorePress?: () => void;
}

export function SectionHeader({ title, subtitle, showViewMore = false, onViewMorePress }: SectionHeaderProps) {
  const colors = useColors();

  const handleViewMorePress = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onViewMorePress?.();
  };

  return (
    <View className="flex-row justify-between items-end px-6 mb-6">
      <View className="flex-1 gap-2">
        <Text className="text-foreground text-4xl font-semibold" style={{ fontFamily: "Cormorant_Garamond" }}>
          {title}
        </Text>
        {subtitle && (
          <Text className="text-foreground text-base font-medium" style={{ fontFamily: "Cormorant_Garamond" }}>
            {subtitle}
          </Text>
        )}
      </View>
      {showViewMore && (
        <Pressable
          onPress={handleViewMorePress}
          style={({ pressed }) => ({
            opacity: pressed ? 0.6 : 1,
          })}
          className="flex-row items-center gap-2 border border-darkGreen rounded-lg px-4 py-2"
        >
          <Text className="text-darkGreen text-base font-semibold" style={{ fontFamily: "Cormorant_Garamond" }}>
            View more
          </Text>
          <IconSymbol name="chevron.right" size={16} color={colors.darkGreen} />
        </Pressable>
      )}
    </View>
  );
}

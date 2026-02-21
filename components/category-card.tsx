import { View, Text, ImageBackground, Pressable, type ImageSourcePropType } from "react-native";
import * as Haptics from "expo-haptics";
import { IconSymbol } from "./ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";
import { LinearGradient } from "expo-linear-gradient";

export interface CategoryCardProps {
  title: string;
  description: string;
  image: ImageSourcePropType;
  onPress?: () => void;
}

export function CategoryCard({ title, description, image, onPress }: CategoryCardProps) {
  const colors = useColors();

  const handlePress = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onPress?.();
  };

  return (
    <Pressable
      onPress={handlePress}
      style={({ pressed }) => ({
        opacity: pressed ? 0.9 : 1,
      })}
      className="w-[280px] h-[420px] rounded-2xl overflow-hidden"
    >
      <ImageBackground source={image} className="w-full h-full justify-end" resizeMode="cover">
        <LinearGradient
          colors={["transparent", "rgba(0,0,0,0.7)"]}
          className="p-6 gap-4"
        >
          <View className="gap-2">
            <Text className="text-white text-3xl font-bold" style={{ fontFamily: "Cormorant_Garamond" }}>
              {title}
            </Text>
            <Text className="text-white text-sm font-medium" numberOfLines={2}>
              {description}
            </Text>
          </View>
          <View className="flex-row items-center gap-2">
            <Text className="text-primary text-base font-semibold">Explore</Text>
            <IconSymbol name="chevron.right" size={18} color={colors.primary} />
          </View>
        </LinearGradient>
      </ImageBackground>
    </Pressable>
  );
}

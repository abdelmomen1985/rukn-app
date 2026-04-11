import { View, Image, Pressable, type ImageSourcePropType } from "react-native";
import { Text } from "@/components/ui/text";
import { useState } from "react";
import * as Haptics from "expo-haptics";
import { IconSymbol } from "./ui/icon-symbol";
import { useColors } from "@/hooks/use-colors";

export interface ProductCardProps {
  id: string;
  name: string;
  price: number;
  image: ImageSourcePropType;
  onPress?: () => void;
  onWishlistToggle?: (id: string, isWishlisted: boolean) => void;
  onAddToCart?: (id: string) => void;
  initialWishlisted?: boolean;
  inCart?: boolean;
}

export function ProductCard({
  id,
  name,
  price,
  image,
  onPress,
  onWishlistToggle,
  onAddToCart,
  initialWishlisted = false,
  inCart = false,
}: ProductCardProps) {
  const colors = useColors();
  const [isWishlisted, setIsWishlisted] = useState(initialWishlisted);

  const handleWishlistToggle = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    const newState = !isWishlisted;
    setIsWishlisted(newState);
    onWishlistToggle?.(id, newState);
  };

  const handleAddToCart = () => {
    if (inCart) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onAddToCart?.(id);
  };

  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => ({
        opacity: pressed ? 0.7 : 1,
        overflow: "hidden",
      })}
      className="w-full bg-surface rounded-lg overflow-hidden"
    >
      <View style={{ position: "relative", width: "100%", height: 156, overflow: "hidden" }}>
        <Image source={image} style={{ width: "100%", height: 156 }} resizeMode="cover" />
        <Pressable
          onPress={handleWishlistToggle}
          style={({ pressed }) => ({
            opacity: pressed ? 0.6 : 1,
          })}
          className="absolute top-2 right-2 w-8 h-8 bg-white rounded-full items-center justify-center"
        >
          <IconSymbol
            name={isWishlisted ? "heart.fill" : "heart"}
            size={18}
            color={isWishlisted ? colors.primary : colors.foreground}
          />
        </Pressable>
      </View>
      <View className="p-3 gap-2">
        <Text className="text-foreground text-sm font-medium" numberOfLines={2}>
          {name}
        </Text>
        <View className="flex-row items-center justify-between">
          <View className="flex-row items-center gap-1">
            <Text className="text-primary text-base font-bold">${price.toFixed(2)}</Text>
          </View>
          <Pressable
            onPress={handleAddToCart}
            disabled={inCart}
            style={({ pressed }) => ({
              opacity: pressed ? 0.6 : inCart ? 0.5 : 1,
            })}
            className={`w-8 h-8 rounded-full items-center justify-center ${inCart ? "bg-muted" : "bg-primary"}`}
          >
            <IconSymbol
              name={inCart ? "checkmark" : "bag"}
              size={16}
              color={inCart ? colors.foreground : colors.darkGreen}
            />
          </Pressable>
        </View>
      </View>
    </Pressable>
  );
}

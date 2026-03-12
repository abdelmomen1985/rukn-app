import { View, Image, Pressable } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useRouter } from "expo-router";
import { useEffect, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { Text } from "@/components/ui/text";
import { useI18n } from "@/lib/i18n";

export function TitleBar() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { t } = useI18n();
  const [wishlistCount, setWishlistCount] = useState(0);
  const [cartCount, setCartCount] = useState(0);

  useEffect(() => {
    const load = async () => {
      try {
        const [w, c] = await Promise.all([
          AsyncStorage.getItem("wishlist"),
          AsyncStorage.getItem("cart"),
        ]);
        setWishlistCount(w ? JSON.parse(w).length : 0);
        setCartCount(c ? JSON.parse(c).length : 0);
      } catch {}
    };
    load();
  }, []);

  return (
    <View
      style={{ paddingTop: insets.top, backgroundColor: "#07352b" }}
      className="px-6 py-4 flex-row justify-between items-center"
    >
      {/* Search */}
      <Pressable
        onPress={() => {}}
        className="flex-row items-center gap-4"
      >
        <IconSymbol name="magnifyingglass" size={24} color="#D4AF37" />
        <Text className="text-primary text-base font-medium">{t("search")}</Text>
      </Pressable>

      {/* Logo */}
      <Image
        source={require("@/assets/figma-assets/1593-8372.webp")}
        className="w-16 h-16"
        resizeMode="contain"
      />

      {/* Wishlist + Cart */}
      <View className="flex-row items-center gap-4">
        <Pressable
          onPress={() => router.push("/(tabs)/wishlist")}
          className="relative"
        >
          <IconSymbol name="heart" size={26} color="#D4AF37" />
          {wishlistCount > 0 && (
            <View className="absolute -top-1 -right-1 bg-primary w-4 h-4 rounded-full items-center justify-center">
              <Text className="text-darkGreen text-[10px] font-bold">
                {wishlistCount}
              </Text>
            </View>
          )}
        </Pressable>

        <Pressable
          onPress={() => router.push("/(tabs)/cart")}
          className="relative"
        >
          <IconSymbol name="cart" size={26} color="#D4AF37" />
          {cartCount > 0 && (
            <View className="absolute -top-1 -right-1 bg-primary w-4 h-4 rounded-full items-center justify-center">
              <Text className="text-darkGreen text-[10px] font-bold">
                {cartCount}
              </Text>
            </View>
          )}
        </Pressable>
      </View>
    </View>
  );
}

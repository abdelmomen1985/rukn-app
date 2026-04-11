import { View, ScrollView, Image, Pressable } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Text } from "@/components/ui/text";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { CTAButton } from "@/components/cta-button";
import { products } from "@/data/products";
import { useLocalSearchParams, useRouter, useFocusEffect } from "expo-router";
import { useColors } from "@/hooks/use-colors";
import { useI18n } from "@/lib/i18n";
import { useState, useCallback } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";

export default function ProductDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const colors = useColors();
  const { t, isRTL, lang } = useI18n();
  const insets = useSafeAreaInsets();

  const product = products.find((p) => p.id === id);

  const [isWishlisted, setIsWishlisted] = useState(false);
  const [inCart, setInCart] = useState(false);

  useFocusEffect(
    useCallback(() => {
      Promise.all([
        AsyncStorage.getItem("wishlist"),
        AsyncStorage.getItem("cart"),
      ]).then(([wishlistData, cartData]) => {
        setIsWishlisted(wishlistData ? new Set(JSON.parse(wishlistData)).has(id) : false);
        setInCart(cartData ? new Set(JSON.parse(cartData)).has(id) : false);
      }).catch((err) => console.error("Failed to load states:", err));
    }, [id])
  );

  const handleWishlistToggle = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    try {
      const data = await AsyncStorage.getItem("wishlist");
      const wishlist = new Set<string>(data ? JSON.parse(data) : []);
      if (isWishlisted) {
        wishlist.delete(id);
      } else {
        wishlist.add(id);
      }
      await AsyncStorage.setItem("wishlist", JSON.stringify(Array.from(wishlist)));
      setIsWishlisted(!isWishlisted);
    } catch (error) {
      console.error("Failed to update wishlist:", error);
    }
  };

  const handleAddToCart = async () => {
    if (inCart) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    try {
      const data = await AsyncStorage.getItem("cart");
      const cart = new Set<string>(data ? JSON.parse(data) : []);
      cart.add(id);
      await AsyncStorage.setItem("cart", JSON.stringify(Array.from(cart)));
      setInCart(true);
    } catch (error) {
      console.error("Failed to update cart:", error);
    }
  };

  const displayName = lang === "ar" && product?.nameAr ? product.nameAr : product?.name;
  const displayDescription = lang === "ar" && product?.descriptionAr ? product.descriptionAr : product?.description;
  const priceLocale = lang === "ar" ? "ar-SA" : "en-US";

  if (!product) {
    return (
      <ScreenContainer className="bg-background">
        <View className="flex-1 items-center justify-center">
          <Text className="text-muted text-lg">{t("productNotFound")}</Text>
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer className="bg-background">
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View className="flex-row items-center justify-between px-4 py-4">
          <Pressable
            onPress={() => router.back()}
            style={({ pressed }) => ({ opacity: pressed ? 0.6 : 1 })}
            className="w-10 h-10 items-center justify-center rounded-full bg-surface"
          >
            <IconSymbol
              name={isRTL ? "chevron.right" : "chevron.left"}
              size={20}
              color={colors.foreground}
            />
          </Pressable>
          <Pressable
            onPress={handleWishlistToggle}
            style={({ pressed }) => ({ opacity: pressed ? 0.6 : 1 })}
            className="w-10 h-10 items-center justify-center rounded-full bg-surface"
          >
            <IconSymbol
              name={isWishlisted ? "heart.fill" : "heart"}
              size={20}
              color={isWishlisted ? colors.primary : colors.foreground}
            />
          </Pressable>
        </View>

        {/* Product Image */}
        <Image
          source={product.image}
          style={{ width: "100%", height: 360 }}
          resizeMode="cover"
        />

        {/* Product Info */}
        <View className="px-6 py-6 gap-4">
          <View className="gap-1">
            <Text
              className="text-foreground text-2xl font-bold"
              style={{ fontFamily: "Cormorant_Garamond" }}
            >
              {displayName}
            </Text>
            <Text
              className="text-primary text-3xl font-bold"
            >
              {product.price.toLocaleString(priceLocale, { minimumFractionDigits: 2, maximumFractionDigits: 2, style: "currency", currency: "USD" })}
            </Text>
          </View>

          {/* Divider */}
          <View className="h-px bg-border" />

          {/* Description */}
          {displayDescription && (
            <View className="gap-2">
              <Text className="text-foreground text-base font-semibold">
                {t("productDetails")}
              </Text>
              <Text className="text-muted text-sm leading-6">
                {displayDescription}
              </Text>
            </View>
          )}

          {/* Spacer for bottom button */}
          <View className="h-20" />
        </View>
      </ScrollView>

      {/* Add to Cart Button */}
      <View
        className="absolute bottom-0 left-0 right-0 bg-background border-t border-border px-6 py-4"
        style={{ paddingBottom: insets.bottom }}
      >
        <CTAButton
          title={inCart ? t("addedToCart") : t("addToCart")}
          onPress={handleAddToCart}
          disabled={inCart}
        />
      </View>
    </ScreenContainer>
  );
}

import { ScrollView, View, FlatList, Pressable, ImageBackground, Platform } from "react-native";
import { Text } from "@/components/ui/text";
import { TitleBar } from "@/components/title-bar";
import { ScreenContainer } from "@/components/screen-container";
import { ProductCard } from "@/components/product-card";
import { products, categories } from "@/data/products";
import { useColors } from "@/hooks/use-colors";
import { LinearGradient } from "expo-linear-gradient";
import { useState, useCallback } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { cn } from "@/lib/utils";
import { useI18n } from "@/lib/i18n";
import { useRouter, useFocusEffect } from "expo-router";

export default function HomeScreen() {
  const colors = useColors();
  const { t, isRTL } = useI18n();
  const router = useRouter();
  const [wishlist, setWishlist] = useState<Set<string>>(new Set());
  const [cart, setCart] = useState<Set<string>>(new Set());
  const [selectedCategory, setSelectedCategory] = useState<string>("all");

  useFocusEffect(
    useCallback(() => {
      AsyncStorage.getItem("wishlist")
        .then((data) => setWishlist(new Set(data ? JSON.parse(data) : [])))
        .catch((err) => console.error("Failed to load wishlist:", err));
      AsyncStorage.getItem("cart")
        .then((data) => setCart(new Set(data ? JSON.parse(data) : [])))
        .catch((err) => console.error("Failed to load cart:", err));
    }, [])
  );

  const handleWishlistToggle = async (id: string, isWishlisted: boolean) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const newWishlist = new Set(wishlist);
    if (isWishlisted) {
      newWishlist.add(id);
    } else {
      newWishlist.delete(id);
    }
    setWishlist(newWishlist);
    try {
      await AsyncStorage.setItem("wishlist", JSON.stringify(Array.from(newWishlist)));
    } catch (error) {
      console.error("Failed to save wishlist:", error);
    }
  };

  const handleAddToCart = async (id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const newCart = new Set(cart);
    newCart.add(id);
    setCart(newCart);
    try {
      await AsyncStorage.setItem("cart", JSON.stringify(Array.from(newCart)));
    } catch (error) {
      console.error("Failed to save cart:", error);
    }
  };

  const filteredProducts =
    selectedCategory === "all"
      ? products
      : products.filter((p) => p.category === selectedCategory);

  return (
    <ScreenContainer edges={["left", "right"]} className="bg-background">
      <ScrollView showsVerticalScrollIndicator={false}>
        <TitleBar />

        {/* Hero Section */}
        <ImageBackground
          source={require("@/assets/figma-assets/1586-4213.webp")}
          className="h-[400px] justify-center"
          resizeMode="cover"
        >
          <LinearGradient colors={["rgba(0,0,0,0.5)", "transparent", "rgba(0,0,0,0.6)"]} className="h-full justify-center px-6">
            <View className="gap-6 max-w-[320px]">
              <Text className="text-white text-5xl font-bold" style={{ fontFamily: "Cormorant_Garamond", textAlign: isRTL ? "right" : "left" }}>
                {t("heroTitle")}
              </Text>
              <Text className="text-white text-base font-medium" style={{ textAlign: isRTL ? "right" : "left" }}>
                {t("heroSubtitle")}
              </Text>
            </View>
          </LinearGradient>
        </ImageBackground>

        {/* Products Section */}
        <View className="bg-background px-6 py-8">
          {/* Section Title */}
          <View className="flex-row justify-between items-center mb-6">
            <Text className="text-foreground text-2xl font-bold" style={{ fontFamily: "Cormorant_Garamond" }}>
              {t("newArrivals")}
            </Text>
            <Pressable>
              <Text className="text-primary text-base font-semibold">{t("viewAll")}</Text>
            </Pressable>
          </View>

          {/* Category Filter Tabs */}
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={{ gap: 8, marginBottom: 24 }}
          >
            {/* All Products */}
            <Pressable
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                setSelectedCategory("all");
              }}
              style={({ pressed }) => ({
                opacity: pressed ? 0.8 : 1,
              })}
              className={cn(
                "px-4 py-2 rounded-full border",
                selectedCategory === "all"
                  ? "bg-primary border-primary"
                  : "bg-surface border-border"
              )}
            >
              <Text
                className={cn(
                  "text-sm font-semibold",
                  selectedCategory === "all" ? "text-darkGreen" : "text-foreground"
                )}
              >
                {t("all")}
              </Text>
            </Pressable>

            {/* Category Tabs */}
            {categories.map((category) => (
              <Pressable
                key={category.id}
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setSelectedCategory(category.id);
                }}
                style={({ pressed }) => ({
                  opacity: pressed ? 0.8 : 1,
                })}
                className={cn(
                  "px-4 py-2 rounded-full border",
                  selectedCategory === category.id
                    ? "bg-primary border-primary"
                    : "bg-surface border-border"
                )}
              >
                <Text
                  className={cn(
                    "text-sm font-semibold",
                    selectedCategory === category.id ? "text-darkGreen" : "text-foreground"
                  )}
                >
                  {t(category.id as any)}
                </Text>
              </Pressable>
            ))}
          </ScrollView>

          {/* Products Grid */}
          {filteredProducts.length === 0 ? (
            <View className="items-center justify-center py-12">
              <Text className="text-muted text-lg">{t("noProductsFound")}</Text>
            </View>
          ) : Platform.OS === "web" ? (
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 12 }}>
              {filteredProducts.map((item) => (
                <View key={item.id} style={{ width: "calc(50% - 6px)" as any }}>
                  <ProductCard
                    id={item.id}
                    name={item.name}
                    price={item.price}
                    image={item.image}
                    initialWishlisted={wishlist.has(item.id)}
                    onWishlistToggle={handleWishlistToggle}
                    onAddToCart={handleAddToCart}
                    inCart={cart.has(item.id)}
                    onPress={() => router.push(`/product/${item.id}`)}
                  />
                </View>
              ))}
            </View>
          ) : (
            <FlatList
              data={filteredProducts}
              numColumns={2}
              columnWrapperStyle={{ gap: 12, marginBottom: 12 }}
              scrollEnabled={false}
              renderItem={({ item }) => (
                <View className="flex-1">
                  <ProductCard
                    id={item.id}
                    name={item.name}
                    price={item.price}
                    image={item.image}
                    initialWishlisted={wishlist.has(item.id)}
                    onWishlistToggle={handleWishlistToggle}
                    onAddToCart={handleAddToCart}
                    inCart={cart.has(item.id)}
                    onPress={() => router.push(`/product/${item.id}`)}
                  />
                </View>
              )}
              keyExtractor={(item) => item.id}
            />
          )}
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}

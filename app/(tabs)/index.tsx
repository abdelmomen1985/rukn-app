import { ScrollView, Text, View, FlatList, Pressable, Image, ImageBackground } from "react-native";
import { ScreenContainer } from "@/components/screen-container";
import { ProductCard } from "@/components/product-card";
import { products, categories } from "@/data/products";
import { useColors } from "@/hooks/use-colors";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { LinearGradient } from "expo-linear-gradient";
import { useState, useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { cn } from "@/lib/utils";

export default function HomeScreen() {
  const colors = useColors();
  const [wishlist, setWishlist] = useState<Set<string>>(new Set());
  const [cart, setCart] = useState<Set<string>>(new Set());
  const [selectedCategory, setSelectedCategory] = useState<string>("all");

  useEffect(() => {
    loadWishlist();
    loadCart();
  }, []);

  const loadWishlist = async () => {
    try {
      const data = await AsyncStorage.getItem("wishlist");
      if (data) {
        setWishlist(new Set(JSON.parse(data)));
      }
    } catch (error) {
      console.error("Failed to load wishlist:", error);
    }
  };

  const loadCart = async () => {
    try {
      const data = await AsyncStorage.getItem("cart");
      if (data) {
        setCart(new Set(JSON.parse(data)));
      }
    } catch (error) {
      console.error("Failed to load cart:", error);
    }
  };

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
        {/* Header */}
        <View className="bg-darkGreen px-6 py-4 flex-row justify-between items-center">
          <View className="flex-row items-center gap-4">
            <IconSymbol name="magnifyingglass" size={20} color="#D4AF37" />
            <Text className="text-primary text-base font-medium">Search</Text>
          </View>
          <Image
            source={require("@/assets/figma-assets/1593-8372.webp")}
            className="w-12 h-12"
            resizeMode="contain"
          />
          <View className="flex-row items-center gap-4">
            <View className="relative">
              <IconSymbol name="heart" size={20} color="#D4AF37" />
              {wishlist.size > 0 && (
                <View className="absolute -top-1 -right-1 bg-primary w-4 h-4 rounded-full items-center justify-center">
                  <Text className="text-darkGreen text-[10px] font-bold">{wishlist.size}</Text>
                </View>
              )}
            </View>
            <View className="relative">
              <IconSymbol name="cart" size={20} color="#D4AF37" />
              {cart.size > 0 && (
                <View className="absolute -top-1 -right-1 bg-primary w-4 h-4 rounded-full items-center justify-center">
                  <Text className="text-darkGreen text-[10px] font-bold">{cart.size}</Text>
                </View>
              )}
            </View>
          </View>
        </View>

        {/* Hero Section */}
        <ImageBackground
          source={require("@/assets/figma-assets/1586-4213.webp")}
          className="h-[400px] justify-center"
          resizeMode="cover"
        >
          <LinearGradient colors={["rgba(0,0,0,0.5)", "transparent", "rgba(0,0,0,0.6)"]} className="h-full justify-center px-6">
            <View className="gap-6 max-w-[320px]">
              <Text className="text-white text-5xl font-bold" style={{ fontFamily: "Cormorant_Garamond" }}>
                Experience the Brilliance of Gold
              </Text>
              <Text className="text-white text-base font-medium">
                Discover timeless elegance in every piece. Crafted with precision, designed for eternity.
              </Text>
            </View>
          </LinearGradient>
        </ImageBackground>

        {/* Products Section */}
        <View className="bg-background px-6 py-8">
          {/* Section Title */}
          <View className="flex-row justify-between items-center mb-6">
            <Text className="text-foreground text-2xl font-bold" style={{ fontFamily: "Cormorant_Garamond" }}>
              وصل حديثا
            </Text>
            <Pressable>
              <Text className="text-primary text-base font-semibold">View all →</Text>
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
                All
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
                  {category.title}
                </Text>
              </Pressable>
            ))}
          </ScrollView>

          {/* Products Grid */}
          {filteredProducts.length === 0 ? (
            <View className="items-center justify-center py-12">
              <Text className="text-muted text-lg">No products found</Text>
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

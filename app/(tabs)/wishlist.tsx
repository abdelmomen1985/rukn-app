import { View, FlatList } from "react-native";
import { Text } from "@/components/ui/text";
import { TitleBar } from "@/components/title-bar";
import LottieView from "lottie-react-native";
import { ScreenContainer } from "@/components/screen-container";
import { ProductCard } from "@/components/product-card";
import { products } from "@/data/products";
import { useState, useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useI18n } from "@/lib/i18n";

export default function WishlistScreen() {
  const { t, isRTL } = useI18n();
  const [wishlist, setWishlist] = useState<Set<string>>(new Set());
  const [cart, setCart] = useState<Set<string>>(new Set());

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
    const newCart = new Set(cart);
    newCart.add(id);
    setCart(newCart);
    try {
      await AsyncStorage.setItem("cart", JSON.stringify(Array.from(newCart)));
    } catch (error) {
      console.error("Failed to save cart:", error);
    }
  };

  const wishlistProducts = products.filter((p) => wishlist.has(p.id));

  return (
    <ScreenContainer className="bg-background">
      <TitleBar />
      <View className="flex-1 px-6 py-6">
        {wishlistProducts.length === 0 ? (
          <View className="flex-1 items-center justify-center gap-4">
            <LottieView
              source={require("@/assets/animations/wishlist-empty-2.json")}
              autoPlay
              loop
              style={{ width: 280, height: 280 }}
            />
            <Text className="text-muted text-lg text-center">{t("wishlistEmpty")}</Text>
            <Text className="text-muted text-sm text-center">
              {t("wishlistEmptySubtitle")}
            </Text>
          </View>
        ) : (
          <FlatList
            data={wishlistProducts}
            numColumns={2}
            columnWrapperStyle={{ gap: 16 }}
            contentContainerStyle={{ gap: 16 }}
            showsVerticalScrollIndicator={false}
            renderItem={({ item }) => (
              <ProductCard
                id={item.id}
                name={item.name}
                price={item.price}
                image={item.image}
                initialWishlisted={true}
                onWishlistToggle={handleWishlistToggle}
                onAddToCart={handleAddToCart}
              />
            )}
            keyExtractor={(item) => item.id}
          />
        )}
      </View>
    </ScreenContainer>
  );
}

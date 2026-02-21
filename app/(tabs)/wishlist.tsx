import { View, Text, FlatList } from "react-native";
import { ScreenContainer } from "@/components/screen-container";
import { ProductCard } from "@/components/product-card";
import { products } from "@/data/products";
import { useState, useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";

export default function WishlistScreen() {
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
      <View className="flex-1 px-6 py-6">
        <Text className="text-foreground text-4xl font-bold mb-6" style={{ fontFamily: "Cormorant_Garamond" }}>
          My Wishlist
        </Text>
        {wishlistProducts.length === 0 ? (
          <View className="flex-1 items-center justify-center gap-4">
            <Text className="text-muted text-lg text-center">Your wishlist is empty</Text>
            <Text className="text-muted text-sm text-center">
              Start adding items you love to your wishlist
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

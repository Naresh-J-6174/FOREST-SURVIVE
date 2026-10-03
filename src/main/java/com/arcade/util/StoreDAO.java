package com.arcade.util;

import com.arcade.model.Product;
import java.util.*;

public class StoreDAO {
    public static List<Product> getProducts() { return DBUtil.store().getProducts(); }

    public static Product getProduct(int id) {
        for (Product p : getProducts()) if (p.id == id) return p;
        return null;
    }

    // Biomass points = total of all game scores - total spent in orders
    public static int getBalance(int uid) {
        return DBUtil.store().getTotalScore(uid) - DBUtil.store().getTotalSpent(uid);
    }

    // product id -> product code for everything this user already bought
    public static Map<Integer, String> getOwned(int uid) {
        Set<Integer> ids = DBUtil.store().getOwnedProductIds(uid);
        Map<Integer, String> m = new LinkedHashMap<Integer, String>();
        for (Product p : getProducts()) if (ids.contains(p.id)) m.put(p.id, p.code);
        return m;
    }

    public static void createOrder(int uid, int total, List<Integer> ids) {
        DBUtil.store().createOrder(uid, total, ids);
    }
}

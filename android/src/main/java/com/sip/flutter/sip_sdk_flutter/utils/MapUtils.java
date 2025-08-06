package com.sip.flutter.sip_sdk_flutter.utils;

import java.util.List;
import java.util.Map;

@SuppressWarnings("unchecked")
public class MapUtils {

    public static <T> T get(Map<String, Object> map, String key, T defaultValue) {
        if (map == null) return defaultValue;
        Object value = map.get(key);
        if (value == null) return defaultValue;

        try {
            if (defaultValue == null) {
                // 如果默认值是 null，直接返回强转（不安全，慎用）
                return (T) value;
            }
            if (defaultValue instanceof Integer) {
                if (value instanceof Number) {
                    return (T) Integer.valueOf(((Number) value).intValue());
                }
                return (T) Integer.valueOf(Integer.parseInt(value.toString()));
            } else if (defaultValue instanceof Short) {
                if (value instanceof Number) {
                    return (T) Short.valueOf(((Number) value).shortValue());
                }
                return (T) Short.valueOf(Short.parseShort(value.toString()));
            } else if (defaultValue instanceof Long) {
                if (value instanceof Number) {
                    return (T) Long.valueOf(((Number) value).longValue());
                }
                return (T) Long.valueOf(Long.parseLong(value.toString()));
            } else if (defaultValue instanceof Float) {
                if (value instanceof Number) {
                    return (T) Float.valueOf(((Number) value).floatValue());
                }
                return (T) Float.valueOf(Float.parseFloat(value.toString()));
            } else if (defaultValue instanceof Double) {
                if (value instanceof Number) {
                    return (T) Double.valueOf(((Number) value).doubleValue());
                }
                return (T) Double.valueOf(Double.parseDouble(value.toString()));
            } else if (defaultValue instanceof Boolean) {
                if (value instanceof Boolean) {
                    return (T) value;
                }
                return (T) Boolean.valueOf(value.toString());
            } else if (defaultValue instanceof String) {
                return (T) value.toString();
            } else if (defaultValue instanceof List) {
                if (value instanceof List) {
                    return (T) value;
                }
                return defaultValue;
            } else if (defaultValue instanceof Map) {
                if (value instanceof Map) {
                    return (T) value;
                }
                return defaultValue;
            } else {
                // 其他类型，直接强转（不安全）
                return (T) value;
            }
        } catch (Exception e) {
            // 解析失败，返回默认值
            return defaultValue;
        }
    }

    public static Map<String, Object> getMap(Map<String, Object> map, String key) {
        if (map == null) return null;
        Object value = map.get(key);
        if (value instanceof Map) {
            return (Map<String, Object>) value;
        }
        return null;
    }
}

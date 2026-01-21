import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TemperatureUnit { celsius, fahrenheit }

TemperatureUnit temperatureUnitFromStorage(String? value) {
  if (value == TemperatureUnit.fahrenheit.storageValue) {
    return TemperatureUnit.fahrenheit;
  }
  return TemperatureUnit.celsius;
}

extension TemperatureUnitLabel on TemperatureUnit {
  String get label {
    switch (this) {
      case TemperatureUnit.celsius:
        return 'Celsius';
      case TemperatureUnit.fahrenheit:
        return 'Fahrenheit';
    }
  }

  String get symbol {
    switch (this) {
      case TemperatureUnit.celsius:
        return '°C';
      case TemperatureUnit.fahrenheit:
        return '°F';
    }
  }

  String get storageValue {
    switch (this) {
      case TemperatureUnit.celsius:
        return 'celsius';
      case TemperatureUnit.fahrenheit:
        return 'fahrenheit';
    }
  }
}

class AppSettings {
  static const _keyTempUnit = 'settings_temperature_unit';
  static const _keyWateringReminders = 'settings_notify_watering_reminders';
  static const _keyDailySummary = 'settings_notify_daily_summary';
  static const _keyNotificationPrompted = 'settings_notify_prompted';
  static const _keyWeatherPrompted = 'settings_weather_prompted';
  static const _keyLastNotificationSchedule = 'debug_last_notification_schedule';
  static const _keyLastNotificationTest = 'debug_last_notification_test';
  static final temperatureUnitNotifier =
      ValueNotifier<TemperatureUnit>(TemperatureUnit.celsius);

  static Future<void> syncTemperatureUnit() async {
    temperatureUnitNotifier.value = await getTemperatureUnit();
  }

  static Future<TemperatureUnit> getTemperatureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyTempUnit);
    return temperatureUnitFromStorage(value);
  }

  static Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTempUnit, unit.storageValue);
    temperatureUnitNotifier.value = unit;
  }

  static Future<bool> getWateringRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWateringReminders) ?? true;
  }

  static Future<void> setWateringRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWateringReminders, enabled);
  }

  static Future<bool> getDailySummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailySummary) ?? false;
  }

  static Future<void> setDailySummaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailySummary, enabled);
  }

  static Future<bool> getNotificationPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationPrompted) ?? false;
  }

  static Future<void> setNotificationPrompted(bool prompted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationPrompted, prompted);
  }

  static Future<bool> getWeatherPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWeatherPrompted) ?? false;
  }

  static Future<void> setWeatherPrompted(bool prompted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeatherPrompted, prompted);
  }

  static Future<void> setLastNotificationSchedule(DateTime? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.remove(_keyLastNotificationSchedule);
      return;
    }
    await prefs.setString(_keyLastNotificationSchedule, time.toIso8601String());
  }

  static Future<DateTime?> getLastNotificationSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyLastNotificationSchedule);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static Future<void> setLastNotificationTest(DateTime? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.remove(_keyLastNotificationTest);
      return;
    }
    await prefs.setString(_keyLastNotificationTest, time.toIso8601String());
  }

  static Future<DateTime?> getLastNotificationTest() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyLastNotificationTest);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

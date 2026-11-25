import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/firebase_employee_service.dart';
import '../models/daily_scorecard_model.dart';
import '../models/monthly_scorecard_model.dart';

/// Stores daily scorecards in Firestore (daily_scorecards/{yyyy-mm-dd}) with a
/// local copy, and rolls published days up into the monthly scorecard.
class DailyScorecardService {
  DailyScorecardService._();

  static const collection = 'daily_scorecards';
  static String _key(String id) => 'daily_scorecard_$id';

  static Future<DailyScorecardModel> load(DateTime date) async {
    final id = DailyScorecardModel.idFor(date);
    if (FirebaseEmployeeService.isFirebaseAvailable) {
      try {
        final doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
        if (doc.exists && doc.data() != null) {
          final m = DailyScorecardModel.fromJson(doc.data()!);
          await _cache(m);
          return m;
        }
      } catch (e) {
        debugPrint('Load daily scorecard: $e');
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(id));
      if (raw != null) return DailyScorecardModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
    return DailyScorecardModel.blank(date);
  }

  static Future<void> _cache(DailyScorecardModel m) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(m.id), jsonEncode(m.toJson()));
    } catch (_) {}
  }

  /// Saves a draft or the published scorecard. Returns false if it could
  /// only be saved on this phone.
  static Future<bool> save(DailyScorecardModel m) async {
    await _cache(m);
    if (!FirebaseEmployeeService.isFirebaseAvailable) return false;
    try {
      await FirebaseFirestore.instance.collection(collection).doc(m.id).set(m.toJson());
      return true;
    } catch (e) {
      debugPrint('Save daily scorecard: $e');
      return false;
    }
  }

  /// Published days of a month (drafts never count).
  static Future<List<DailyScorecardModel>> publishedForMonth(int year, int month) async {
    final days = <String, DailyScorecardModel>{};
    if (FirebaseEmployeeService.isFirebaseAvailable) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection(collection)
            .where('year', isEqualTo: year)
            .where('month', isEqualTo: month)
            .get();
        for (final d in snap.docs) {
          final m = DailyScorecardModel.fromJson(d.data());
          if (m.isPublished) days[m.id] = m;
        }
      } catch (e) {
        debugPrint('Load month of daily scorecards: $e');
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith('daily_scorecard_$year-${month.toString().padLeft(2, '0')}'))) {
        final m = DailyScorecardModel.fromJson(jsonDecode(prefs.getString(k)!) as Map<String, dynamic>);
        if (m.isPublished) days.putIfAbsent(m.id, () => m);
      }
    } catch (_) {}
    final list = days.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Fills the monthly scorecard's channel numbers from the published days.
  /// Actual = sum of done; target = sum of daily targets.
  static void applyToMonthly(MonthlyScorecardModel mo, List<DailyScorecardModel> days) {
    int done(String c, String i) => days.fold(0, (s, d) => s + (d.item(c, i)?.done ?? 0));
    int target(String c, String i) => days.fold(0, (s, d) => s + (d.item(c, i)?.target ?? 0));

    mo.instaContentReelActual = done('instagram', 'contentReel');
    mo.instaContentReelTarget = target('instagram', 'contentReel');
    mo.instaProductReelActual = done('instagram', 'productReel');
    mo.instaProductReelTarget = target('instagram', 'productReel');
    mo.instaStoriesActual = done('instagram', 'stories');
    mo.instaStoriesTarget = target('instagram', 'stories');
    mo.instaCarouselActual = done('instagram', 'carousel');
    mo.instaCarouselTarget = target('instagram', 'carousel');
    mo.instaCampaignActual = done('instagram', 'campaign');
    mo.instaCampaignTarget = target('instagram', 'campaign');

    mo.webMnListingActual = done('listing', 'website');
    mo.webMnListingTarget = target('listing', 'website');
    mo.appMnListingActual = done('listing', 'app');
    mo.appMnListingTarget = target('listing', 'app');
    mo.googleListingActual = done('listing', 'google');
    mo.googleListingTarget = target('listing', 'google');

    mo.waStoriesActual = done('whatsapp', 'stories');
    mo.waStoriesTarget = target('whatsapp', 'stories');
    mo.waChannelsActual = done('whatsapp', 'channels');
    mo.waChannelsTarget = target('whatsapp', 'channels');
    mo.waCampaignActual = done('whatsapp', 'campaign');
    mo.waCampaignTarget = target('whatsapp', 'campaign');

    mo.appCampaignActual = done('mobileApp', 'campaign');
    mo.appCampaignTarget = target('mobileApp', 'campaign');
    mo.appNotificationActual = done('mobileApp', 'notification');
    mo.appNotificationTarget = target('mobileApp', 'notification');

    mo.googleBlogsActual = done('google', 'blog');
    mo.googleBlogsTarget = target('google', 'blog');
    mo.googleCampaignActual = done('google', 'campaign');
    mo.googleCampaignTarget = target('google', 'campaign');

    mo.osmSnapchatActual = done('otherSocial', 'snapchat');
    mo.osmSnapchatTarget = target('otherSocial', 'snapchat');
    mo.osmPinterestActual = done('otherSocial', 'pinterest');
    mo.osmPinterestTarget = target('otherSocial', 'pinterest');
    mo.osmShortsActual = done('otherSocial', 'shorts');
    mo.osmShortsTarget = target('otherSocial', 'shorts');
    mo.osmLinkedinActual = done('otherSocial', 'linkedin');
    mo.osmLinkedinTarget = target('otherSocial', 'linkedin');
    mo.osmXPostActual = done('otherSocial', 'xpost');
    mo.osmXPostTarget = target('otherSocial', 'xpost');

    if (days.isNotEmpty) {
      mo.designResponse = days.fold(0, (s, d) => s + d.feedbackResponses);
      mo.designFeedbackRating = (days.fold(0, (s, d) => s + d.feedbackRating) / days.length).round();
    }
  }
}

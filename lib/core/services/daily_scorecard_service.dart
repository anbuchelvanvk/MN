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

  /// Fills the monthly scorecard's channel numbers from the published days,
  /// one day at a time: actual = sum of each day's "done", target = sum of
  /// each day's target. A target the team lead typed in for the month (see
  /// [MonthlyScorecardModel.targetOverrides]) is kept as typed. With no
  /// published day yet, the stored monthly numbers are left as they are.
  static void applyToMonthly(MonthlyScorecardModel mo, List<DailyScorecardModel> days) {
    if (days.isEmpty) return;
    int done(String c, String i) => days.fold(0, (s, d) => s + (d.item(c, i)?.done ?? 0));
    int target(String c, String i) => days.fold(0, (s, d) => s + (d.item(c, i)?.target ?? 0));
    final keep = mo.targetOverrides;

    void sync(String field, String c, String i, void Function(int) setActual, void Function(int) setTarget) {
      setActual(done(c, i));
      if (!keep.contains('${field}Target')) setTarget(target(c, i));
    }

    sync('instaContentReel', 'instagram', 'contentReel', (v) => mo.instaContentReelActual = v, (v) => mo.instaContentReelTarget = v);
    sync('instaProductReel', 'instagram', 'productReel', (v) => mo.instaProductReelActual = v, (v) => mo.instaProductReelTarget = v);
    sync('instaStories', 'instagram', 'stories', (v) => mo.instaStoriesActual = v, (v) => mo.instaStoriesTarget = v);
    sync('instaCarousel', 'instagram', 'carousel', (v) => mo.instaCarouselActual = v, (v) => mo.instaCarouselTarget = v);
    sync('instaCampaign', 'instagram', 'campaign', (v) => mo.instaCampaignActual = v, (v) => mo.instaCampaignTarget = v);

    sync('webMnListing', 'listing', 'website', (v) => mo.webMnListingActual = v, (v) => mo.webMnListingTarget = v);
    sync('appMnListing', 'listing', 'app', (v) => mo.appMnListingActual = v, (v) => mo.appMnListingTarget = v);
    sync('googleListing', 'listing', 'google', (v) => mo.googleListingActual = v, (v) => mo.googleListingTarget = v);

    sync('waStories', 'whatsapp', 'stories', (v) => mo.waStoriesActual = v, (v) => mo.waStoriesTarget = v);
    sync('waChannels', 'whatsapp', 'channels', (v) => mo.waChannelsActual = v, (v) => mo.waChannelsTarget = v);
    sync('waCampaign', 'whatsapp', 'campaign', (v) => mo.waCampaignActual = v, (v) => mo.waCampaignTarget = v);

    sync('appCampaign', 'mobileApp', 'campaign', (v) => mo.appCampaignActual = v, (v) => mo.appCampaignTarget = v);
    sync('appNotification', 'mobileApp', 'notification', (v) => mo.appNotificationActual = v, (v) => mo.appNotificationTarget = v);

    sync('googleBlogs', 'google', 'blog', (v) => mo.googleBlogsActual = v, (v) => mo.googleBlogsTarget = v);
    sync('googleCampaign', 'google', 'campaign', (v) => mo.googleCampaignActual = v, (v) => mo.googleCampaignTarget = v);

    sync('osmSnapchat', 'otherSocial', 'snapchat', (v) => mo.osmSnapchatActual = v, (v) => mo.osmSnapchatTarget = v);
    sync('osmPinterest', 'otherSocial', 'pinterest', (v) => mo.osmPinterestActual = v, (v) => mo.osmPinterestTarget = v);
    sync('osmShorts', 'otherSocial', 'shorts', (v) => mo.osmShortsActual = v, (v) => mo.osmShortsTarget = v);
    sync('osmLinkedin', 'otherSocial', 'linkedin', (v) => mo.osmLinkedinActual = v, (v) => mo.osmLinkedinTarget = v);
    sync('osmXPost', 'otherSocial', 'xpost', (v) => mo.osmXPostActual = v, (v) => mo.osmXPostTarget = v);

    mo.designResponse = days.fold(0, (s, d) => s + d.feedbackResponses);
    mo.designFeedbackRating = (days.fold(0, (s, d) => s + d.feedbackRating) / days.length).round();
  }
}

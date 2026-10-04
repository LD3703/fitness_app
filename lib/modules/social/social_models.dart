// Datové třídy sociálních funkcí (obraz dokumentů ve Firestore).
// Popis modelu: docs/social.md.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Timestamp / DateTime / null → DateTime?.
DateTime? readDate(Object? v) => switch (v) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ => null,
    };

double? readDouble(Object? v) => v is num ? v.toDouble() : null;

int? readInt(Object? v) => v is num ? v.toInt() : null;

String? readString(Object? v) => v is String ? v : null;

Map<String, Object?> readMap(Object? v) =>
    v is Map ? {for (final e in v.entries) '${e.key}': e.value} : const {};

/// Veřejný profil (dokument users/{uid}) – vidí ho jen přátelé.
class FriendProfile {
  FriendProfile({
    required this.uid,
    required this.displayName,
    this.friendCode,
    this.shareRecords = false,
    this.shareStats = false,
    this.workoutsThisMonth,
    this.statsMonth,
    this.weeklyVolume,
    this.statsWeek,
    this.weeks = const {},
  });

  factory FriendProfile.fromMap(String uid, Map<String, Object?> m) {
    final weeks = readMap(m['weeks']);
    return FriendProfile(
      uid: uid,
      displayName: readString(m['displayName']) ?? '?',
      friendCode: readString(m['friendCode']),
      shareRecords: m['shareRecords'] == true,
      shareStats: m['shareStats'] == true,
      workoutsThisMonth: readInt(m['workoutsThisMonth']),
      statsMonth: readString(m['statsMonth']),
      weeklyVolume: readDouble(m['weeklyVolume']),
      statsWeek: readString(m['statsWeek']),
      weeks: {
        for (final e in weeks.entries)
          if (e.value is bool) e.key: e.value! as bool,
      },
    );
  }

  final String uid;
  final String displayName;

  /// Jen u vlastního profilu (přátelé ho sice mohou číst, ale nepotřebují).
  final String? friendCode;
  final bool shareRecords;
  final bool shareStats;
  final int? workoutsThisMonth;
  final String? statsMonth;
  final double? weeklyVolume;
  final String? statsWeek;

  /// ISO týden → splnil plán.
  final Map<String, bool> weeks;

  /// Počet tréninků v měsíci [month] (starší údaj se nepočítá).
  int? workoutsIn(String month) =>
      statsMonth == month ? workoutsThisMonth : null;

  /// Objem v týdnu [week] (starší údaj se nepočítá).
  double? volumeIn(String week) => statsWeek == week ? weeklyVolume : null;
}

/// Vazba na přítele (users/{uid}/friends/{friendUid}).
class FriendLink {
  FriendLink({required this.uid, this.since});

  final String uid;
  final DateTime? since;
}

/// Druhy položek v novinkách.
abstract final class FeedType {
  static const friend = 'friend';
  static const pr = 'pr';
  static const invite = 'invite';
  static const inviteReply = 'inviteReply';
  static const challenge = 'challenge';
  static const challengeDone = 'challengeDone';

  /// Někdo mě v posilovně předběhl na 1. místě (zapisuje jen Cloud Function).
  static const gymOvertaken = 'gymOvertaken';

  static const all = [
    friend,
    pr,
    invite,
    inviteReply,
    challenge,
    challengeDone,
    gymOvertaken,
  ];
}

/// Položka novinek (users/{uid}/feed/{id}) – zapisuje ji přítel.
class FeedItem {
  FeedItem({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.fromName,
    required this.createdAt,
    required this.data,
    this.read = false,
    this.status,
    this.handled = false,
  });

  factory FeedItem.fromMap(String id, Map<String, Object?> m) => FeedItem(
        id: id,
        type: readString(m['type']) ?? '',
        fromUid: readString(m['fromUid']) ?? '',
        fromName: readString(m['fromName']) ?? '?',
        createdAt: readDate(m['createdAt']) ?? DateTime.now(),
        data: readMap(m['data']),
        read: m['read'] == true,
        status: readString(m['status']),
        handled: m['handled'] == true,
      );

  final String id;
  final String type;
  final String fromUid;
  final String fromName;
  final DateTime createdAt;
  final Map<String, Object?> data;
  final bool read;

  /// U pozvánek a výzev: null (čeká) / accepted / declined.
  final String? status;

  /// Aplikace už položku zpracovala (např. zapsala trénink do kalendáře).
  final bool handled;

  String? str(String key) => readString(data[key]);
  double? number(String key) => readDouble(data[key]);
  DateTime? date(String key) => readDate(data[key]);
}

/// Stavy pozvánky.
abstract final class InviteStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const declined = 'declined';
  static const cancelled = 'cancelled';
}

/// Pozvánka na společný trénink (invitations/{id}).
class Invitation {
  Invitation({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.planName,
    required this.startAt,
    required this.durationMinutes,
    required this.status,
  });

  factory Invitation.fromMap(String id, Map<String, Object?> m) => Invitation(
        id: id,
        fromUid: readString(m['fromUid']) ?? '',
        fromName: readString(m['fromName']) ?? '?',
        toUid: readString(m['toUid']) ?? '',
        planName: readString(m['planName']) ?? '',
        startAt: readDate(m['startAt']) ?? DateTime.now(),
        durationMinutes: readInt(m['durationMinutes']) ?? 60,
        status: readString(m['status']) ?? InviteStatus.pending,
      );

  final String id;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String planName;
  final DateTime startAt;
  final int durationMinutes;
  final String status;
}

/// Druhy výzev na serveru (odpovídají ChallengeKind v aplikaci).
abstract final class RemoteChallengeKind {
  static const beatRecord = 'beatRecord';
  static const workoutsInMonth = 'workoutsInMonth';
  static const weeklyWater = 'weeklyWater';
}

/// Výzva mezi dvěma přáteli (challenges/{id}).
class RemoteChallenge {
  RemoteChallenge({
    required this.id,
    required this.creatorUid,
    required this.creatorName,
    required this.members,
    required this.kind,
    required this.target,
    required this.deadline,
    required this.createdAt,
    this.exerciseSlug,
    this.exerciseName,
    this.accepted = const {},
    this.declined = const {},
    this.completed = const {},
    this.progress = const {},
  });

  factory RemoteChallenge.fromMap(String id, Map<String, Object?> m) {
    final members = m['members'];
    return RemoteChallenge(
      id: id,
      creatorUid: readString(m['creatorUid']) ?? '',
      creatorName: readString(m['creatorName']) ?? '?',
      members: members is List ? [for (final x in members) '$x'] : const [],
      kind: readString(m['kind']) ?? '',
      target: readDouble(m['target']) ?? 0,
      deadline: readDate(m['deadline']) ?? DateTime.now(),
      createdAt: readDate(m['createdAt']) ?? DateTime.now(),
      exerciseSlug: readString(m['exerciseSlug']),
      exerciseName: readString(m['exerciseName']),
      accepted: {
        for (final e in readMap(m['accepted']).entries)
          if (e.value == true) e.key,
      },
      declined: {
        for (final e in readMap(m['declined']).entries)
          if (e.value == true) e.key,
      },
      completed: {
        for (final e in readMap(m['completed']).entries)
          if (readDate(e.value) case final d?) e.key: d,
      },
      progress: {
        for (final e in readMap(m['progress']).entries)
          if (readDouble(e.value) case final v?) e.key: v,
      },
    );
  }

  final String id;
  final String creatorUid;
  final String creatorName;
  final List<String> members;
  final String kind;

  /// beatRecord: kg (odhad 1RM), workoutsInMonth: počet,
  /// weeklyWater: 100 (%) – množství vody se nikdy neposílá.
  final double target;
  final DateTime deadline;
  final DateTime createdAt;
  final String? exerciseSlug;
  final String? exerciseName;
  final Set<String> accepted;
  final Set<String> declined;
  final Map<String, DateTime> completed;

  /// workoutsInMonth: počet tréninků, weeklyWater: % splnění.
  final Map<String, double> progress;

  String otherMember(String me) =>
      members.firstWhere((m) => m != me, orElse: () => creatorUid);
}

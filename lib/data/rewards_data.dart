import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// Every badge, cosmetic unlock and Jannah Garden plant, in one place.
// Rewards are earned only by doing: nothing is bought, and no religious
// content is ever locked behind them. Challenges use these now; Games
// (NEXT_UPDATE_PROMPTS section 20) will add their own entries here.
//
// Names avoid real religious ranks (no "Hafiz", "Sheikh", "Mufti", "Wali").

/// Who awards a badge. Challenge badges are given only by the Cloud
/// Function (functions/src/rewards.ts) from Firestore data, so nobody can
/// award themselves one; local badges come from actions on this device
/// (Tasbeeh, Hifz) and also work for guests.
enum RewardSource { server, local }

class BadgeDef {
  final String id;
  final IconData icon;
  final RewardSource source;

  const BadgeDef(this.id, this.icon, this.source);
}

const badges = <BadgeDef>[
  BadgeDef('first_challenge', Iconsax.flag, RewardSource.server),
  BadgeDef('khatam_finisher', Iconsax.book_1, RewardSource.server),
  BadgeDef('steadfast', Iconsax.calendar_tick, RewardSource.server),
  BadgeDef('early_bird', Iconsax.sun_1, RewardSource.server),
  BadgeDef('encourager', Iconsax.heart, RewardSource.server),
  BadgeDef('family_builder', Iconsax.people, RewardSource.server),
  BadgeDef('comeback', Iconsax.refresh_circle, RewardSource.server),
  BadgeDef('first_surah', Iconsax.book_saved, RewardSource.local),
  BadgeDef('dhikr_1000', Iconsax.activity, RewardSource.local),
  BadgeDef('dhikr_10000', Iconsax.star_1, RewardSource.local),
];

BadgeDef? badgeById(String id) => badges.where((b) => b.id == id).firstOrNull;

/// Thresholds the server and the device use (kept in step with
/// functions/src/rewards.ts).
class RewardRules {
  RewardRules._();

  static const encouragerReactions = 50;
  static const familyBuilderJoins = 5;
  static const dhikrPerPalm = 1000;
  static const dhikrBadges = {'dhikr_1000': 1000, 'dhikr_10000': 10000};

  /// The garden shows at most this many palms (one per 1,000 dhikr); the
  /// rest are counted in a label, so the garden stays calm.
  static const maxPalmsShown = 40;
}

enum CosmeticKind { accent, mushafFrame, bead, avatarFrame }

class CosmeticDef {
  final String id;
  final CosmeticKind kind;

  /// The badge that unlocks it; null for the default, always available.
  final String? unlockedBy;

  const CosmeticDef(this.id, this.kind, [this.unlockedBy]);
}

const cosmetics = <CosmeticDef>[
  CosmeticDef('classic_gold', CosmeticKind.accent),
  CosmeticDef('madinah_green', CosmeticKind.accent, 'first_challenge'),
  CosmeticDef('night_of_qadr', CosmeticKind.accent, 'steadfast'),
  CosmeticDef('desert_gold', CosmeticKind.accent, 'khatam_finisher'),
  CosmeticDef('frame_none', CosmeticKind.mushafFrame),
  CosmeticDef('frame_arch', CosmeticKind.mushafFrame, 'first_surah'),
  CosmeticDef('frame_star', CosmeticKind.mushafFrame, 'early_bird'),
  CosmeticDef('bead_classic', CosmeticKind.bead),
  CosmeticDef('bead_pearl', CosmeticKind.bead, 'dhikr_1000'),
  CosmeticDef('bead_glow', CosmeticKind.bead, 'dhikr_10000'),
  CosmeticDef('avatar_ring', CosmeticKind.avatarFrame),
  CosmeticDef('avatar_crescent', CosmeticKind.avatarFrame, 'encourager'),
  CosmeticDef('avatar_star', CosmeticKind.avatarFrame, 'family_builder'),
  CosmeticDef('avatar_garden', CosmeticKind.avatarFrame, 'comeback'),
];

CosmeticDef? cosmeticById(String id) => cosmetics.where((c) => c.id == id).firstOrNull;

/// Accent colours (light, dark) for the app-wide accent themes.
const accentColors = <String, (Color, Color)>{
  'classic_gold': (Color(0xFFCB9B3F), Color(0xFFE8C165)),
  'madinah_green': (Color(0xFF2F7D5A), Color(0xFF74C79A)),
  'night_of_qadr': (Color(0xFF5A4E9E), Color(0xFFB4A8EE)),
  'desert_gold': (Color(0xFFB4672A), Color(0xFFEDA66A)),
};

/// What a Jannah Garden plant stands for.
enum GardenKind {
  /// A completed challenge.
  tree,

  /// A finished Khatam challenge.
  fountain,

  /// A surah memorised in Hifz mode.
  flower,

  /// Every 1,000 dhikr in Tasbeeh (see [gardenHadith]).
  palm,
}

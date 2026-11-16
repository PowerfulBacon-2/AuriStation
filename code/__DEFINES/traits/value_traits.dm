/// Trait that stores the skin colour of a bodypart. Must be applied to a bodypart and not the mob as a whole.
#define TRAIT_OVERRIDE_SKIN_COLOUR "skin_colour"

/// Holds a sound environment, when set then the highest priority soundscape will be assigned to the user
#define TRAIT_VALUE_SOUND_SCAPE "sound_scape"

/// Stores typepaths, the typepath value read from this trait indicates that this item
/// is meant to look like the item with that path, which might affect how you show
/// this item to players (such as through armour readouts).
#define TRAIT_VALUE_MIMIC_PATH "mimic_path"

/// Clothing multiplicative/additive trait which modifies the amount of suppression received when firing
/// a weapon.
#define TRAIT_VALUE_ARMOR_SUPPRESSION_SELF "self_suppression"

/// Clothing trait which determines the amount of suppression received when a bullet flies past or when
/// someone else fires at you.
#define TRAIT_VALUE_ARMOR_SUPPRESSION_OTHER "other_suppression"

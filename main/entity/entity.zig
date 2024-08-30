pub const Entity = union(enum(i32)) {
    pub const ItemFrame = @import("impl/decoration/ItemFrame.zig");
    pub const LeadKnot = @import("impl/decoration/LeadKnot.zig");
    pub const Painting = @import("impl/decoration/Painting.zig");

    pub const EnderDragon = @import("impl/living/boss/EnderDragon.zig");
    pub const Wither = @import("impl/living/boss/Wither.zig");

    pub const Blaze = @import("impl/living/hostile/Blaze.zig");
    pub const CaveSpider = @import("impl/living/hostile/CaveSpider.zig");
    pub const Creeper = @import("impl/living/hostile/Creeper.zig");
    pub const Endermite = @import("impl/living/hostile/Endermite.zig");
    pub const Giant = @import("impl/living/hostile/Giant.zig");
    pub const Guardian = @import("impl/living/hostile/Guardian.zig");
    pub const Silverfish = @import("impl/living/hostile/Silverfish.zig");
    pub const Skeleton = @import("impl/living/hostile/Skeleton.zig");
    pub const Spider = @import("impl/living/hostile/Spider.zig");
    pub const Witch = @import("impl/living/hostile/Witch.zig");
    pub const Zombie = @import("impl/living/hostile/Zombie.zig");

    pub const Enderman = @import("impl/living/neutral/Enderman.zig");
    pub const IronGolem = @import("impl/living/neutral/IronGolem.zig");
    pub const ZombiePigman = @import("impl/living/neutral/ZombiePigman.zig");

    pub const Chicken = @import("impl/living/passive/Chicken.zig");
    pub const Cow = @import("impl/living/passive/Cow.zig");
    pub const Equine = @import("impl/living/passive/Equine.zig");
    pub const Mooshroom = @import("impl/living/passive/Mooshroom.zig");
    pub const Ocelot = @import("impl/living/passive/Ocelot.zig");
    pub const Pig = @import("impl/living/passive/Pig.zig");
    pub const Rabbit = @import("impl/living/passive/Rabbit.zig");
    pub const Sheep = @import("impl/living/passive/Sheep.zig");
    pub const SnowGolem = @import("impl/living/passive/SnowGolem.zig");
    pub const Villager = @import("impl/living/passive/Villager.zig");
    pub const Wolf = @import("impl/living/passive/Wolf.zig");

    pub const ArmorStand = @import("impl/misc/ArmorStand.zig");
    pub const EnderCrystal = @import("impl/misc/EnderCrystal.zig");
    pub const EnderEye = @import("impl/misc/EnderEye.zig");
    pub const FallingBlock = @import("impl/misc/FallingBlock.zig");
    pub const Fireworks = @import("impl/misc/Fireworks.zig");
    pub const FishingBobber = @import("impl/misc/FishingBobber.zig");
    pub const Item = @import("impl/misc/Item.zig");
    pub const PrimedTnt = @import("impl/misc/PrimedTnt.zig");
    pub const XpOrb = @import("impl/misc/XpOrb.zig");

    pub const LocalPlayer = @import("impl/player/LocalPlayer.zig");
    pub const RemotePlayer = @import("impl/player/RemotePlayer.zig");

    pub const Arrow = @import("impl/projectile/Arrow.zig");
    pub const Egg = @import("impl/projectile/Egg.zig");
    pub const EnderPearl = @import("impl/projectile/EnderPearl.zig");
    pub const ExperienceBottle = @import("impl/projectile/ExperienceBottle.zig");
    pub const Fireball = @import("impl/projectile/Fireball.zig");
    pub const Potion = @import("impl/projectile/Potion.zig");
    pub const SmallFireball = @import("impl/projectile/SmallFireball.zig");
    pub const Snowball = @import("impl/projectile/Snowball.zig");
    pub const WitherSkull = @import("impl/projectile/WitherSkull.zig");

    pub const Boat = @import("impl/vehicle/Boat.zig");
    pub const Minecart = @import("impl/vehicle/Minecart.zig");

    pub const Lightning = @import("impl/weather/Lightning.zig");

    pub const Base = @import("impl/Base.zig");
    pub const LivingBase = @import("impl/living/LivingBase.zig");
    pub const PlayerBase = @import("impl/player/PlayerBase.zig");
    pub const DecorationBase = @import("impl/decoration/DecorationBase.zig");
    pub const InterpolatedBase = @import("impl/InterpolatedBase.zig");

    pub const DataTracker = @import("datatracker/DataTracker.zig");

    item_frame: ItemFrame,
    lead_knot: LeadKnot,
    painting: Painting,
    ender_dragon: EnderDragon,
    wither: Wither,
    blaze: Blaze,
    cave_spider: CaveSpider,
    creeper: Creeper,
    endermite: Endermite,
    giant: Giant,
    guardian: Guardian,
    silverfish: Silverfish,
    skeleton: Skeleton,
    spider: Spider,
    witch: Witch,
    zombie: Zombie,
    enderman: Enderman,
    iron_golem: IronGolem,
    zombie_pigman: ZombiePigman,
    chicken: Chicken,
    cow: Cow,
    equine: Equine,
    mooshroom: Mooshroom,
    ocelot: Ocelot,
    pig: Pig,
    rabbit: Rabbit,
    sheep: Sheep,
    snow_golem: SnowGolem,
    villager: Villager,
    wolf: Wolf,
    armor_stand: ArmorStand,
    ender_crystal: EnderCrystal,
    ender_eye: EnderEye,
    falling_block: FallingBlock,
    fireworks: Fireworks,
    fishing_bobber: FishingBobber,
    item: Item,
    primed_tnt: PrimedTnt,
    xp_orb: XpOrb,
    local_player: LocalPlayer,
    remote_player: RemotePlayer,
    arrow: Arrow,
    egg: Egg,
    ender_pearl: EnderPearl,
    experience_bottle: ExperienceBottle,
    fireball: Fireball,
    potion: Potion,
    small_fireball: SmallFireball,
    snowball: Snowball,
    wither_skull: WitherSkull,
    boat: Boat,
    minecart: Minecart,
    lightning: Lightning,

    pub fn tick(entity: @This()) !void {
        switch (entity) {
            inline else => |specific_entity| {
                specific_entity.tick();
            },
        }
    }
};

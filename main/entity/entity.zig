const std = @import("std");
const root = @import("root");
const Vector3 = root.Vector3;
const Rotation2 = root.Rotation2;

pub const EntityType = enum(i32) {
    item = 1,
    xp_orb = 2,
    egg = 7,
    lead_knot = 8,
    painting = 9,
    arrow = 10,
    snowball = 11,
    fireball = 12,
    small_fireball = 13,
    ender_pearl = 14,
    ender_eye = 15,
    potion = 16,
    experience_bottle = 17,
    item_frame = 18,
    wither_skull = 19,
    primed_tnt = 20,
    falling_block = 21,
    fireworks = 22,
    armor_stand = 30,
    command_block_minecart = 40,
    boat = 41,
    minecart = 42,
    chest_minecart = 43,
    furnace_minecart = 44,
    tnt_minecart = 45,
    hopper_minecart = 46,
    spawner_minecart = 47,
    creeper = 50,
    skeleton = 51,
    spider = 52,
    giant = 53,
    zombie = 54,
    slime = 55,
    ghast = 56,
    zombie_pigman = 57,
    enderman = 58,
    cave_spider = 59,
    silverfish = 60,
    blaze = 61,
    magma_cube = 62,
    ender_dragon = 63,
    wither = 64,
    bat = 65,
    witch = 66,
    endermite = 67,
    guardian = 68,
    pig = 90,
    sheep = 91,
    cow = 92,
    chicken = 93,
    squid = 94,
    wolf = 95,
    mooshroom = 96,
    snow_golem = 97,
    ocelot = 98,
    iron_golem = 99,
    equine = 100,
    rabbit = 101,
    villager = 120,
    ender_crystal = 200,

    fishing_bobber,
    local_player,
    remote_player,
    lightning,

    removed,
};

pub const Entity = union(EntityType) {
    item: Item,
    xp_orb: XpOrb,
    egg: Egg,
    lead_knot: LeadKnot,
    painting: Painting,
    arrow: Arrow,
    snowball: Snowball,
    fireball: Fireball,
    small_fireball: SmallFireball,
    ender_pearl: EnderPearl,
    ender_eye: EnderEye,
    potion: Potion,
    experience_bottle: ExperienceBottle,
    item_frame: ItemFrame,
    wither_skull: WitherSkull,
    primed_tnt: PrimedTnt,
    falling_block: FallingBlock,
    fireworks: Fireworks,
    armor_stand: ArmorStand,
    command_block_minecart: Minecart,
    boat: Boat,
    minecart: Minecart,
    chest_minecart: Minecart,
    furnace_minecart: Minecart,
    tnt_minecart: Minecart,
    hopper_minecart: Minecart,
    spawner_minecart: Minecart,
    creeper: Creeper,
    skeleton: Skeleton,
    spider: Spider,
    giant: Giant,
    zombie: Zombie,
    slime: Slime,
    ghast: Ghast,
    zombie_pigman: ZombiePigman,
    enderman: Enderman,
    cave_spider: CaveSpider,
    silverfish: Silverfish,
    blaze: Blaze,
    magma_cube: MagmaCube,
    ender_dragon: EnderDragon,
    wither: Wither,
    bat: Bat,
    witch: Witch,
    endermite: Endermite,
    guardian: Guardian,
    pig: Pig,
    sheep: Sheep,
    cow: Cow,
    chicken: Chicken,
    squid: Squid,
    wolf: Wolf,
    mooshroom: Mooshroom,
    snow_golem: SnowGolem,
    ocelot: Ocelot,
    iron_golem: IronGolem,
    equine: Equine,
    rabbit: Rabbit,
    villager: Villager,
    ender_crystal: EnderCrystal,

    fishing_bobber: FishingBobber,
    local_player: LocalPlayer,
    remote_player: RemotePlayer,
    lightning: Lightning,

    removed,

    pub fn tick(entity: *@This()) !void {
        switch (entity.*) {
            .removed => return,
            inline else => |*specific_entity| {
                specific_entity.tick();
            },
        }
    }

    pub fn move(self: *@This(), delta: Vector3(f64)) void {
        switch (self.*) {
            .removed => return,
            inline else => |*specific_entity| {
                specific_entity.base.pos = specific_entity.base.pos.add(delta);
                @import("log").entity_move(.{ self, specific_entity.base.pos });
            },
        }
    }

    pub fn rotateTo(self: *@This(), rotation: Rotation2(f32)) void {
        switch (self.*) {
            .removed => return,
            inline else => |*specific_entity| {
                specific_entity.base.rotation = rotation;
                @import("log").entity_rotate(.{ self, specific_entity.base.rotation });
            },
        }
    }

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("type={s} id={}", .{
            @tagName(@as(EntityType, self)),
            switch (self) {
                .removed => 0,
                inline else => |specific_entity| specific_entity.base.network_id,
            },
        });
    }

    pub const ItemFrame = @import("impl/decoration/ItemFrame.zig");
    pub const LeadKnot = @import("impl/decoration/LeadKnot.zig");
    pub const Painting = @import("impl/decoration/Painting.zig");

    pub const EnderDragon = @import("impl/living/boss/EnderDragon.zig");
    pub const Wither = @import("impl/living/boss/Wither.zig");

    pub const Blaze = @import("impl/living/hostile/Blaze.zig");
    pub const CaveSpider = @import("impl/living/hostile/CaveSpider.zig");
    pub const Creeper = @import("impl/living/hostile/Creeper.zig");
    pub const Endermite = @import("impl/living/hostile/Endermite.zig");
    pub const Ghast = @import("impl/living/hostile/Ghast.zig");
    pub const Giant = @import("impl/living/hostile/Giant.zig");
    pub const Guardian = @import("impl/living/hostile/Guardian.zig");
    pub const MagmaCube = @import("impl/living/hostile/MagmaCube.zig");
    pub const Silverfish = @import("impl/living/hostile/Silverfish.zig");
    pub const Skeleton = @import("impl/living/hostile/Skeleton.zig");
    pub const Slime = @import("impl/living/hostile/Slime.zig");
    pub const Spider = @import("impl/living/hostile/Spider.zig");
    pub const Witch = @import("impl/living/hostile/Witch.zig");
    pub const Zombie = @import("impl/living/hostile/Zombie.zig");

    pub const Enderman = @import("impl/living/neutral/Enderman.zig");
    pub const IronGolem = @import("impl/living/neutral/IronGolem.zig");
    pub const ZombiePigman = @import("impl/living/neutral/ZombiePigman.zig");

    pub const Bat = @import("impl/living/passive/Bat.zig");
    pub const Chicken = @import("impl/living/passive/Chicken.zig");
    pub const Cow = @import("impl/living/passive/Cow.zig");
    pub const Equine = @import("impl/living/passive/Equine.zig");
    pub const Mooshroom = @import("impl/living/passive/Mooshroom.zig");
    pub const Ocelot = @import("impl/living/passive/Ocelot.zig");
    pub const Pig = @import("impl/living/passive/Pig.zig");
    pub const Rabbit = @import("impl/living/passive/Rabbit.zig");
    pub const Sheep = @import("impl/living/passive/Sheep.zig");
    pub const SnowGolem = @import("impl/living/passive/SnowGolem.zig");
    pub const Squid = @import("impl/living/passive/Squid.zig");
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
};

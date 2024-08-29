pub const EnderDragonEntity = @import("impl/living/boss/EnderDragonEntity.zig");
pub const WitherEntity = @import("impl/living/boss/WitherEntity.zig");

pub const BlazeEntity = @import("impl/living/hostile/BlazeEntity.zig");
pub const CaveSpiderEntity = @import("impl/living/hostile/CaveSpiderEntity.zig");
pub const CreeperEntity = @import("impl/living/hostile/CreeperEntity.zig");
pub const EndermiteEntity = @import("impl/living/hostile/EndermiteEntity.zig");
pub const GiantEntity = @import("impl/living/hostile/GiantEntity.zig");
pub const GuardianEntity = @import("impl/living/hostile/GuardianEntity.zig");
pub const SilverfishEntity = @import("impl/living/hostile/SilverfishEntity.zig");
pub const SkeletonEntity = @import("impl/living/hostile/SkeletonEntity.zig");
pub const SpiderEntity = @import("impl/living/hostile/SpiderEntity.zig");
pub const WitchEntity = @import("impl/living/hostile/WitchEntity.zig");
pub const ZombieEntity = @import("impl/living/hostile/ZombieEntity.zig");

pub const EndermanEntity = @import("impl/living/neutral/EndermanEntity.zig");
pub const IronGolemEntity = @import("impl/living/neutral/IronGolemEntity.zig");
pub const ZombiePigmanEntity = @import("impl/living/neutral/ZombiePigmanEntity.zig");

pub const ChickenEntity = @import("impl/living/passive/ChickenEntity.zig");
pub const CowEntity = @import("impl/living/passive/CowEntity.zig");
pub const EquineEntity = @import("impl/living/passive/EquineEntity.zig");
pub const MooshroomEntity = @import("impl/living/passive/MooshroomEntity.zig");
pub const OcelotEntity = @import("impl/living/passive/OcelotEntity.zig");
pub const PigEntity = @import("impl/living/passive/PigEntity.zig");
pub const RabbitEntity = @import("impl/living/passive/RabbitEntity.zig");
pub const SheepEntity = @import("impl/living/passive/SheepEntity.zig");
pub const SnowGolemEntity = @import("impl/living/passive/SnowGolemEntity.zig");
pub const VillagerEntity = @import("impl/living/passive/VillagerEntity.zig");
pub const WolfEntity = @import("impl/living/passive/WolfEntity.zig");

pub const ArmorStandEntity = @import("impl/misc/ArmorStandEntity.zig");
pub const EnderCrystalEntity = @import("impl/misc/EnderCrystalEntity.zig");
pub const FallingBlockEntity = @import("impl/misc/FallingBlockEntity.zig");
pub const FireworksEntity = @import("impl/misc/FireworksEntity.zig");
pub const FishingBobberEntity = @import("impl/misc/FishingBobberEntity.zig");
pub const ItemEntity = @import("impl/misc/ItemEntity.zig");
pub const PrimedTntEntity = @import("impl/misc/PrimedTntEntity.zig");
pub const XpOrbEntity = @import("impl/misc/XpOrbEntity.zig");

pub const LocalPlayerEntity = @import("impl/player/LocalPlayerEntity.zig");
pub const RemotePlayerEntity = @import("impl/player/LocalPlayerEntity.zig");

pub const ArrowEntity = @import("impl/projectile/ArrowEntity.zig");
pub const EggEntity = @import("impl/projectile/EggEntity.zig");
pub const EnderPearlEntity = @import("impl/projectile/EnderPearlEntity.zig");
pub const ExperienceBottleEntity = @import("impl/projectile/ExperienceBottleEntity.zig");
pub const FireballEntity = @import("impl/projectile/FireballEntity.zig");
pub const PotionEntity = @import("impl/projectile/PotionEntity.zig");
pub const SmallFireballEntity = @import("impl/projectile/SmallFireballEntity.zig");
pub const SnowballEntity = @import("impl/projectile/SnowballEntity.zig");
pub const WitherSkullEntity = @import("impl/projectile/WitherSkullEntity.zig");

pub const BoatEntity = @import("impl/player/LocalPlayerEntity.zig");
pub const MinecartEntity = @import("impl/player/LocalPlayerEntity.zig");

pub const LightningEntity = @import("impl/weather/LightningEntity.zig");

pub const Datatracker = @import("datatracker/DataTracker.zig");

pub const Entity = union(enum) {
    EnderDragon: EnderDragonEntity,
    Wither: WitherEntity,
    Blaze: BlazeEntity,
    CaveSpider: CaveSpiderEntity,
    Creeper: CreeperEntity,
    Endermite: EndermiteEntity,
    Giant: GiantEntity,
    Guardian: GuardianEntity,
    Silverfish: SilverfishEntity,
    Skeleton: SkeletonEntity,
    Spider: SpiderEntity,
    Witch: WitchEntity,
    Zombie: ZombieEntity,
    Enderman: EndermanEntity,
    IronGolem: IronGolemEntity,
    ZombiePigman: ZombiePigmanEntity,
    Chicken: ChickenEntity,
    Cow: CowEntity,
    Equine: EquineEntity,
    Mooshroom: MooshroomEntity,
    Ocelot: OcelotEntity,
    Pig: PigEntity,
    Rabbit: RabbitEntity,
    Sheep: SheepEntity,
    SnowGolem: SnowGolemEntity,
    Villager: VillagerEntity,
    Wolf: WolfEntity,
    ArmorStand: ArmorStandEntity,
    EnderCrystal: EnderCrystalEntity,
    FallingBlock: FallingBlockEntity,
    Fireworks: FireworksEntity,
    FishingBobber: FishingBobberEntity,
    Item: ItemEntity,
    PrimedTnt: PrimedTntEntity,
    XpOrb: XpOrbEntity,
    LocalPlayer: LocalPlayerEntity,
    RemotePlayer: RemotePlayerEntity,
    Arrow: ArrowEntity,
    Egg: EggEntity,
    EnderPearl: EnderPearlEntity,
    ExperienceBottle: ExperienceBottleEntity,
    Fireball: FireballEntity,
    Potion: PotionEntity,
    SmallFireball: SmallFireballEntity,
    Snowball: SnowballEntity,
    WitherSkull: WitherSkullEntity,
    Boat: BoatEntity,
    Minecart: MinecartEntity,
    Lightning: LightningEntity,
    pub fn tick(entity: @This()) !void {
        switch (entity) {
            inline else => |specific_entity| {
                specific_entity.tick();
            },
        }
    }
};

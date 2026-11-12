status: enum(i32) {
    PerformRespawn = 0,
    RequestStats = 1,
    OpenInventoryAchievement = 2,
},

const main = @import("main");

const C2S = main.network.packet.C2S;

require("sprites")

miners = {}

function createMiner(x, y, speed, health, damage)
    local miner = {
        x = x,
        y = y,
        speed = speed,
        health = health,
        damage = damage,
        objective = nil,
    }

    table.insert(miners, miner)
end

function updateMiner(miner)
    
end
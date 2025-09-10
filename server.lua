local QBCore = exports['qb-core']:GetCoreObject()

local playerJobs = {}
local tabletItemName = Config and Config.Items and Config.Items.tablet or 'trucker_tablet'

-- Database bootstrap: ensure required tables/columns exist
local hasCitizenIdColumn = false

local function initDatabase()
    -- Create table if not exists (minimal schema for runtime)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `trucker_players` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `identifier` VARCHAR(50) NOT NULL,
        `name` VARCHAR(100) NOT NULL,
        `level` INT(11) DEFAULT 1,
        `experience` INT(11) DEFAULT 0,
        `total_earnings` INT(11) DEFAULT 0,
        `total_deliveries` INT(11) DEFAULT 0,
        `total_distance` FLOAT DEFAULT 0,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `identifier` (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

    -- Ensure 'identifier' column exists (for older mismatched schemas)
    local col = MySQL.scalar.await(
        'SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1',
        { 'trucker_players', 'identifier' }
    )
    if not col then
        -- If missing, try to add it. If another unique id exists like citizenid, copy it in a best-effort way.
        MySQL.query.await('ALTER TABLE `trucker_players` ADD COLUMN `identifier` VARCHAR(50) NOT NULL DEFAULT ""', {})
        -- Attempt to populate from common columns if present
        local hasCitizenId = MySQL.scalar.await(
            'SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1',
            { 'trucker_players', 'citizenid' }
        )
        if hasCitizenId then
            MySQL.update.await('UPDATE `trucker_players` SET `identifier` = `citizenid` WHERE `identifier` = ""', {})
        end
        -- Add unique index if not present
        pcall(function()
            MySQL.query.await('CREATE UNIQUE INDEX `uniq_identifier` ON `trucker_players` (`identifier`)')
        end)
    end

    -- cache whether citizenid column exists to support legacy schemas
    hasCitizenIdColumn = MySQL.scalar.await(
        'SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1',
        { 'trucker_players', 'citizenid' }
    ) and true or false
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    initDatabase()
end)

-- Register rental vehicle
local plateToOwner = {}
local plateToVehicleType = {}

RegisterNetEvent('qbx_truckerjob:registerRentedVehicle', function(plate, vehType)
    local src = source
    plateToOwner[plate] = src
    plateToVehicleType[plate] = vehType
end)

-- Return rental at depot
lib.callback.register('qbx_truckerjob:returnRental', function(src, plate)
    if not plate or plateToOwner[plate] ~= src then
        return { success = false, message = 'Not your rental' }
    end
    plateToOwner[plate] = nil
    plateToVehicleType[plate] = nil
    return { success = true }
end)

local function ensurePlayerInDatabase(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local identifier = Player.PlayerData.citizenid
    local name = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)) or (Player.PlayerData.name or ('Player '..tostring(src)))
    local exists = MySQL.scalar.await('SELECT id FROM trucker_players WHERE identifier = ? LIMIT 1', { identifier })
    if not exists then
        if hasCitizenIdColumn then
            MySQL.query.await('INSERT INTO trucker_players (identifier, citizenid, name, level, experience, total_earnings, total_deliveries, total_distance) VALUES (?, ?, ?, 1, 0, 0, 0, 0) ON DUPLICATE KEY UPDATE name = VALUES(name)', { identifier, identifier, name })
        else
            MySQL.query.await('INSERT INTO trucker_players (identifier, name, level, experience, total_earnings, total_deliveries, total_distance) VALUES (?, ?, 1, 0, 0, 0, 0) ON DUPLICATE KEY UPDATE name = VALUES(name)', { identifier, name })
        end
    else
        -- keep name up to date
        MySQL.update.await('UPDATE trucker_players SET name = ? WHERE identifier = ?', { name, identifier })
    end
end

local function fetchPlayerStatsFromDb(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    local identifier = Player.PlayerData.citizenid
    ensurePlayerInDatabase(src)
    local row = MySQL.single.await('SELECT level, experience, total_earnings, total_deliveries, total_distance FROM trucker_players WHERE identifier = ? LIMIT 1', { identifier })
    if not row then return nil end
    local stats = {
        level = row.level or 1,
        experience = row.experience or 0,
        total_earnings = row.total_earnings or 0,
        total_deliveries = row.total_deliveries or 0,
        total_distance = row.total_distance or 0,
        reputation = (playerJobs[identifier] and playerJobs[identifier].stats and playerJobs[identifier].stats.reputation) or 0,
        name = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)) or Player.PlayerData.name
    }
    playerJobs[identifier] = playerJobs[identifier] or {}
    playerJobs[identifier].stats = stats
    return stats
end

local function getIdentifier(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player and Player.PlayerData.citizenid or ('src:'..tostring(src))
end

local function getPlayerStats(src)
    -- Basic in-memory stats to start; can be replaced with DB
    local identifier = getIdentifier(src)
    local stats = playerJobs[identifier] and playerJobs[identifier].stats or {
        level = 1,
        experience = 0,
        total_earnings = 0,
        total_deliveries = 0,
        reputation = 0
    }
    return stats
end

lib.callback.register('qbx_truckerjob:getMenuData', function(src)
    local stats = fetchPlayerStatsFromDb(src) or getPlayerStats(src)
    return { playerStats = stats, difficulties = Config.Difficulties }
end)

-- Employment: give/remove tablet
lib.callback.register('qbx_truckerjob:startEmployment', function(src)
    if not exports.ox_inventory or not exports.ox_inventory.AddItem then
        return { success = false, message = 'Inventory not available' }
    end
    local current = exports.ox_inventory:Search(src, 'count', tabletItemName) or 0
    if current > 0 then
        return { success = true }
    end
    local ok, err = exports.ox_inventory:AddItem(src, tabletItemName, 1)
    if ok then
        return { success = true }
    else
        local msg = err == 'cannot_carry' and 'Inventory full' or 'Cannot give tablet'
        return { success = false, message = msg }
    end
end)

lib.callback.register('qbx_truckerjob:endEmployment', function(src)
    if not exports.ox_inventory or not exports.ox_inventory.RemoveItem then
        return { success = false, message = 'Inventory not available' }
    end
    local removed = exports.ox_inventory:RemoveItem(src, tabletItemName, 1)
    if removed then
        return { success = true }
    else
        return { success = false, message = 'No tablet to return' }
    end
end)

lib.callback.register('qbx_truckerjob:startJob', function(src, difficultyKey)
    -- anti-spam throttle
    local now = os.time()
    playerJobs[src] = playerJobs[src] or {}
    if playerJobs[src].lastStart and (now - playerJobs[src].lastStart) < 2 then
        return { success = false, message = 'Please wait...' }
    end
    playerJobs[src].lastStart = now

    local difficulty = Config.Difficulties[difficultyKey]
    if not difficulty then
        return { success = false, message = 'Invalid difficulty' }
    end

    local identifier = getIdentifier(src)
    playerJobs[identifier] = playerJobs[identifier] or {}
    if playerJobs[identifier].active then
        return { success = false, message = 'You already have an active job' }
    end

    -- pick a destination server-side
    local destinations = Config.DeliveryLocations[difficultyKey] or {}
    local destination = destinations[math.random(1, #destinations)]
    local job = {
        id = ('job-%s-%d'):format(difficultyKey, os.time()),
        difficulty = difficultyKey,
        vehicle = difficulty.vehicle,
        trailer = difficulty.trailer,
        deposit = 0,
        destination = destination,
        remainingBoxes = (difficulty.type == 'box' and tonumber(difficulty.boxes)) or 0
    }
    playerJobs[identifier].active = job
    return { success = true, job = job }
end)

lib.callback.register('qbx_truckerjob:cancelJob', function(src)
    local identifier = getIdentifier(src)
    local state = playerJobs[identifier]
    if not state or not state.active then return true end
    -- refund half deposit
    local refund = math.floor((state.active.deposit or 0) * 0.5)
    if refund > 0 then
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.AddMoney('bank', refund, 'Trucker deposit refund')
    end
    state.active = nil
    return true
end)

lib.callback.register('qbx_truckerjob:rentVehicle', function(src, vehicleType, difficultyKey)
    -- anti-spam
    local now = os.time()
    playerJobs[src] = playerJobs[src] or {}
    if playerJobs[src].lastRent and (now - playerJobs[src].lastRent) < 2 then
        return { success = false, message = 'Please wait...' }
    end

    playerJobs[src].lastRent = now
    local difficulty = Config.Difficulties[difficultyKey]
    if not difficulty then
        return { success = false, message = 'Invalid difficulty' }
    end
    
    -- compute dynamic rent price from config
    local identifier = getIdentifier(src)
    local stats = getPlayerStats(src)
    local base = (Config.RentalPricing.base[difficultyKey] or 500)
    local rep = stats.reputation or 0
    local repMult = 1.0
    for i = #Config.RentalPricing.repDiscounts, 1, -1 do
        local tier = Config.RentalPricing.repDiscounts[i]
        if rep >= tier.required then repMult = tier.multiplier break end
    end
    local exp = stats.experience or 0
    local expSteps = math.floor(exp / (Config.RentalPricing.expReduction.per or 10000))
    local expMult = 1.0 - expSteps * (Config.RentalPricing.expReduction.step or 0.02)
    local minExpMult = Config.RentalPricing.expReduction.minMultiplier or 0.80
    if expMult < minExpMult then expMult = minExpMult end
    local rentPrice = math.floor(base * repMult * expMult)
    
    local Player = QBCore.Functions.GetPlayer(src)
    if rentPrice > 0 and Player.Functions.RemoveMoney('cash', rentPrice, 'Trucker rent') ~= true then
        return { success = false, message = 'Not enough cash to rent' }
    end
    
    -- spawn handled client-side or by separate spawn system; return success
    return { success = true, rentPrice = rentPrice }
end)

-- Inventory helpers
lib.callback.register('qbx_truckerjob:removeItem', function(src, itemName, amount)
    if not exports.ox_inventory or not exports.ox_inventory.RemoveItem then
        return false
    end
    return exports.ox_inventory:RemoveItem(src, itemName, amount or 1) and true or false
end)

-- Complete job and payout with reputation multipliers
RegisterNetEvent('qbx_truckerjob:completeJob', function(distanceKm)
    local src = source
    local identifier = getIdentifier(src)
    local state = playerJobs[identifier]
    if not state or not state.active then return end

    local Player = QBCore.Functions.GetPlayer(src)
    local diffKey = state.active.difficulty
    local diff = Config.Difficulties[diffKey]
    if not diff then return end

    local stats = getPlayerStats(src)
    local baseMoney = math.random(diff.rewards.money[1], diff.rewards.money[2])
    
    -- Calculate EXP based on job type
    local baseExp = 0
    if diff.type == 'box' then
        -- Box jobs: EXP per box delivered
        local totalBoxes = diff.boxes or 1
        baseExp = totalBoxes * (diff.rewards.exp or 2)
    elseif diff.type == 'trailer' then
        -- Trailer jobs: random EXP between min and max
        if type(diff.rewards.exp) == 'table' then
            baseExp = math.random(diff.rewards.exp[1], diff.rewards.exp[2])
        else
            baseExp = math.random(3, 10) -- fallback
        end
    else
        baseExp = diff.rewards.exp or 5
    end

    -- reputation tier
    local rep = stats.reputation or 0
    local tiers = Config.Reputation.tiers
    local payoutMult, expMult = 1.0, 1.0
    for i = #tiers, 1, -1 do
        if rep >= tiers[i].required then
            payoutMult = tiers[i].payoutMultiplier
            expMult = tiers[i].expMultiplier
            break
        end
    end

    local money = math.floor(baseMoney * payoutMult)
    local exp = math.floor(baseExp * expMult)

    Player.Functions.AddMoney('bank', money, 'Trucker payout')

    -- update stats
    stats.experience = (stats.experience or 0) + exp
    stats.total_earnings = (stats.total_earnings or 0) + money
    stats.total_deliveries = (stats.total_deliveries or 0) + 1
    stats.reputation = (stats.reputation or 0) + (Config.Reputation.perDelivery or 50)
    playerJobs[identifier].stats = stats

    -- persist to database
    MySQL.update.await('UPDATE trucker_players SET experience = ?, total_earnings = ?, total_deliveries = ?, total_distance = ?, level = ? WHERE identifier = ?', {
        stats.experience, stats.total_earnings, stats.total_deliveries, (stats.total_distance or 0) + (distanceKm or 0), math.floor((stats.experience or 0) / 100) + 1, getIdentifier(src)
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Delivery Complete',
        description = ('Earned $%s and %s EXP'):format(money, exp),
        type = 'success',
        duration = 5000
    })

    state.active = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    local identifier = getIdentifier(src)
    playerJobs[identifier] = nil
end)
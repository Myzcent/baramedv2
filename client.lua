local QBCore = exports['qb-core']:GetCoreObject()

-- Type definitions
---@class ActiveJob
---@field destination { coords: vector4, name: string }
---@field difficulty string
---@field trailerEntity number
---@field pickupBlip number
---@field vehicle string
---@field remainingBoxes number

-- State management
---@class JobState
---@field active boolean
---@field job ActiveJob|nil
---@field blips table<string,number>
---@field entities table<string,number>
---@field cooldowns table<string,number>

local JobState = {
    active = false,
    job = nil,
    blips = {},
    entities = {},
    cooldowns = {},
    cleanup = function(self)
        for _, blip in pairs(self.blips) do if DoesBlipExist(blip) then RemoveBlip(blip) end end
        for _, entity in pairs(self.entities) do if DoesEntityExist(entity) then DeleteEntity(entity) end end
        self.blips = {}
        self.entities = {}
        self.job = nil
        self.active = false
    end
}

local nuiOpen = false
local isRenting = false
local activeJob = nil
local deliveryBlip = nil
local deliveryPed = nil

local function startDeliveryAnim(targetPed)
    local ped = PlayerPedId()
    if targetPed and DoesEntityExist(targetPed) then
        TaskTurnPedToFaceEntity(ped, targetPed, 500)
        Wait(500)
    end
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
end

local function stopDeliveryAnim()
    ClearPedTasks(PlayerPedId())
end

local function giveVehicleKeys(vehicle, plate)
    plate = plate or GetVehicleNumberPlateText(vehicle)
    -- slight delay to ensure plate is set and entity exists for other scripts
    Wait(100)
    -- make sure vehicle is usable even if keys resource fails
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleDoorsLocked(vehicle, 1) -- unlocked
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehRadioStation(vehicle, 'OFF')
    -- set statebag hint some scripts watch
    if Entity and Entity(vehicle) and Entity(vehicle).state and Entity(vehicle).state.set then
        pcall(function() Entity(vehicle).state:set('owner', true, true) end)
        pcall(function() Entity(vehicle).state:set('keys', true, true) end)
        pcall(function() Entity(vehicle).state:set('plate', plate, true) end)
    end
    -- Prefer event-based keys to avoid missing export errors
    -- standalone vehiclekeys client events
    if TriggerEvent then
        pcall(function() TriggerEvent('vehiclekeys:client:SetOwner', plate) end)
        pcall(function() TriggerEvent('qs-vehiclekeys:client:GiveKeys', plate) end)
        pcall(function() TriggerEvent('wasabi_carlock:client:GiveKey', plate) end)
    end
    -- some servers use server-side acquisition
    if TriggerServerEvent then
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    end
    -- done
end

local function spawnDeliveryNPC(target)
    if deliveryPed and DoesEntityExist(deliveryPed) then DeleteEntity(deliveryPed) deliveryPed = nil end
    local mdl = `s_m_m_dockwork_01`
    if lib and lib.requestModel then lib.requestModel(mdl) else RequestModel(mdl) while not HasModelLoaded(mdl) do Wait(0) end end
    deliveryPed = CreatePed(0, mdl, target.coords.x, target.coords.y, target.coords.z - 1.0, target.coords.w or 0.0, false, false)
    FreezeEntityPosition(deliveryPed, true)
    SetEntityInvincible(deliveryPed, true)
    SetBlockingOfNonTemporaryEvents(deliveryPed, true)

    exports.ox_target:addLocalEntity(deliveryPed, {
        {
            name = 'qbx_truckerjob:deliverCargo',
            icon = 'fa-solid fa-box',
            label = 'Deliver Box',
            canInteract = function(entity, distance, coords, name)
                if not activeJob then return false end
                local diffCfg = Config.Difficulties[activeJob.difficulty]
                if not diffCfg then return false end
                if diffCfg.type == 'box' then
                    return (exports.ox_inventory:Search('count', Config.Items.box) or 0) > 0 and (activeJob.remainingBoxes or 1) > 0
                else
                    local ped = PlayerPedId()
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 then
                        local attached, trailer = GetVehicleTrailerVehicle(veh)
                        return attached and trailer ~= 0
                    end
                    return false
                end
            end,
            onSelect = function()
                if not activeJob then return end
                local diffCfg = Config.Difficulties[activeJob.difficulty]
                if not diffCfg then return end
                if diffCfg.type == 'box' then
                    startDeliveryAnim(deliveryPed)
                    if lib and lib.progressBar then
                        lib.progressBar({ duration = Config.Progress and Config.Progress.deliver or 60000, label = 'Delivering boxes...', useWhileDead = false, canCancel = false, disable = { move = true, car = true, combat = true } })
                    end
                    local count = exports.ox_inventory:Search('count', Config.Items.box) or 0
                    if count <= 0 then
                        QBCore.Functions.Notify('You need cargo to deliver here.', 'error')
                        stopDeliveryAnim()
                        return
                    end
                    if (activeJob.remainingBoxes or 0) <= 0 then
                        QBCore.Functions.Notify('All boxes delivered.', 'inform')
                        stopDeliveryAnim()
                        return
                    end
                    local removed = lib.callback.await('qbx_truckerjob:removeItem', false, Config.Items.box, 1)
                    if not removed then
                        QBCore.Functions.Notify('Failed to remove cargo.', 'error')
                        stopDeliveryAnim()
                        return
                    end
                    activeJob.remainingBoxes = (activeJob.remainingBoxes or 1) - 1
                    if activeJob.remainingBoxes > 0 then
                        QBCore.Functions.Notify(('Delivered 1 box. %s remaining.'):format(activeJob.remainingBoxes), 'success')
                        stopDeliveryAnim()
                        return
                    end
                else
                    startDeliveryAnim(deliveryPed)
                    if lib and lib.progressBar then
                        lib.progressBar({ duration = Config.Progress and Config.Progress.deliver or 60000, label = 'Delivering trailer...', useWhileDead = false, canCancel = false, disable = { move = true, car = true, combat = true } })
                    end
                    local ped = PlayerPedId()
                    local veh = GetVehiclePedIsIn(ped, false)
                    local attached = false
                    local trailerEntity = 0
                    if veh ~= 0 then
                        attached, trailerEntity = GetVehicleTrailerVehicle(veh)
                    end
                    if not attached then
                        QBCore.Functions.Notify('Attach your trailer before delivering.', 'error')
                        stopDeliveryAnim()
                        return
                    end
                    -- Detach and delete trailer only; keep truck
                    DetachVehicleFromTrailer(veh)
                    if trailerEntity ~= 0 and DoesEntityExist(trailerEntity) then
                        SetVehicleDoorsLocked(trailerEntity, 2)
                        SetEntityAsMissionEntity(trailerEntity, true, true)
                        DeleteEntity(trailerEntity)
                    end
                end
                TriggerServerEvent('qbx_truckerjob:completeJob', 0.0)
                if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
                if deliveryPed and DoesEntityExist(deliveryPed) then DeleteEntity(deliveryPed) deliveryPed = nil end
                stopDeliveryAnim()
                activeJob = nil
            end
        }
    })
end

-- Create depot blip
CreateThread(function()
    if not Config.Depot.blip or not Config.Depot.blip.enabled then return end
    local blip = AddBlipForCoord(Config.Depot.coords.x, Config.Depot.coords.y, Config.Depot.coords.z)
    SetBlipSprite(blip, Config.Depot.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Depot.blip.scale or 0.8)
    SetBlipColour(blip, Config.Depot.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Depot.blip.name or 'Trucker Depot')
    EndTextCommandSetBlipName(blip)
end)

-- Ox_Target: open menu at depot
CreateThread(function()
    local mdl = Config.NPC.model or `s_m_m_dockwork_01`
    if lib and lib.requestModel then
        lib.requestModel(mdl)
    else
        RequestModel(mdl)
        while not HasModelLoaded(mdl) do Wait(0) end
    end
    local spawn = Config.NPC.coords or Config.Depot.coords
    local ped = CreatePed(0, mdl, spawn.x, spawn.y, spawn.z - 1.0, spawn.w or Config.Depot.heading or 0.0, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if Config.NPC.blip and Config.NPC.blip.enabled then
        local blip = AddBlipForCoord(spawn.x, spawn.y, spawn.z)
        SetBlipSprite(blip, Config.NPC.blip.sprite or 479)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.NPC.blip.scale or 0.8)
        SetBlipColour(blip, Config.NPC.blip.color or 26)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.NPC.blip.name or 'Trucker Foreman')
        EndTextCommandSetBlipName(blip)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'qbx_truckerjob:startEmployment',
            icon = 'fa-solid fa-truck-fast',
            label = Config.NPC.startLabel or 'Start Trucker Job',
            canInteract = function()
                local hasTablet = (exports.ox_inventory:Search('count', Config.Items.tablet) or 0) > 0
                return not hasTablet
            end,
            onSelect = function()
                local result = lib.callback.await('qbx_truckerjob:startEmployment', false)
                if result and result.success then
                    QBCore.Functions.Notify('You received a trucker tablet.', 'success')
                else
                    QBCore.Functions.Notify(result and result.message or 'Unable to start job', 'error')
                end
            end
        },
        {
            name = 'qbx_truckerjob:endEmployment',
            icon = 'fa-solid fa-person-walking-arrow-right',
            label = Config.NPC.endLabel or 'Return Trucker Job',
            canInteract = function()
                local hasTablet = (exports.ox_inventory:Search('count', Config.Items.tablet) or 0) > 0
                return hasTablet
            end,
            onSelect = function()
                local result = lib.callback.await('qbx_truckerjob:endEmployment', false)
                if result and result.success then
                    QBCore.Functions.Notify('You returned your trucker tablet.', 'success')
                else
                    QBCore.Functions.Notify(result and result.message or 'Unable to end job', 'error')
                end
            end
        }
    })
end)

-- Ox_Target: rental NPC
CreateThread(function()
    local cfg = Config.NPCRental
    if not cfg or not cfg.coords then return end
    local mdl = cfg.model or `s_m_m_trucker_01`
    if lib and lib.requestModel then
        lib.requestModel(mdl)
    else
        RequestModel(mdl)
        while not HasModelLoaded(mdl) do Wait(0) end
    end
    local p = cfg.coords
    local ped = CreatePed(0, mdl, p.x, p.y, p.z - 1.0, p.w or 0.0, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if cfg.blip and cfg.blip.enabled then
        local blip = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(blip, cfg.blip.sprite or 67)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, cfg.blip.scale or 0.8)
        SetBlipColour(blip, cfg.blip.color or 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(cfg.blip.name or 'Truck Rental')
        EndTextCommandSetBlipName(blip)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'qbx_truckerjob:openRent',
            icon = 'fa-solid fa-key',
            label = (cfg.label or 'Open Truck Rental'),
            onSelect = function()
                if lib and lib.progressBar then
                    lib.progressBar({ duration = Config.Progress and Config.Progress.rentVehicle or 1500, label = 'Opening Rental...', useWhileDead = false, canCancel = false, disable = { move = true, car = true, combat = true } })
                end
                if nuiOpen then return end
                SetNuiFocus(true, true)
                nuiOpen = true
                local serverData = lib.callback.await('qbx_truckerjob:getMenuData', false)
                SendNUIMessage({
                    action = 'openRentMenu',
                    difficulties = serverData.difficulties
                })
            end
        }
    })
end)

-- Return rental vehicle command (can be used anywhere)
RegisterCommand('returnrental', function(source, args, rawCommand)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then 
        QBCore.Functions.Notify('You must be in a vehicle to return it', 'error')
        return 
    end
    
    local plate = GetVehicleNumberPlateText(veh)
    local ok = lib.callback.await('qbx_truckerjob:returnRental', false, plate)
    if ok and ok.success then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteEntity(veh)
        QBCore.Functions.Notify('Rental returned successfully', 'success')
    else
        QBCore.Functions.Notify((ok and ok.message) or 'This is not your rental vehicle', 'error')
    end
end)

-- Add keybind for returning rental
RegisterKeyMapping('returnrental', 'Return Rental Vehicle', 'keyboard', 'F7')

-- Open menu helper
function OpenTruckerMenu()
    if nuiOpen then return end
    local hasTablet = (exports.ox_inventory:Search('count', Config.Items.tablet) or 0) > 0
    if not hasTablet and not (Config.Debug and Config.Debug.allowOpenWithoutTablet) then
        QBCore.Functions.Notify('You need a trucker tablet to open this.', 'error')
        return
    end
    SetNuiFocus(true, true)
    nuiOpen = true

    local serverData = nil
    local ok, res = pcall(function()
        return lib.callback.await('qbx_truckerjob:getMenuData', false)
    end)
    if ok then serverData = res end
    if not serverData or not serverData.playerStats or not serverData.difficulties then
        -- retry once after a short delay (resource/db might be warming up)
        Wait(200)
        ok, res = pcall(function()
            return lib.callback.await('qbx_truckerjob:getMenuData', false)
        end)
        if ok then serverData = res end
    end
    if not serverData or not serverData.playerStats or not serverData.difficulties then
        -- fallback to open UI with defaults so user can still see menu
        serverData = serverData or {}
        serverData.playerStats = serverData.playerStats or { level = 1, experience = 0, reputation = 0, total_deliveries = 0, total_earnings = 0, name = 'Driver' }
        serverData.difficulties = serverData.difficulties or Config.Difficulties
        QBCore.Functions.Notify('Loaded fallback stats. DB may be initializing.', 'primary')
    end

    SendNUIMessage({
        action = 'openJobMenu',
        playerStats = serverData.playerStats,
        difficulties = serverData.difficulties,
        currentJob = activeJob
    })
end

-- Get random trailer spawn location
local function GetTrailerSpawnLocation()
    if Config.Rental.trailerSpawns and #Config.Rental.trailerSpawns > 0 then
        return Config.Rental.trailerSpawns[math.random(#Config.Rental.trailerSpawns)]
    end
    return Config.Rental.trailerSpawn
end

-- Spawn trailer at pickup location
local function SpawnTrailerAtPickup(difficulty)
    if not difficulty or difficulty.type ~= 'trailer' or not difficulty.trailer then return nil end
    
    local spawn = GetTrailerSpawnLocation()
    if not spawn then return nil end

    -- Load model
    local model = joaat(difficulty.trailer)
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(model) then return nil end

    -- Clear area and spawn
    ClearAreaOfVehicles(spawn.x, spawn.y, spawn.z, 10.0, false, false, false, false, false)
    Wait(100)

    local trailer = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    if not DoesEntityExist(trailer) then 
        SetModelAsNoLongerNeeded(model)
        return nil 
    end

    -- Setup trailer
    SetEntityAsMissionEntity(trailer, true, true)
    SetVehicleDoorsLocked(trailer, 1)
    SetVehicleOnGroundProperly(trailer)

    -- Add pickup blip
    local blip = AddBlipForEntity(trailer)
    SetBlipSprite(blip, 479)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pickup Trailer")
    EndTextCommandSetBlipName(blip)

    SetModelAsNoLongerNeeded(model)
    return trailer, blip
end

-- NUI Callbacks
RegisterNUICallback('startJob', function(data, cb)
    local difficulty = data and data.difficulty
    if not difficulty then cb('error') return end

    -- Close NUI immediately
    if nuiOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'hideUI' })
        nuiOpen = false
    end

    JobState:cleanup() -- Cleanup any existing job state

    local ok, result = pcall(function()
        return lib.callback.await('qbx_truckerjob:startJob', false, difficulty)
    end)

    if ok and result and result.success then
        if lib and lib.progressBar then
            lib.progressBar({
                duration = Config.Progress and Config.Progress.startJob or 3000,
                label = 'Starting job...',
                useWhileDead = false,
                canCancel = false,
                disable = { move = true, car = true, combat = true }
            })
        end

        activeJob = result.job

        -- For trailer jobs, spawn trailer at pickup location (no auto-attach)
        if result.job.difficulty then
            local config = Config.Difficulties[result.job.difficulty]
            if config and config.type == 'trailer' then
                local trailer, pickupBlip = SpawnTrailerAtPickup(config)
                if trailer then
                    activeJob.trailerEntity = trailer
                    activeJob.pickupBlip = pickupBlip
                    QBCore.Functions.Notify('Trailer spawned at pickup location. Go collect it!', 'primary')
                end
            end
        end

        -- Set up delivery route
        local target = result.job and result.job.destination
        if target and target.coords then
            if deliveryBlip then RemoveBlip(deliveryBlip) end
            deliveryBlip = AddBlipForCoord(target.coords.x, target.coords.y, target.coords.z)
            SetBlipRoute(deliveryBlip, true)
            SetBlipSprite(deliveryBlip, 1)
            SetBlipColour(deliveryBlip, 5)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Delivery Location")
            EndTextCommandSetBlipName(deliveryBlip)
            
            -- Spawn delivery NPC for box jobs
            local config = Config.Difficulties[result.job.difficulty]
            if config and config.type == 'box' then
                spawnDeliveryNPC(target)
            end
            
            QBCore.Functions.Notify(('Deliver to %s'):format(target.name or 'Destination'), 'primary')
        end

        QBCore.Functions.Notify('Job started!', 'success')
    else
        QBCore.Functions.Notify(result and result.message or 'Cannot start job', 'error')
    end

    cb('ok')
end)

RegisterNUICallback('cancelJob', function(_, cb)
    -- Close NUI immediately
    if nuiOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'hideUI' })
        nuiOpen = false
    end

    if lib and lib.progressBar then
        lib.progressBar({ duration = Config.Progress and Config.Progress.cancelJob or 2000, label = 'Cancelling job...', useWhileDead = false, canCancel = false, disable = { move = true, car = true, combat = true } })
    end

    -- Cleanup all job entities and blips
    if activeJob then
        -- Cleanup trailer if exists
        if activeJob.trailerEntity and DoesEntityExist(activeJob.trailerEntity) then
            SetEntityAsMissionEntity(activeJob.trailerEntity, true, true)
            DeleteEntity(activeJob.trailerEntity)
        end
        -- Remove blips
        if activeJob.pickupBlip then RemoveBlip(activeJob.pickupBlip) end
    end
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    if deliveryPed and DoesEntityExist(deliveryPed) then DeleteEntity(deliveryPed) end

    -- Cancel on server
    lib.callback.await('qbx_truckerjob:cancelJob', false)

    -- Reset state
    activeJob = nil
    deliveryBlip = nil
    deliveryPed = nil

    QBCore.Functions.Notify('Job cancelled', 'error')
    cb('ok')
end)

RegisterNUICallback('rentVehicle', function(data, cb)
    local vehicleType = data and data.vehicleType
    local difficulty = data and data.difficulty
    if not vehicleType or not difficulty then cb('error') return end
    if isRenting then cb('ok') return end
    
    -- Check distance to rental location
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local rentalPos = Config.NPCRental.coords
    local distance = #(playerPos - vector3(rentalPos.x, rentalPos.y, rentalPos.z))
    
    if distance > 10.0 then
        QBCore.Functions.Notify('You must be near the rental location to rent a vehicle', 'error')
        cb('ok')
        return
    end
    
    isRenting = true
    
    -- close UI immediately to prevent double clicks
    if nuiOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'hideUI' })
        nuiOpen = false
    end
    
    if lib and lib.progressBar then
        lib.progressBar({ duration = Config.Progress and Config.Progress.rentVehicle or 3000, label = 'Processing rental...', useWhileDead = false, canCancel = false, disable = { move = true, car = true, combat = true } })
    end
    
    local result = lib.callback.await('qbx_truckerjob:rentVehicle', false, vehicleType, difficulty)
    if result and result.success then
        QBCore.Functions.Notify('Vehicle rented!', 'success')
        -- spawn vehicle client-side
        local spawn = Config.Rental.spawn
        local model = joaat(vehicleType)
        if lib and lib.requestModel then lib.requestModel(model) else RequestModel(model) while not HasModelLoaded(model) do Wait(0) end end
        local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleOnGroundProperly(veh)
        local plate = ('TRK%s'):format(math.random(100,999))
        SetVehicleNumberPlateText(veh, plate)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        giveVehicleKeys(veh, plate)
        -- Register rental vehicle
        TriggerServerEvent('qbx_truckerjob:registerRentedVehicle', plate, vehicleType)

        -- NO auto-attach for trailer jobs - trailer will be at pickup location
    else
        QBCore.Functions.Notify(result and result.message or 'Cannot rent vehicle', 'error')
    end
    isRenting = false
    cb('ok')
end)

RegisterNUICallback('closeNUI', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideUI' })
    nuiOpen = false
    cb('ok')
end)

-- Handle trailer delivery at destination - player must detach trailer first
local function HandleTrailerDelivery()
    if not activeJob or not activeJob.destination then return end

    local job = activeJob
    if not job.destination or not job.destination.coords then return end

    local config = Config.Difficulties[job.difficulty]
    if not config or config.type ~= 'trailer' then return end

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local dest = job.destination.coords
    local dist = #(pos - vector3(dest.x, dest.y, dest.z))

    -- Draw delivery marker
    if dist < 50.0 then
        DrawMarker(1, dest.x, dest.y, dest.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 10.0, 10.0, 1.5, 0, 200, 100, 120, false, true, 2, false, nil, nil, false)

        -- Check delivery conditions when player is near and on foot
        if dist < 15.0 and not IsPedInAnyVehicle(ped, true) then
            -- Find nearby trailer that belongs to the job
            if activeJob.trailerEntity and DoesEntityExist(activeJob.trailerEntity) then
                local trailerPos = GetEntityCoords(activeJob.trailerEntity)
                local trailerDist = #(pos - trailerPos)
                
                if trailerDist < 8.0 then
                    -- Check if trailer is detached from any vehicle
                    local isAttached = false
                    local vehicles = GetGamePool('CVehicle')
                    for _, veh in ipairs(vehicles) do
                        if GetVehicleClass(veh) ~= 11 then -- Not a trailer
                            local hasTrailer, attachedTrailer = GetVehicleTrailerVehicle(veh)
                            if hasTrailer and attachedTrailer == activeJob.trailerEntity then
                                isAttached = true
                                QBCore.Functions.Notify('Detach the trailer first before delivery!', 'error')
                                break
                            end
                        end
                    end

                    -- Only show delivery option if trailer is detached
                    if not isAttached then
                        exports.ox_target:addLocalEntity(activeJob.trailerEntity, {
                            {
                                name = 'qbx_truckerjob:deliverTrailer',
                                icon = 'fa-solid fa-truck-ramp-box',
                                label = 'Deliver Trailer',
                                onSelect = function()
                                    lib.progressBar({
                                        duration = 30000,
                                        label = 'Processing trailer delivery...',
                                        useWhileDead = false,
                                        canCancel = false,
                                        disable = { move = true, car = true, combat = true }
                                    })
                                    
                                    -- Complete delivery
                                    DeleteEntity(activeJob.trailerEntity)
                                    if activeJob.pickupBlip then RemoveBlip(activeJob.pickupBlip) end
                                    if deliveryBlip then RemoveBlip(deliveryBlip) end
                                    
                                    TriggerServerEvent('qbx_truckerjob:completeJob', 0.0)
                                    activeJob = nil
                                    deliveryBlip = nil
                                    
                                    QBCore.Functions.Notify('Trailer delivered successfully!', 'success')
                                end
                            }
                        })
                    end
                end
            end
        end
    end
end

-- Main delivery processing thread
CreateThread(function()
    while true do
        Wait(500)
        HandleTrailerDelivery()
    end
end)

-- Command to open menu for testing
RegisterCommand(Config.Commands.openTablet, function(source, args, rawCommand)
    OpenTruckerMenu()
end)

RegisterKeyMapping(Config.Commands.openTablet, 'Open Trucker Tablet', 'keyboard', Config.Commands.keybind or 'F6')

-- Make tablet item usable via ox_inventory
RegisterNetEvent('ox:useItem', function(itemName, data)
    if itemName ~= Config.Items.tablet then return end
    OpenTruckerMenu()
end)

-- Clean focus if resource stops while NUI is open
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if nuiOpen then
        SetNuiFocus(false, false)
        nuiOpen = false
    end
    -- Cleanup all job state
    JobState:cleanup()
end)

-- Export for other scripts to open menu
exports('OpenTruckerMenu', OpenTruckerMenu)

-- Export used by ox_inventory item definition
exports('UseTruckerTablet', function(item, slot, data)
    OpenTruckerMenu()
end)

RegisterNetEvent('qbx_truckerjob:registerRentedVehicle', function(plate, vehType)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        DetachVehicleFromTrailer(veh) -- Ensure no trailer is attached when renting
    end
end)
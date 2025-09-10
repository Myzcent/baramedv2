Config = {
    Locale = 'en',
    Debug = {
        allowOpenWithoutTablet = false
    },
    Progress = {
        startJob = 3000,
        cancelJob = 2000,
        rentVehicle = 3000,
        deliver = 30000,
        startEmployment = 3500,
        endEmployment = 3500
    },
    Items = {
        tablet = 'trucker_tablet',
        box = 'box'
    },
    Commands = {
        openTablet = 'tablet', -- command name to open tablet UI
        keybind = 'F6' -- default key for opening tablet
    },
    NPC = {
        model = `s_m_m_dockwork_01`,
        startLabel = 'Start Trucker Job',
        endLabel = 'Return Trucker Job',
        coords = vec4(-325.6071, -2773.0779, 5.2070, 167.5888),
        blip = {
            enabled = true,
            sprite = 479, -- dock worker
            color = 26,
            scale = 0.8,
            name = 'Trucker Foreman'
        }
    },
    NPCRental = {
        model = `s_m_m_trucker_01`,
        label = 'Open Truck Rental',
        coords = vec4(-353.1340, -2780.8174, 5.0004, 280.6833),
        blip = {
            enabled = true,
            sprite = 67, -- truck
            color = 3,
            scale = 0.8,
            name = 'Truck Rental'
        }
    },
    Depot = {
        coords = vec4(-329.9640, -2764.7158, 4.9953, 267.7668),
        heading = 90.0,
        targetLabel = 'Open Trucker Menu',
        blip = {
            enabled = true,
            sprite = 477,
            color = 3,
            scale = 0.8,
            name = 'Trucker Depot'
        }
    },
    Rental = {
        spawn = vec4(-362.9955, -2772.2505, 6.0112, 346.0849),
        -- Trailer spawn locations (will randomly select one)
        trailerSpawns = {
            vec4(1186.5, -3235.4, 6.1, 90.0),     -- Terminal Dock
            vec4(816.12, -3211.45, 5.9, 175.0),   -- Container Area
            vec4(938.45, -3154.87, 5.9, 90.0),    -- Warehouse Area
            vec4(1013.67, -3200.12, 5.9, 0.0),    -- Shipping Area
            vec4(777.34, -3185.67, 5.9, 270.0),   -- Port Loading
            vec4(955.23, -3125.45, 5.9, 85.0),    -- Logistics Hub
            vec4(892.56, -3205.78, 5.9, 180.0),   -- Storage Yard
            vec4(1095.34, -3192.56, 5.9, 270.0),  -- Freight Zone
            vec4(845.67, -3187.89, 5.9, 90.0),    -- Loading Bay
            vec4(982.45, -3167.23, 5.9, 180.0)    -- Cargo Terminal
        },
        -- Default spawn point if no random location is selected
        trailerSpawn = vec4(1186.5, -3235.4, 6.1, 90.0)
    },
    RentalPricing = {
        base = {
            easy = 300,
            medium = 600,
            hard = 1200
        },
        repDiscounts = {
            { required = 0, multiplier = 1.00 },
            { required = 500, multiplier = 0.95 },
            { required = 1500, multiplier = 0.90 },
            { required = 3500, multiplier = 0.85 }
        },
        expReduction = {
            per = 10000, -- every 10k exp
            step = 0.02, -- 2% cheaper
            minMultiplier = 0.80 -- cap at 20% off from EXP
        }
    },
    DifficultyMultipliers = {
        easy = 1.0,
        medium = 1.5,
        hard = 2.0
    },
    Reputation = {
        -- reputation points accumulate; tier unlocks and multipliers
        tiers = {
            { name = 'Rookie', required = 0, payoutMultiplier = 1.0, expMultiplier = 1.0 },
            { name = 'Skilled', required = 500, payoutMultiplier = 1.1, expMultiplier = 1.1 },
            { name = 'Pro', required = 1500, payoutMultiplier = 1.25, expMultiplier = 1.2 },
            { name = 'Elite', required = 3500, payoutMultiplier = 1.4, expMultiplier = 1.3 }
        },
        perDelivery = 50
    },
    DeliveryLocations = {
        easy = {
            { name = 'LS Docks', coords = vec4(1200.45, -3250.25, 6.0, 90.0) },
            { name = 'Vinewood Bowl', coords = vec4(688.6, 572.6, 130.5, 340.0) },
            { name = 'La Mesa', coords = vec4(842.8, -236.3, 72.0, 270.0) }
        },
        medium = {
            { name = 'Sandy Shores Airfield', coords = vec4(1735.5, 3296.8, 41.1, 105.0) },
            { name = 'Grapeseed Depot', coords = vec4(1691.0, 4785.8, 41.9, 190.0) }
        },
        hard = {
            { name = 'Paleto Bay Factory', coords = vec4(-103.7, 6278.8, 31.4, 135.0) },
            { name = 'Zancudo Base Gate', coords = vec4(-2388.0, 3277.2, 32.8, 60.0) },
            { name = 'Mount Chiliad Site', coords = vec4(1479.2, 6511.2, 20.0, 180.0) }
        }
    },
    Difficulties = {
        easy = {
            label = 'Local Deliveries',
            requiredLevel = 1,
            type = 'box',
            vehicle = 'mule',
            boxes = 6,
            deposit = 0,
            rewards = { money = {800, 1200}, exp = 2 }, -- 2 EXP per box
        },
        medium = {
            label = 'Citywide Logistics',
            requiredLevel = 3,
            type = 'box',
            vehicle = 'benson',
            boxes = 10,
            deposit = 0,
            rewards = { money = {1400, 2000}, exp = 2 }, -- 2 EXP per box
        },
        hard = {
            label = 'Long-Haul Trailer',
            requiredLevel = 5,
            type = 'trailer',
            vehicle = 'phantom3',
            trailer = 'trailers',
            deposit = 0,
            rewards = { money = {2200, 3200}, exp = {3, 10} }, -- 3-10 EXP for trailer
        }
    }
}

return Config
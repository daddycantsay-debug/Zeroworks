Config = {}

-- ─────────────────────────────────────────────────────────────────
--  FRAMEWORK  ('auto' | 'esx' | 'qbcore')
--  'auto' will detect whichever is running on your server
-- ─────────────────────────────────────────────────────────────────
Config.Framework = 'auto'

-- ─────────────────────────────────────────────────────────────────
--  COMMANDS & KEYS
-- ─────────────────────────────────────────────────────────────────
Config.TrapCommand  = 'trap'   -- /trap to toggle trap mode
Config.SellKey      = 51       -- GTA control index — 51 = E key

-- ─────────────────────────────────────────────────────────────────
--  NPC BEHAVIOUR
-- ─────────────────────────────────────────────────────────────────
Config.DetectionRadius = 30.0   -- metres — how far NPC spawns from car
Config.NPCTimeout      = 30000  -- ms — how long buyer waits before leaving
Config.SpawnInterval   = 15000  -- ms — delay between buyer spawns

-- ─────────────────────────────────────────────────────────────────
--  MAP BLIP  (shown while trap mode is active)
-- ─────────────────────────────────────────────────────────────────
Config.ShowBlip   = true
Config.BlipSprite = 140
Config.BlipColor  = 1
Config.BlipScale  = 0.8
Config.BlipLabel  = 'Trap Spot'

-- ─────────────────────────────────────────────────────────────────
--  BUYER TYPES
--  Each type defines who shows up, what they want, how much they
--  pay, and how they behave. A random type is picked each spawn.
--
--  Fields per type:
--    label         display name (shown in notifications)
--    models        ped model pool (random pick)
--    preferredDrug item name this type prefers (nil = any random drug)
--    priceMultMin  multiplier applied to drug minPrice  (e.g. 0.8 = pays less)
--    priceMultMax  multiplier applied to drug maxPrice
--    minAmount     min units they want to buy
--    maxAmount     max units they want to buy
--    greetLines    lines shown as subtitle when they get in the car
--    walkStyle     movement clipset while approaching  (nil = default)
--    spawnOnFoot   true = walks up, false = always uses a vehicle approach
-- ─────────────────────────────────────────────────────────────────
Config.BuyerTypes = {

    -- ── Street Junkie ─────────────────────────────────────────────
    {
        label         = 'Street Junkie',
        models        = {
            'a_m_y_genstreet_01',
            'a_m_m_genstreet_01',
            'a_m_y_genstreet_02',
            'a_m_m_genstreet_02',
        },
        preferredDrug = 'meth10g',
        priceMultMin  = 0.7,
        priceMultMax  = 0.9,
        minAmount     = 1,
        maxAmount     = 2,
        greetLines    = {
            "Yo... you got that stuff? I need it bad man.",
            "Please tell me you got meth. I'm dying out here.",
            "Hook me up bro, I ain't slept in three days.",
            "Just give me something, anything. Please.",
        },
        walkStyle     = 'move_m@drunk@slightlydrunk',
        spawnOnFoot   = false,
    },

    -- ── College Kid ───────────────────────────────────────────────
    {
        label         = 'College Kid',
        models        = {
            'a_m_y_skater_01',
            'a_m_m_skater_01',
            'a_f_y_hipster_01',
            'a_f_y_hipster_02',
            'a_m_y_hipster_01',
            'a_m_y_hipster_02',
        },
        preferredDrug = 'weed20g',
        priceMultMin  = 1.0,
        priceMultMax  = 1.2,
        minAmount     = 1,
        maxAmount     = 3,
        greetLines    = {
            "Dude, you got the good stuff? My guy said you were legit.",
            "Okay so like... I just need a little weed for the weekend.",
            "Bro this is so sketchy lol. Just give me the weed.",
            "My roommate said you were the guy. You got weed right?",
        },
        walkStyle     = nil,
        spawnOnFoot   = false,
    },

    -- ── Rich Addict ───────────────────────────────────────────────
    {
        label         = 'Rich Addict',
        models        = {
            'a_m_m_business_01',
            'a_m_y_business_01',
            'a_m_y_business_02',
            'a_f_m_business_02',
            'a_m_m_business_02',
        },
        preferredDrug = 'coke10g',
        priceMultMin  = 1.3,
        priceMultMax  = 1.6,
        minAmount     = 2,
        maxAmount     = 4,
        greetLines    = {
            "I don't have all day. You have the coke or not?",
            "My associate said you were reliable. Don't disappoint me.",
            "I'll pay whatever. Just make it quick, I have a meeting.",
            "Look, I need the good stuff. None of that cut garbage.",
        },
        walkStyle     = nil,
        spawnOnFoot   = false,
    },

    -- ── Gang Member ───────────────────────────────────────────────
    {
        label         = 'Gang Member',
        models        = {
            'g_m_y_famdnf_01',
            'g_m_y_famca_01',
            'g_m_y_famfor_01',
            'a_m_y_mexthug_01',
            'g_m_y_mexgang_01',
            'g_m_y_ballaorig_01',
        },
        preferredDrug = nil,   -- buys anything
        priceMultMin  = 0.85,
        priceMultMax  = 1.05,
        minAmount     = 2,
        maxAmount     = 5,
        greetLines    = {
            "Aye, what you got? We need to re-up.",
            "My boys sent me. You holding?",
            "Don't waste my time. What's the ticket?",
            "Heard you got good product. Let's see it.",
        },
        walkStyle     = 'move_m@gangster@generic',
        spawnOnFoot   = false,
    },

    -- ── Biker ─────────────────────────────────────────────────────
    {
        label         = 'Biker',
        models        = {
            'g_m_y_lost_01',
            'g_m_y_lost_02',
            'g_m_m_lost_01',
            'g_m_m_lost_02',
            'a_m_m_biker_01',
        },
        preferredDrug = 'meth10g',
        priceMultMin  = 0.9,
        priceMultMax  = 1.1,
        minAmount     = 2,
        maxAmount     = 4,
        greetLines    = {
            "Chapter needs a re-up. You got the crystal?",
            "My boys are waiting. Make it fast.",
            "You the new connect? Alright, what you got?",
            "Don't short me. Last guy tried that didn't end well.",
        },
        walkStyle     = 'move_m@brave',
        spawnOnFoot   = false,
    },

    -- ── Desperate Housewife ───────────────────────────────────────
    {
        label         = 'Desperate Housewife',
        models        = {
            'a_f_m_bevhills_01',
            'a_f_m_bevhills_02',
            'a_f_y_bevhills_01',
            'a_f_y_bevhills_02',
            'a_f_m_business_02',
        },
        preferredDrug = 'xpills',
        priceMultMin  = 1.1,
        priceMultMax  = 1.4,
        minAmount     = 2,
        maxAmount     = 5,
        greetLines    = {
            "My doctor cut me off. You have the oxy right?",
            "Please, I just need a few pills. I'll pay anything.",
            "Don't judge me okay? Just... do you have oxy?",
            "My back is killing me. The pharmacy won't refill it.",
        },
        walkStyle     = nil,
        spawnOnFoot   = false,
    },

    -- ── Homeless Guy ──────────────────────────────────────────────
    {
        label         = 'Homeless Guy',
        models        = {
            'a_m_m_tramp_01',
            'a_m_y_tramp_01',
            'a_m_m_homeless_01',
        },
        preferredDrug = 'weed4g',
        priceMultMin  = 0.5,
        priceMultMax  = 0.75,
        minAmount     = 1,
        maxAmount     = 1,
        greetLines    = {
            "Hey man... I scraped together what I could. You got weed?",
            "Just a little bit bro. I got like twenty bucks.",
            "Come on man, hook a brother up. Just a little.",
            "I ain't got much but I'll pay what I can.",
        },
        walkStyle     = 'move_m@drunk@slightlydrunk',
        spawnOnFoot   = true,   -- always walks up, no car
    },

    -- ── Off-Duty Cop ──────────────────────────────────────────────
    -- Pays well but has a higher chance of triggering a police alert
    {
        label         = 'Off-Duty Cop',
        models        = {
            'a_m_m_business_01',
            'a_m_y_business_03',
            'a_m_m_farmer_01',
            'a_m_y_genstreet_01',
        },
        preferredDrug = 'coke10g',
        priceMultMin  = 1.2,
        priceMultMax  = 1.5,
        minAmount     = 1,
        maxAmount     = 2,
        policeAlertBonus = 40,  -- extra % added to police alert chance for this buyer
        greetLines    = {
            "Keep it cool. Just here for a personal purchase.",
            "Don't make this weird. You got coke?",
            "Nobody needs to know about this. You understand?",
            "Quick and quiet. That's how I like it.",
        },
        walkStyle     = nil,
        spawnOnFoot   = false,
    },

    -- ── Party Girl ────────────────────────────────────────────────
    {
        label         = 'Party Girl',
        models        = {
            'a_f_y_clubcust_01',
            'a_f_y_clubcust_02',
            'a_f_y_clubcust_03',
            'a_f_y_hipster_01',
            'a_f_y_soucal_01',
        },
        preferredDrug = 'coke10g',
        priceMultMin  = 1.0,
        priceMultMax  = 1.3,
        minAmount     = 1,
        maxAmount     = 3,
        greetLines    = {
            "Omg finally! My girls are waiting at the club.",
            "You're literally saving my night right now.",
            "Just need a little something for the party, you know?",
            "My friend said you were the guy. She was right!",
        },
        walkStyle     = nil,
        spawnOnFoot   = false,
    },

    -- ── Construction Worker ───────────────────────────────────────
    {
        label         = 'Construction Worker',
        models        = {
            's_m_y_construct_01',
            's_m_y_construct_02',
            's_m_m_construct_01',
            's_m_m_construct_02',
        },
        preferredDrug = 'meth10g',
        priceMultMin  = 0.9,
        priceMultMax  = 1.1,
        minAmount     = 1,
        maxAmount     = 3,
        greetLines    = {
            "Long shift man. You got anything to keep me going?",
            "Foreman's on my ass. Need something to stay awake.",
            "My buddy said you were out here. You got meth?",
            "Quick stop. Gotta get back to the site.",
        },
        walkStyle     = nil,
        spawnOnFoot   = false,
    },

    -- ── Lean Sipper ───────────────────────────────────────────────
    {
        label         = 'Lean Sipper',
        models        = {
            'a_m_y_genstreet_01',
            'a_m_y_genstreet_02',
            'g_m_y_famca_01',
            'g_m_y_famdnf_01',
        },
        preferredDrug = 'double_cup',
        priceMultMin  = 0.9,
        priceMultMax  = 1.2,
        minAmount     = 1,
        maxAmount     = 3,
        greetLines    = {
            "Aye you got them cups? I'm tryna sip tonight.",
            "My boy said you got that lean. What's the ticket?",
            "I need like two cups bro. You holding?",
            "Don't play me. You got the double cup or not?",
        },
        walkStyle     = 'move_m@drunk@slightlydrunk',
        spawnOnFoot   = false,
    },

    -- ── Heroin Addict ─────────────────────────────────────────────
    {
        label         = 'Heroin Addict',
        models        = {
            'a_m_m_tramp_01',
            'a_m_y_tramp_01',
            'a_m_y_genstreet_01',
            'a_m_m_genstreet_02',
        },
        preferredDrug = 'blacktar',
        priceMultMin  = 0.6,
        priceMultMax  = 0.85,
        minAmount     = 1,
        maxAmount     = 2,
        greetLines    = {
            "Please man... I need the tar. I'm sick without it.",
            "You got black? I'll pay whatever you want.",
            "I can't function right now. You got the tar?",
            "Just a little bit. I'm not doing good man.",
        },
        walkStyle     = 'move_m@drunk@slightlydrunk',
        spawnOnFoot   = true,
    },

    -- ── Pill Popper ───────────────────────────────────────────────
    {
        label         = 'Pill Popper',
        models        = {
            'a_f_y_bevhills_01',
            'a_f_m_bevhills_02',
            'a_m_y_business_02',
            'a_m_m_business_01',
        },
        preferredDrug = 'xpills',
        priceMultMin  = 1.0,
        priceMultMax  = 1.3,
        minAmount     = 2,
        maxAmount     = 6,
        greetLines    = {
            "You got the X? I need like four for the weekend.",
            "My plug dried up. Someone said you had pills.",
            "Don't short me on the count. I'll know.",
            "Festival's this weekend. I need the good ones.",
        },
        walkStyle     = nil,
        spawnOnFoot   = false,
    },

    -- ── Spice Head ────────────────────────────────────────────────
    {
        label         = 'Spice Head',
        models        = {
            'a_m_m_tramp_01',
            'a_m_y_tramp_01',
            'a_m_m_homeless_01',
            'a_m_y_genstreet_02',
        },
        preferredDrug = 'spice_pooch',
        priceMultMin  = 0.5,
        priceMultMax  = 0.8,
        minAmount     = 1,
        maxAmount     = 3,
        greetLines    = {
            "You got spice? I just need a pouch man.",
            "Bro hook me up with the spice. I'm broke but I got something.",
            "Just the spice. That's all I need right now.",
            "You holding spice? My guy ran out.",
        },
        walkStyle     = 'move_m@drunk@verydrunk',
        spawnOnFoot   = true,
    },
}

-- ─────────────────────────────────────────────────────────────────
--  DRUGS
--  item        = inventory item name (must match your items.lua)
--  label       = display name shown in sell menu
--  minPrice /
--  maxPrice    = random cash payout per unit sold
--  minAmount /
--  maxAmount   = random quantity the buyer wants
-- ─────────────────────────────────────────────────────────────────
Config.Drugs = {
    -- ── Weed ──────────────────────────────────────────────────────
    {
        item      = 'weedbrick',
        label     = 'Weed Brick (200G)',
        minPrice  = 300,
        maxPrice  = 600,
        minAmount = 1,
        maxAmount = 2,
    },
    {
        item      = 'weed20g',
        label     = 'Weed (20G)',
        minPrice  = 60,
        maxPrice  = 120,
        minAmount = 1,
        maxAmount = 4,
    },
    {
        item      = 'weed4g',
        label     = 'Weed (4G)',
        minPrice  = 15,
        maxPrice  = 35,
        minAmount = 1,
        maxAmount = 6,
    },
    {
        item      = 'joint2g',
        label     = 'Joint (2G)',
        minPrice  = 10,
        maxPrice  = 25,
        minAmount = 1,
        maxAmount = 5,
    },
    {
        item      = 'weed_pooch',
        label     = 'Weed Pouch',
        minPrice  = 40,
        maxPrice  = 80,
        minAmount = 1,
        maxAmount = 3,
    },
    {
        item      = 'shroom_pouch',
        label     = 'Shroom Pouch',
        minPrice  = 60,
        maxPrice  = 130,
        minAmount = 1,
        maxAmount = 3,
    },
    -- ── Coke / Crack ──────────────────────────────────────────────
    {
        item      = 'coke10g',
        label     = 'Cocaine (10G)',
        minPrice  = 200,
        maxPrice  = 450,
        minAmount = 1,
        maxAmount = 3,
    },
    {
        item      = 'crack_pouch',
        label     = 'Crack Pouch',
        minPrice  = 120,
        maxPrice  = 260,
        minAmount = 1,
        maxAmount = 4,
    },
    -- ── Meth ──────────────────────────────────────────────────────
    {
        item      = 'meth10g',
        label     = 'Meth (10G)',
        minPrice  = 150,
        maxPrice  = 300,
        minAmount = 1,
        maxAmount = 3,
    },
    {
        item      = 'meth_pooch',
        label     = 'Meth Pouch',
        minPrice  = 80,
        maxPrice  = 160,
        minAmount = 1,
        maxAmount = 3,
    },
    {
        item      = 'flakka',
        label     = 'Flakka',
        minPrice  = 90,
        maxPrice  = 180,
        minAmount = 1,
        maxAmount = 4,
    },
    {
        item      = 'mdp2p',
        label     = 'MDP2P',
        minPrice  = 200,
        maxPrice  = 400,
        minAmount = 1,
        maxAmount = 2,
    },
    -- ── Spice ─────────────────────────────────────────────────────
    {
        item      = 'spice_pooch',
        label     = 'Spice Pouch',
        minPrice  = 30,
        maxPrice  = 70,
        minAmount = 1,
        maxAmount = 4,
    },
    -- ── Pills / Lean / Sizzurp ────────────────────────────────────
    {
        item      = 'xpills',
        label     = 'X Pills',
        minPrice  = 80,
        maxPrice  = 160,
        minAmount = 1,
        maxAmount = 5,
    },
    {
        item      = 'molly_pouch',
        label     = 'Molly Pouch',
        minPrice  = 100,
        maxPrice  = 200,
        minAmount = 1,
        maxAmount = 4,
    },
    {
        item      = 'perc_pouch',
        label     = 'Perc Pouch',
        minPrice  = 90,
        maxPrice  = 180,
        minAmount = 1,
        maxAmount = 5,
    },
    {
        item      = 'vicodin',
        label     = 'Vicodin',
        minPrice  = 50,
        maxPrice  = 110,
        minAmount = 1,
        maxAmount = 6,
    },
    {
        item      = 'reddextro',
        label     = 'Red Dextro',
        minPrice  = 40,
        maxPrice  = 90,
        minAmount = 1,
        maxAmount = 6,
    },
    {
        item      = 'double_cup',
        label     = 'Double Cup',
        minPrice  = 50,
        maxPrice  = 100,
        minAmount = 1,
        maxAmount = 3,
    },
    {
        item      = 'sizzurup',
        label     = 'Sizzurp',
        minPrice  = 60,
        maxPrice  = 120,
        minAmount = 1,
        maxAmount = 3,
    },
    -- ── Opioids / Heroin ──────────────────────────────────────────
    {
        item      = 'blacktar',
        label     = 'Black Tar',
        minPrice  = 120,
        maxPrice  = 250,
        minAmount = 1,
        maxAmount = 2,
    },
    {
        item      = 'morphine',
        label     = 'Morphine',
        minPrice  = 150,
        maxPrice  = 300,
        minAmount = 1,
        maxAmount = 3,
    },
    {
        item      = 'opium_pouch',
        label     = 'Opium Pouch',
        minPrice  = 130,
        maxPrice  = 270,
        minAmount = 1,
        maxAmount = 3,
    },
    -- ── Speedball (Coke + Heroin mix) ─────────────────────────────
    {
        item      = 'speedball',
        label     = 'Speedball',
        minPrice  = 250,
        maxPrice  = 500,
        minAmount = 1,
        maxAmount = 2,
    },
    -- ── Weed edibles (can be sold to buyers) ──────────────────────
    {
        item      = 'edible_gummy',
        label     = 'Gummy Bears (10mg)',
        minPrice  = 20,
        maxPrice  = 50,
        minAmount = 2,
        maxAmount = 6,
    },
    {
        item      = 'edible_brownie',
        label     = 'Space Brownie (50mg)',
        minPrice  = 40,
        maxPrice  = 90,
        minAmount = 1,
        maxAmount = 3,
    },
    {
        item      = 'edible_cookie',
        label     = 'Cookie (25mg)',
        minPrice  = 25,
        maxPrice  = 60,
        minAmount = 1,
        maxAmount = 4,
    },
    {
        item      = 'blunt5g',
        label     = 'Blunt (5G)',
        minPrice  = 20,
        maxPrice  = 45,
        minAmount = 1,
        maxAmount = 5,
    },
}

-- ─────────────────────────────────────────────────────────────────
--  POLICE ALERTS
-- ─────────────────────────────────────────────────────────────────
Config.PoliceAlertChance = 15   -- 0–100 percent chance per sale
Config.MinPoliceForAlert = 1    -- minimum on-duty officers needed to fire alert

-- Police job names to check (add sheriff, bcso, etc. if needed)
Config.PoliceJobs = { 'police', 'sheriff', 'bcso' }

-- ─────────────────────────────────────────────────────────────────
--  COP PATROL SYSTEM
--  While trap mode is active, NPC cop cars periodically cruise past.
--  If the player is mid-sale when a cop passes, there is a chance
--  the cop stops, gets out, and investigates — triggering heat.
-- ─────────────────────────────────────────────────────────────────
Config.CopPatrolEnabled    = true   -- set false to disable entirely
Config.CopPatrolInterval   = { min = 45, max = 120 }  -- seconds between patrols
Config.CopStopChance       = 30     -- 0–100 % chance cop stops if player is mid-sale
Config.CopInvestigateChance = 20    -- 0–100 % chance cop calls it in after stopping
Config.CopSpawnDistance    = 80.0   -- metres away the cop car spawns
Config.CopDriveSpeed       = 12.0   -- cruising speed (~27mph, realistic patrol)
Config.CopWatchTime        = 8000   -- ms the cop sits and watches before deciding

-- Cop car models
Config.CopVehicles = {
    'police',
    'police2',
    'police3',
    'policeb',   -- police bike — adds variety
}

-- Cop ped models
Config.CopModels = {
    's_m_y_cop_01',
    's_f_y_cop_01',
    's_m_y_hwaycop_01',
}

-- ─────────────────────────────────────────────────────────────────
--  NPC ANGER SYSTEM
--  When the buyer has no stock of what they want, they get angry.
--  There is a chance they get out of the car and fight the player.
-- ─────────────────────────────────────────────────────────────────
Config.BuyerAngryFightChance = 60   -- 0–100 percent chance the angry buyer fights instead of leaving

-- Lines the NPC shouts when they find out you don't have their drug
-- %s is replaced with the drug label they wanted
Config.AngryLines = {
    "Yo what the hell?! You said you had %s!",
    "Bro I came all the way out here for %s and you got NOTHING?!",
    "Man you wasting my time! Where's the %s?!",
    "You playing games? I need that %s NOW.",
    "This is a joke right? No %s? Are you serious?!",
    "I don't got time for this. You said you had %s!",
}

-- ─────────────────────────────────────────────────────────────────
--  ROB SYSTEM
--  After a sale there is a chance a robber NPC drives up in a car,
--  gets out, and robs the player of their drugs AND cash.
-- ─────────────────────────────────────────────────────────────────
Config.RobChance        = 25    -- 0–100 percent chance a rob attempt fires after each sale
Config.RobCashPercent   = 75    -- percent of player cash stolen (1–100)
Config.RobDrugAmount    = 2     -- max units of each drug stolen per rob
Config.RobDrunkDuration = 15    -- seconds the drunk effect lasts after being robbed

-- Bleed effect (triggered after stab during rob)
Config.BleedDuration    = 30    -- seconds the bleed lasts
Config.BleedDamage      = 3     -- health points drained per bleed tick
Config.BleedInterval    = 2000  -- ms between each bleed tick

-- How far away the robber vehicle spawns (metres)
Config.RobSpawnDistance = 60.0

-- Ped models used for the robber
Config.RobberModels = {
    'g_m_y_lost_01',
    'g_m_y_ballaorig_01',
    'g_m_y_mexgang_01',
    'g_m_y_famdnf_01',
    'g_m_m_chicold_01',
}

-- ─────────────────────────────────────────────────────────────────
--  SELL MODES
--  'car'    — NPC gets in passenger seat (original)
--  'window' — NPC walks to driver window, player leans out
--  'foot'   — Player on foot, NPC walks up to them
--  Use /trap car | /trap window | /trap foot  to select mode
-- ─────────────────────────────────────────────────────────────────
Config.DefaultSellMode = 'car'   -- default mode on /trap

-- ─────────────────────────────────────────────────────────────────
--  ON-FOOT ROB SYSTEM
--  When selling on foot there is a chance two armed NPCs roll up
--  and rob the player at gunpoint.
-- ─────────────────────────────────────────────────────────────────
Config.FootRobChance      = 35    -- 0–100 % chance per foot sale
Config.FootRobberCount    = 2     -- always 2 robbers on foot
Config.FootRobberModels   = {
    'g_m_y_ballaorig_01',
    'g_m_y_famdnf_01',
    'g_m_y_mexgang_01',
    'g_m_y_lost_01',
    'g_m_m_chicold_01',
}
Config.FootRobberWeapons  = {
    GetHashKey('WEAPON_PISTOL'),
    GetHashKey('WEAPON_MICROSMG'),
    GetHashKey('WEAPON_SAWNOFFSHOTGUN'),
}

-- ─────────────────────────────────────────────────────────────────
--  KILL ROBBER / LOOT SYSTEM
-- ─────────────────────────────────────────────────────────────────
Config.LootWindowTime   = 60    -- seconds player has to loot the robber's body
Config.KillRobberWanted = 2     -- wanted stars added when player kills the robber
Config.LootKey          = 51    -- GTA control index — 51 = E key (same as sell key)

-- Vehicle models the robber arrives in
Config.RobberVehicles = {
    'sultan',
    'kuruma',
    'buffalo',
    'dominator',
    'gauntlet',
}

-- ─────────────────────────────────────────────────────────────────
--  DRUG USE & ADDICTION SYSTEM
--
--  Players can use /use [drugItem] to consume drugs they carry.
--  Each use increases addiction level. Addiction causes withdrawal
--  debuffs that worsen over time. Hospital cures addiction for a fee.
--
--  Addiction levels:
--    0 = Clean
--    1 = Hooked    (mild effects)
--    2 = Dependent (moderate effects)
--    3 = Strung Out (severe effects)
-- ─────────────────────────────────────────────────────────────────
Config.DrugUseCommand   = 'use'       -- /use [item]  e.g. /use joint2g
Config.AddictionSaveKey = 'zj_addiction'  -- key used in persistent storage

-- How many uses before addiction level increases
Config.AddictionThreshold = {
    [1] = 5,    -- 5 uses to become Hooked
    [2] = 12,   -- 12 total uses to become Dependent
    [3] = 22,   -- 22 total uses to become Strung Out
}

-- Withdrawal tick interval (ms) — how often debuffs are applied when not using
Config.WithdrawalInterval = 30000   -- every 30 seconds

-- How long (seconds) before alien attack triggers if untreated at level 3
Config.AlienAttackDelay   = 360     -- 6 minutes

-- Hospital cure cost per addiction level
Config.HospitalCureCost = {
    [1] = 500,
    [2] = 1500,
    [3] = 4000,
}

-- Hospital interaction distance (metres)
Config.HospitalRadius = 5.0

-- Sandy Shores Medical Center coords (change to your server's hospital)
Config.HospitalCoords = { x = 1839.0, y = 3672.0, z = 34.3 }

-- ─────────────────────────────────────────────────────────────────
--  SMOKEABLE / USEABLE DRUGS
--  item         = inventory item name
--  label        = display name
--  animDict     = animation dictionary for the use animation
--  animName     = animation clip name
--  animDuration = ms the animation plays
--  effect       = screen/gameplay effect applied on use
--    type: 'weed' | 'meth' | 'coke' | 'lean' | 'pill' | 'tar'
--  healthBoost  = HP added on use (0 = none)
--  staminaBoost = true = restores stamina
--  addictionAdd = how much this adds to the use counter per use
-- ─────────────────────────────────────────────────────────────────
Config.UseableDrugs = {
    {
        item         = 'joint2g',
        label        = 'Joint (2G)',
        animDict     = 'amb@world_human_smoking@male@idle_a',
        animName     = 'idle_a',
        animDuration = 6000,
        effect       = 'weed',
        healthBoost  = 0,
        staminaBoost = false,
        addictionAdd = 1,
    },
    {
        item         = 'weed4g',
        label        = 'Weed (4G)',
        animDict     = 'amb@world_human_smoking@male@idle_a',
        animName     = 'idle_a',
        animDuration = 5000,
        effect       = 'weed',
        healthBoost  = 0,
        staminaBoost = false,
        addictionAdd = 1,
    },
    {
        item         = 'meth10g',
        label        = 'Meth (10G)',
        animDict     = 'amb@world_human_smoking@male@idle_a',
        animName     = 'idle_a',
        animDuration = 4000,
        effect       = 'meth',
        healthBoost  = 10,
        staminaBoost = true,
        addictionAdd = 2,
    },
    {
        item         = 'coke10g',
        label        = 'Cocaine (10G)',
        animDict     = 'switch@trevor@trev_smoking_meth',
        animName     = 'trev_smoking_meth_loop',
        animDuration = 4000,
        effect       = 'coke',
        healthBoost  = 5,
        staminaBoost = true,
        addictionAdd = 2,
    },
    {
        item         = 'double_cup',
        label        = 'Double Cup',
        animDict     = 'amb@world_human_drinking@beer@male@idle_a',
        animName     = 'idle_a',
        animDuration = 5000,
        effect       = 'lean',
        healthBoost  = 0,
        staminaBoost = false,
        addictionAdd = 1,
    },
    {
        item         = 'xpills',
        label        = 'X Pills',
        animDict     = 'mp_player_inteat@pills',
        animName     = 'loop',
        animDuration = 3000,
        effect       = 'pill',
        healthBoost  = 15,
        staminaBoost = true,
        addictionAdd = 2,
    },
    {
        item         = 'blacktar',
        label        = 'Black Tar',
        animDict     = 'amb@world_human_smoking@male@idle_a',
        animName     = 'idle_a',
        animDuration = 6000,
        effect       = 'tar',
        healthBoost  = 0,
        staminaBoost = false,
        addictionAdd = 3,
    },
    {
        item         = 'spice_pooch',
        label        = 'Spice Pouch',
        animDict     = 'amb@world_human_smoking@male@idle_a',
        animName     = 'idle_a',
        animDuration = 5000,
        effect       = 'weed',
        healthBoost  = 0,
        staminaBoost = false,
        addictionAdd = 2,
    },
    -- ── Blunts ────────────────────────────────────────────────────
    {
        item         = 'blunt5g',
        label        = 'Blunt (5G)',
        animDict     = 'amb@world_human_smoking@male@idle_a',
        animName     = 'idle_a',
        animDuration = 8000,
        effect       = 'weed',
        healthBoost  = 0,
        staminaBoost = false,
        addictionAdd = 1,
    },
    -- ── Edibles ───────────────────────────────────────────────────
    {
        item         = 'edible_gummy',
        label        = 'Gummy Bears (10mg)',
        animDict     = 'mp_player_inteat@burger',
        animName     = 'loop',
        animDuration = 3000,
        effect       = 'weed',
        healthBoost  = 5,
        staminaBoost = false,
        addictionAdd = 1,
    },
    {
        item         = 'edible_brownie',
        label        = 'Space Brownie (50mg)',
        animDict     = 'mp_player_inteat@burger',
        animName     = 'loop',
        animDuration = 3500,
        effect       = 'lean',   -- stronger effect — woozy
        healthBoost  = 10,
        staminaBoost = false,
        addictionAdd = 2,
    },
    {
        item         = 'edible_cookie',
        label        = 'Cookie (25mg)',
        animDict     = 'mp_player_inteat@burger',
        animName     = 'loop',
        animDuration = 3000,
        effect       = 'weed',
        healthBoost  = 8,
        staminaBoost = false,
        addictionAdd = 1,
    },
    {
        item         = 'edible_drink',
        label        = 'Infused Drink (20mg)',
        animDict     = 'amb@world_human_drinking@beer@male@idle_a',
        animName     = 'idle_a',
        animDuration = 4000,
        effect       = 'weed',
        healthBoost  = 5,
        staminaBoost = false,
        addictionAdd = 1,
    },
    -- ── All remaining drugs ───────────────────────────────────────
    { item='weed_pooch',   label='Weed Pouch',       animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=5000, effect='weed', healthBoost=0,  staminaBoost=false, addictionAdd=1 },
    { item='weedbrick',    label='Weed Brick',        animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=5000, effect='weed', healthBoost=0,  staminaBoost=false, addictionAdd=1 },
    { item='weed20g',      label='Weed (20G)',         animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=5000, effect='weed', healthBoost=0,  staminaBoost=false, addictionAdd=1 },
    { item='shroom_pouch', label='Shroom Pouch',       animDict='mp_player_inteat@burger',                   animName='loop',                animDuration=3500, effect='pill', healthBoost=0,  staminaBoost=false, addictionAdd=2 },
    { item='crack_pouch',  label='Crack Pouch',        animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=4000, effect='coke', healthBoost=5,  staminaBoost=true,  addictionAdd=3 },
    { item='meth_pooch',   label='Meth Pouch',         animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=4000, effect='meth', healthBoost=5,  staminaBoost=true,  addictionAdd=2 },
    { item='flakka',       label='Flakka',             animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=3500, effect='meth', healthBoost=0,  staminaBoost=true,  addictionAdd=3 },
    { item='mdp2p',        label='MDP2P',              animDict='switch@trevor@trev_smoking_meth',            animName='trev_smoking_meth_loop', animDuration=4000, effect='meth', healthBoost=0, staminaBoost=true, addictionAdd=3 },
    { item='spice_pooch',  label='Spice Pouch',        animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=5000, effect='weed', healthBoost=0,  staminaBoost=false, addictionAdd=2 },
    { item='molly_pouch',  label='Molly Pouch',        animDict='mp_player_inteat@pills',                    animName='loop',                animDuration=3000, effect='pill', healthBoost=10, staminaBoost=true,  addictionAdd=2 },
    { item='perc_pouch',   label='Perc Pouch',         animDict='mp_player_inteat@pills',                    animName='loop',                animDuration=3000, effect='tar',  healthBoost=5,  staminaBoost=false, addictionAdd=2 },
    { item='vicodin',      label='Vicodin',            animDict='mp_player_inteat@pills',                    animName='loop',                animDuration=3000, effect='tar',  healthBoost=8,  staminaBoost=false, addictionAdd=2 },
    { item='reddextro',    label='Red Dextro',         animDict='mp_player_inteat@pills',                    animName='loop',                animDuration=3000, effect='pill', healthBoost=5,  staminaBoost=false, addictionAdd=1 },
    { item='sizzurup',     label='Sizzurp',            animDict='amb@world_human_drinking@beer@male@idle_a',  animName='idle_a',              animDuration=5000, effect='lean', healthBoost=0,  staminaBoost=false, addictionAdd=2 },
    { item='morphine',     label='Morphine',           animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=5000, effect='tar',  healthBoost=10, staminaBoost=false, addictionAdd=3 },
    { item='opium_pouch',  label='Opium Pouch',        animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=5000, effect='tar',  healthBoost=5,  staminaBoost=false, addictionAdd=3 },
    { item='speedball',    label='Speedball',          animDict='switch@trevor@trev_smoking_meth',            animName='trev_smoking_meth_loop', animDuration=4000, effect='coke', healthBoost=15, staminaBoost=true, addictionAdd=4 },
    { item='blunt5g',      label='Blunt (5G)',         animDict='amb@world_human_smoking@male@idle_a',        animName='idle_a',              animDuration=8000, effect='weed', healthBoost=0,  staminaBoost=false, addictionAdd=1 },
    { item='edible_gummy', label='Gummy Bears',        animDict='mp_player_inteat@burger',                   animName='loop',                animDuration=3000, effect='weed', healthBoost=5,  staminaBoost=false, addictionAdd=1 },
    { item='edible_brownie',label='Space Brownie',     animDict='mp_player_inteat@burger',                   animName='loop',                animDuration=3500, effect='lean', healthBoost=10, staminaBoost=false, addictionAdd=2 },
    { item='edible_cookie',label='Cookie (25mg)',      animDict='mp_player_inteat@burger',                   animName='loop',                animDuration=3000, effect='weed', healthBoost=8,  staminaBoost=false, addictionAdd=1 },
}

-- ─────────────────────────────────────────────────────────────────
--  TRUNK / CRAFTING SYSTEM
--  When on foot near your vehicle, look at the trunk (third eye)
--  to open a menu: craft drugs, sell from trunk, or just open it.
--
--  Recipes:
--    ingredients = { { item, amount }, ... }  — what gets consumed
--    output      = item name produced
--    outputAmt   = how many you get per craft
--    label       = display name in menu
--    animDict /
--    animName    = animation played while crafting
--    craftTime   = ms the craft takes
-- ─────────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────
--  TARGET SYSTEM
--  Auto-detects ox_target or qb-target.
--  Used for: trunk lab, weed store, YouTools.
-- ─────────────────────────────────────────────────────────────────
Config.TargetSystem = 'auto'   -- 'auto' | 'ox' | 'qb'

Config.CraftRecipes = {
    -- ── Roll a Joint ──────────────────────────────────────────────
    {
        label      = 'Roll a Joint (2G)',
        output     = 'joint2g',
        outputAmt  = 1,
        craftTime  = 5000,
        animDict   = 'amb@world_human_smoking@male@idle_a',
        animName   = 'idle_a',
        ingredients = {
            { item = 'weed4g',   amount = 1 },
            { item = 'rolpaper', amount = 1 },
        },
    },
    -- ── Pack Weed Pouch ───────────────────────────────────────────
    {
        label      = 'Pack Weed Pouch',
        output     = 'weed_pooch',
        outputAmt  = 1,
        craftTime  = 6000,
        animDict   = 'amb@world_human_smoking@male@idle_a',
        animName   = 'idle_a',
        ingredients = {
            { item = 'weed20g', amount = 1 },
        },
    },
    -- ── Pack Meth Pouch ───────────────────────────────────────────
    {
        label      = 'Pack Meth Pouch',
        output     = 'meth_pooch',
        outputAmt  = 1,
        craftTime  = 6000,
        animDict   = 'amb@world_human_smoking@male@idle_a',
        animName   = 'idle_a',
        ingredients = {
            { item = 'meth10g', amount = 1 },
        },
    },
    -- ── Pack Spice Pouch ──────────────────────────────────────────
    {
        label      = 'Pack Spice Pouch',
        output     = 'spice_pooch',
        outputAmt  = 1,
        craftTime  = 6000,
        animDict   = 'amb@world_human_smoking@male@idle_a',
        animName   = 'idle_a',
        ingredients = {
            { item = 'spice_pooch', amount = 1 },
        },
    },
    -- ── Mix Double Cup ────────────────────────────────────────────
    {
        label      = 'Mix Double Cup',
        output     = 'double_cup',
        outputAmt  = 1,
        craftTime  = 4000,
        animDict   = 'amb@world_human_drinking@beer@male@idle_a',
        animName   = 'idle_a',
        ingredients = {
            { item = 'xpills', amount = 1 },
        },
    },
    -- ── Break Down Weed Brick ─────────────────────────────────────
    {
        label      = 'Break Down Weed Brick → 20G bags',
        output     = 'weed20g',
        outputAmt  = 10,
        craftTime  = 8000,
        animDict   = 'amb@world_human_smoking@male@idle_a',
        animName   = 'idle_a',
        ingredients = {
            { item = 'weedbrick', amount = 1 },
        },
    },
}

-- ─────────────────────────────────────────────────────────────────
--  BURNER PHONE / DELIVERY SYSTEM
--
--  Player uses /phone to open their burner phone contact list.
--  Each contact places a delivery order for a specific drug.
--  Player drives to the delivery marker and presses E to drop off.
--
--  Delivery types:
--    'home'   — residential area, low heat, moderate pay
--    'office' — business district, moderate heat, good pay
--    'corner' — street corner, high heat, fast turnaround
--    'hotel'  — hotel room, low heat, high pay, longer drive
-- ─────────────────────────────────────────────────────────────────
Config.PhoneCommand       = 'phone'    -- /phone to open burner phone
Config.DeliveryKey        = 51         -- E key to complete delivery
Config.DeliveryRadius     = 4.0        -- metres to trigger delivery prompt
Config.PhoneInterceptChance = 8        -- 0–100 % chance cops intercept per call made
Config.MaxActiveDeliveries  = 1        -- only one delivery at a time

-- Contacts on the burner phone
Config.BurnerContacts = {
    {
        name        = 'Big Mike',
        number      = '555-0142',
        type        = 'corner',
        description = 'Corner boy. Needs small amounts fast.',
        drug        = 'weed4g',
        drugLabel   = 'Weed (4G)',
        minAmount   = 2,
        maxAmount   = 5,
        minPay      = 80,
        maxPay      = 150,
        timeLimit   = 300,    -- seconds to complete
        heatChance  = 25,     -- extra police alert % for this contact
    },
    {
        name        = 'Lisa H.',
        number      = '555-0198',
        type        = 'home',
        description = 'Suburban housewife. Discreet, pays well.',
        drug        = 'xpills',
        drugLabel   = 'X Pills',
        minAmount   = 3,
        maxAmount   = 6,
        minPay      = 200,
        maxPay      = 400,
        timeLimit   = 480,
        heatChance  = 10,
    },
    {
        name        = 'D. Reeves',
        number      = '555-0231',
        type        = 'office',
        description = 'Downtown exec. Coke only, no exceptions.',
        drug        = 'coke10g',
        drugLabel   = 'Cocaine (10G)',
        minAmount   = 2,
        maxAmount   = 4,
        minPay      = 350,
        maxPay      = 700,
        timeLimit   = 420,
        heatChance  = 15,
    },
    {
        name        = 'Lil Smoke',
        number      = '555-0077',
        type        = 'corner',
        description = 'Young hustler. Weed and joints only.',
        drug        = 'joint2g',
        drugLabel   = 'Joint (2G)',
        minAmount   = 5,
        maxAmount   = 10,
        minPay      = 60,
        maxPay      = 120,
        timeLimit   = 240,
        heatChance  = 20,
    },
    {
        name        = 'T-Bone',
        number      = '555-0315',
        type        = 'corner',
        description = 'Biker connect. Meth re-up.',
        drug        = 'meth10g',
        drugLabel   = 'Meth (10G)',
        minAmount   = 2,
        maxAmount   = 4,
        minPay      = 250,
        maxPay      = 500,
        timeLimit   = 360,
        heatChance  = 20,
    },
    {
        name        = 'Room 214',
        number      = '555-0409',
        type        = 'hotel',
        description = 'Hotel guest. Lean and pills. No questions.',
        drug        = 'double_cup',
        drugLabel   = 'Double Cup',
        minAmount   = 2,
        maxAmount   = 4,
        minPay      = 180,
        maxPay      = 320,
        timeLimit   = 540,
        heatChance  = 8,
    },
    {
        name        = 'Pops',
        number      = '555-0522',
        type        = 'home',
        description = 'Old head. Black tar, cash on delivery.',
        drug        = 'blacktar',
        drugLabel   = 'Black Tar',
        minAmount   = 1,
        maxAmount   = 2,
        minPay      = 300,
        maxPay      = 550,
        timeLimit   = 600,
        heatChance  = 12,
    },
    {
        name        = 'Spice King',
        number      = '555-0633',
        type        = 'corner',
        description = 'Moves spice pouches. Volume buyer.',
        drug        = 'spice_pooch',
        drugLabel   = 'Spice Pouch',
        minAmount   = 3,
        maxAmount   = 6,
        minPay      = 90,
        maxPay      = 180,
        timeLimit   = 300,
        heatChance  = 18,
    },
}

-- Delivery drop-off locations per type
-- Each type has a pool of coords — one is picked randomly per order
Config.DeliveryLocations = {
    home = {
        { x = 289.8,   y = -956.0,  z = 29.4,  label = 'Vinewood Hills House'    },
        { x = -1216.0, y = -1571.0, z = 4.4,   label = 'Strawberry Apartment'    },
        { x = 126.5,   y = -1956.0, z = 21.0,  label = 'Davis Residence'         },
        { x = 372.0,   y = -1611.0, z = 29.3,  label = 'Chamberlain Hills House' },
    },
    office = {
        { x = -141.0,  y = -620.0,  z = 168.8, label = 'Maze Bank Tower Lobby'   },
        { x = 315.0,   y = -700.0,  z = 29.3,  label = 'Downtown Office Block'   },
        { x = -547.0,  y = -200.0,  z = 37.9,  label = 'Rockford Hills Office'   },
    },
    corner = {
        { x = 135.0,   y = -1952.0, z = 21.0,  label = 'Davis Corner'            },
        { x = 392.0,   y = -1600.0, z = 29.3,  label = 'Chamberlain Corner'      },
        { x = -1097.0, y = -1570.0, z = 4.4,   label = 'Strawberry Corner'       },
        { x = 1209.0,  y = -1402.0, z = 35.2,  label = 'Cypress Flats Corner'    },
    },
    hotel = {
        { x = -1221.0, y = -330.0,  z = 37.8,  label = 'Richman Hotel'           },
        { x = 135.0,   y = -1285.0, z = 29.2,  label = 'Downtown Motel'          },
        { x = -1044.0, y = -2745.0, z = 21.3,  label = 'Airport Motel'           },
    },
}

-- ─────────────────────────────────────────────────────────────────
--  WEED DISPENSARY — "THE COOKIE JAR"
--  All-weed store: flower, blunts, joints, pre-rolls, edibles,
--  lighters. Located where the Cookies dispensary sits in FiveM
--  (Rockford Hills / Vinewood area, near the clothing stores).
-- ─────────────────────────────────────────────────────────────────
Config.WeedStoreCommand = 'dispensary'  -- /dispensary to open
Config.WeedStoreRadius  = 4.0           -- metres to trigger prompt

-- All Cookie Jar locations — each gets a blip on the map
Config.WeedStoreLocations = {
    { x = -1290.0, y = -280.0,  z = 37.5,  label = 'The Cookie Jar — Rockford Hills' },
    { x = -1222.0, y = -905.0,  z = 12.3,  label = 'The Cookie Jar — Vespucci'       },
    { x = 372.0,   y = 328.0,   z = 103.6, label = 'The Cookie Jar — Vinewood'       },
    { x = -47.0,   y = -1757.0, z = 29.4,  label = 'The Cookie Jar — South LS'       },
    { x = 1161.0,  y = -322.0,  z = 69.2,  label = 'The Cookie Jar — Sandy Shores'   },
}

-- Full product catalogue
Config.WeedStoreItems = {
    -- ── Flower ────────────────────────────────────────────────────
    {
        item        = 'weed4g',
        label       = 'Flower (4G)',
        price       = 25,
        description = 'Small personal bag of flower',
        category    = 'flower',
    },
    {
        item        = 'weed20g',
        label       = 'Flower (20G)',
        price       = 90,
        description = 'Larger bag — better value',
        category    = 'flower',
    },
    {
        item        = 'weedbrick',
        label       = 'Weed Brick (200G)',
        price       = 750,
        description = 'Bulk brick — serious buyers only',
        category    = 'flower',
    },
    {
        item        = 'weed_pooch',
        label       = 'Weed Pouch',
        price       = 60,
        description = 'Sealed smell-proof pouch, 20G',
        category    = 'flower',
    },
    -- ── Pre-Rolls & Blunts ────────────────────────────────────────
    {
        item        = 'joint2g',
        label       = 'Pre-Roll Joint (2G)',
        price       = 30,
        description = 'Ready to spark, no prep needed',
        category    = 'preroll',
    },
    {
        item        = 'blunt5g',
        label       = 'Blunt (5G)',
        price       = 55,
        description = 'Tobacco wrap, slow burn',
        category    = 'preroll',
    },
    {
        item        = 'blunt_pack',
        label       = 'Blunt Pack (5-pack)',
        price       = 220,
        description = 'Five blunts, bulk discount',
        category    = 'preroll',
    },
    {
        item        = 'preroll_pack',
        label       = 'Pre-Roll Pack (5-pack)',
        price       = 120,
        description = 'Five joints, ready to go',
        category    = 'preroll',
    },
    -- ── Edibles ───────────────────────────────────────────────────
    {
        item        = 'edible_gummy',
        label       = 'Gummy Bears (10mg)',
        price       = 40,
        description = 'Slow onset, long lasting',
        category    = 'edible',
    },
    {
        item        = 'edible_brownie',
        label       = 'Space Brownie (50mg)',
        price       = 80,
        description = 'Strong — eat half first',
        category    = 'edible',
    },
    {
        item        = 'edible_cookie',
        label       = 'Cookie (25mg)',
        price       = 50,
        description = 'Classic. You know what it is.',
        category    = 'edible',
    },
    {
        item        = 'edible_drink',
        label       = 'Infused Drink (20mg)',
        price       = 35,
        description = 'Sparkling cannabis beverage',
        category    = 'edible',
    },
    -- ── Accessories ───────────────────────────────────────────────
    {
        item        = 'rolpaper',
        label       = 'Rolling Papers',
        price       = 5,
        description = 'Pack of 32 papers',
        category    = 'accessories',
    },
    {
        item        = 'lighter',
        label       = 'Lighter',
        price       = 3,
        description = 'Disposable BIC-style lighter',
        category    = 'accessories',
    },
    {
        item        = 'grinder',
        label       = 'Grinder',
        price       = 20,
        description = 'Metal 4-piece grinder',
        category    = 'accessories',
    },
}

-- ─────────────────────────────────────────────────────────────────
--  ROLLING MINIGAME
--  Press the correct key sequence to roll a blunt.
--  Success = joint2g added to inventory.
--  Fail = weed4g and rolpaper consumed but no joint produced.
-- ─────────────────────────────────────────────────────────────────
Config.RollMinigame = {
    steps       = 4,        -- number of key presses required
    timePerStep = 2500,     -- ms player has to press each key
    -- Keys used in the sequence (GTA control indices)
    -- 19=G, 20=H, 22=Space, 23=F, 24=R, 25=T, 26=Y
    keyPool     = { 19, 20, 23, 24, 25 },
    keyLabels   = { [19]='G', [20]='H', [23]='F', [24]='R', [25]='T' },
}

-- ─────────────────────────────────────────────────────────────────
--  TRUNK DRUG LAB
--  Bought from YouTools store. Installs in car trunk.
--  Only works when car is parked (speed = 0).
--  Lets player craft drugs faster than normal crafting.
-- ─────────────────────────────────────────────────────────────────
Config.TrunkLabItem      = 'trunk_lab'      -- item name in inventory
Config.TrunkLabSpeedMult = 0.5              -- craft time multiplier (0.5 = 2x faster)
Config.TrunkLabMaxSpeed  = 1.0             -- max vehicle speed (m/s) to use lab

-- YouTools store location (where player buys the trunk lab kit)
Config.YouToolsLocation  = { x = 1134.9, y = -2011.7, z = 30.7, label = 'YouTools' }
Config.YouToolsRadius    = 5.0
Config.TrunkLabKitPrice  = 2500            -- cost to buy the lab kit

-- What the trunk lab can produce (subset of CraftRecipes — faster versions)
-- Uses same recipe indices as Config.CraftRecipes
Config.TrunkLabRecipes   = { 1, 2, 3, 4, 5, 6 }   -- all recipes available in lab

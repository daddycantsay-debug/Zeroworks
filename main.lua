-- ═══════════════════════════════════════════════════════════════
--  zero-junkies | client/main.lua  v2.0
--  ESX & QBCore — Trap / Car Drug Selling Script
--  Features: buyer types, NPC dialogue, rob system, loot, effects
-- ═══════════════════════════════════════════════════════════════

local Framework = nil
local isESX     = false
local isQB      = false

-- ─────────────────────────────────────────────
--  NUI TABLET BRIDGE
--  All menus open the tablet UI instead of qb-menu/ESX menus.
-- ─────────────────────────────────────────────

local tabletOpen = false

local function OpenTablet(data)
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(data)
end

local function CloseTablet()
    tabletOpen = false
    SetNuiFocus(false, false)
end

-- NUI callbacks — fired when player clicks in the tablet
RegisterNUICallback('closeTablet', function(_, cb)
    CloseTablet(); cb({})
end)

RegisterNUICallback('sellDrug', function(data, cb)
    cb({})
    menuOpen = false
    if not npcInCar or not currentNPC or not DoesEntityExist(currentNPC) then
        Notify('~r~No buyer ready.', 'error'); return
    end
    local drug = Config.Drugs[data.index]
    if not drug then return end
    local mult  = data.moodMult or 1.0
    local buyer = currentBuyer
    local minP  = math.floor(drug.minPrice  * mult * (buyer and buyer.priceMultMin or 1.0))
    local maxP  = math.floor(drug.maxPrice  * mult * (buyer and buyer.priceMultMax or 1.0))
    TriggerServerEvent('zero-junkies:server:SellDrug', {
        item             = drug.item,
        label            = drug.label,
        minPrice         = minP,
        maxPrice         = maxP,
        minAmt           = buyer and buyer.minAmount or drug.minAmount,
        maxAmt           = buyer and buyer.maxAmount or drug.maxAmount,
        policeAlertBonus = buyer and buyer.policeAlertBonus or 0,
    })
end)

RegisterNUICallback('dismissBuyer', function(_, cb)
    cb({})
    menuOpen = false; dialogueOpen = false
    local veh = GetDriverVehicle()
    if currentNPC and DoesEntityExist(currentNPC) then
        local buyerLabel = currentBuyer and currentBuyer.label or 'Buyer'
        ShowSubtitle(('~b~[%s] ~w~Alright, I\'m out.'):format(buyerLabel), 3000)
        if veh then TaskLeaveVehicle(currentNPC, veh, 0) end
        Wait(2500); DeleteNPC()
    end
end)

RegisterNUICallback('dialogue', function(data, cb)
    cb({})
    dialogueOpen = false
    CreateThread(function() HandleDialogue(data.topic) end)
end)

RegisterNUICallback('openSell', function(_, cb)
    cb({})
    dialogueOpen = false
    Wait(150)
    OpenSellMenuTablet()
end)

RegisterNUICallback('trunkOpen', function(_, cb)
    cb({})
    local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()).x, GetEntityCoords(PlayerPedId()).y, GetEntityCoords(PlayerPedId()).z, Config.TrunkRadius, 0, 70)
    if veh and veh ~= 0 then OpenTrunkAnim(veh) end
end)

RegisterNUICallback('trunkCraft', function(_, cb)
    cb({})
    local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()).x, GetEntityCoords(PlayerPedId()).y, GetEntityCoords(PlayerPedId()).z, Config.TrunkRadius, 0, 70)
    if veh and veh ~= 0 then
        local labActive = trunkLabInstalled and labVehicle == veh and GetEntitySpeed(veh) <= Config.TrunkLabMaxSpeed
        OpenTablet({
            type      = 'openTablet',
            view      = 'craft',
            showTabs  = false,
            recipes   = Config.CraftRecipes,
            labActive = labActive,
        })
    end
end)

RegisterNUICallback('trunkSell', function(_, cb)
    cb({})
    TriggerEvent('zero-junkies:client:TrunkSell')
end)

RegisterNUICallback('trunkInstall', function(_, cb)
    cb({})
    TriggerEvent('zero-junkies:client:TrunkInstallLab')
end)

RegisterNUICallback('trunkClose', function(_, cb)
    cb({})
    trunkMenuOpen = false
end)

RegisterNUICallback('craftDrug', function(data, cb)
    cb({})
    TriggerEvent('zero-junkies:client:CraftDrug', { recipeIndex = data.recipeIndex })
end)

RegisterNUICallback('callContact', function(data, cb)
    cb({})
    CreateThread(function() CallContact(data.contactIndex) end)
end)

RegisterNUICallback('buyStoreItem', function(data, cb)
    cb({})
    TriggerServerEvent('zero-junkies:server:BuyStoreItem', data.index)
end)

-- Store page: cart checkout (multiple items at once)
RegisterNUICallback('storePurchaseCart', function(data, cb)
    cb({})
    local cart = data.cart or {}
    if #cart == 0 then return end
    TriggerServerEvent('zero-junkies:server:PurchaseCart', cart)
end)

-- Store page: close
RegisterNUICallback('closeStore', function(_, cb)
    cb({})
    storeMenuOpen = false
    CloseTablet()
end)

RegisterNUICallback('listAction', function(data, cb)
    cb({})
    TriggerEvent('zero-junkies:client:' .. (data.action or 'noop'), data.args or {})
end)

-- ── Tablet-aware sell menu ────────────────────────────────────────
function OpenSellMenuTablet()
    if menuOpen then return end
    menuOpen = true

    local moodMult = 1.0
    if npcMood >= 2 then moodMult = 1.25
    elseif npcMood >= 1 then moodMult = 1.10
    elseif npcMood <= -2 then moodMult = 0.75
    elseif npcMood <= -1 then moodMult = 0.90
    end

    local buyer = currentBuyer
    local drugData = {}
    for _, drug in ipairs(Config.Drugs) do
        drugData[#drugData + 1] = {
            item      = drug.item,
            label     = drug.label,
            minPrice  = math.floor(drug.minPrice  * moodMult * (buyer and buyer.priceMultMin or 1.0)),
            maxPrice  = math.floor(drug.maxPrice  * moodMult * (buyer and buyer.priceMultMax or 1.0)),
            preferred = buyer and buyer.preferredDrug == drug.item or false,
        }
    end

    OpenTablet({
        type       = 'openTablet',
        view       = 'drugs',
        showTabs   = false,
        mood       = npcMood,
        moodMult   = moodMult,
        buyerName  = buyer and buyer.label or 'Buyer',
        buyerLabel = buyer and buyer.label or 'Buyer',
        drugs      = drugData,
    })
end

-- ── Dialogue camera ──────────────────────────────────────────────
-- Positions a scripted cam behind the player's shoulder,
-- looking at the NPC's head — classic over-the-shoulder dialogue shot.
local dialogueCam = nil

local function StartDialogueCam()
    if dialogueCam and DoesCamExist(dialogueCam) then return end
    if not currentNPC or not DoesEntityExist(currentNPC) then return end

    local playerPed = PlayerPedId()
    local npcPed    = currentNPC

    -- Get bone positions
    local playerPos = GetEntityCoords(playerPed)
    local npcHeadPos = GetPedBoneCoords(npcPed, 0x796e, 0.0, 0.0, 0.0)  -- head bone

    -- Camera sits ~1.2m behind player, ~0.6m to the right, ~0.7m up
    local heading = GetEntityHeading(playerPed)
    local rad     = math.rad(heading)

    local camX = playerPos.x - 1.2 * math.cos(rad) + 0.6 * math.sin(rad)
    local camY = playerPos.y - 1.2 * math.sin(rad) - 0.6 * math.cos(rad)
    local camZ = playerPos.z + 0.7

    dialogueCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(dialogueCam, camX, camY, camZ)

    -- Point at NPC head
    PointCamAtCoord(dialogueCam, npcHeadPos.x, npcHeadPos.y, npcHeadPos.z + 0.05)

    SetCamFov(dialogueCam, 45.0)   -- tighter FOV = more cinematic
    RenderScriptCams(true, true, 600, true, false)  -- smooth 600ms transition in
end

local function StopDialogueCam()
    if dialogueCam and DoesCamExist(dialogueCam) then
        RenderScriptCams(false, true, 400, true, false)  -- smooth transition out
        Wait(420)
        DestroyCam(dialogueCam, false)
        dialogueCam = nil
    end
end

-- ── Tablet-aware dialogue menu ────────────────────────────────────
function OpenDialogueMenuTablet()
    if dialogueOpen or menuOpen then return end
    dialogueOpen = true

    local buyer = currentBuyer
    local greetLine = ''
    if buyer and buyer.greetLines then
        greetLine = buyer.greetLines[math.random(#buyer.greetLines)]
    end

    -- Start the dialogue camera
    StartDialogueCam()

    SetNuiFocus(true, true)
    tabletOpen = true
    SendNUIMessage({
        type       = 'openDialogue',
        buyerName  = buyer and buyer.label or 'Buyer',
        buyerLabel = buyer and buyer.label or 'Buyer',
        mood       = npcMood,
        greetLine  = greetLine,
    })
end

-- NUI callback: player picked a dialogue option
RegisterNUICallback('dlgOption', function(data, cb)
    cb({})
    dialogueOpen = false
    local topic = data.topic

    if topic == 'sell' then
        -- Close dialogue, open sell menu
        SendNUIMessage({ type = 'closeDialogue' })
        StopDialogueCam()
        SetNuiFocus(false, false)
        tabletOpen = false
        Wait(150)
        OpenSellMenuTablet()

    elseif topic == 'dismiss' then
        SendNUIMessage({ type = 'closeDialogue' })
        StopDialogueCam()
        SetNuiFocus(false, false)
        tabletOpen = false
        TriggerEvent('zero-junkies:client:DismissBuyer')

    else
        -- Dialogue topic — handle in Lua, push NPC response back to UI
        CreateThread(function()
            HandleDialogueNUI(topic)
        end)
    end
end)

-- NUI callback: close dialogue
RegisterNUICallback('closeDlg', function(_, cb)
    cb({})
    dialogueOpen = false
    tabletOpen   = false
    StopDialogueCam()
    SetNuiFocus(false, false)
end)

-- Handle a dialogue topic and push NPC response back to the UI
local function HandleDialogueNUI(topic)
    if not currentNPC or not DoesEntityExist(currentNPC) then return end

    local ped       = currentNPC
    local buyer     = currentBuyer
    local npcLabel  = buyer and buyer.label or 'Buyer'
    local npcLine   = ''
    local moodDelta = 0

    -- Play NPC gesture
    if LoadAnimDict('gestures@m@standing@casual') then
        TaskPlayAnim(ped, 'gestures@m@standing@casual', 'gesture_chat',
            2.0, -2.0, 2500, 49, 0, false, false, false)
    end
    PlayAmbientSpeech1(ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)

    if topic == 'greeting' then
        local pool = npcMood >= 0
            and { "Yo, good to see you. You got the goods?",
                  "Hey. Let's keep this quick and clean.",
                  "Good timing. I been waiting." }
            or  { "You're late. Let's just do this.",
                  "I don't like waiting. You know that." }
        npcLine   = pool[math.random(#pool)]
        moodDelta = 1

    elseif topic == 'price' then
        if npcMood >= 1 then
            local pool = { "Alright, I can work with that. You're solid.",
                           "That's fair. I'll remember that.",
                           "Cool. You take care of me, I take care of you." }
            npcLine   = pool[math.random(#pool)]
            moodDelta = 1
            Notify('~g~Negotiation worked! Better payout this sale.', 'success')
        else
            local pool = { "That's too much man. You're killing me.",
                           "Nah, that's not right. I'm a regular.",
                           "You serious? That's highway robbery." }
            npcLine   = pool[math.random(#pool)]
            moodDelta = -1
            Notify('~r~They didn\'t like that. Mood dropped.', 'error')
        end

    elseif topic == 'quality' then
        local pool = { "Straight off the brick. Nobody touched it.",
                       "Same batch. You know I don't play with quality.",
                       "Purest thing in the city right now. Trust." }
        npcLine   = pool[math.random(#pool)]
        moodDelta = 1
        Notify('~g~They trust the product. Mood improved.', 'success')

    elseif topic == 'heat' then
        if math.random(100) <= 60 then
            local pool = { "Nah, we good. I been here all day.",
                           "Clean as a whistle. Relax.",
                           "Nobody's watching. Stop being paranoid." }
            npcLine = pool[math.random(#pool)]
            Notify('~g~Area is clear.', 'success')
        else
            local pool = { "Might wanna make this quick. Seen a cruiser earlier.",
                           "Keep your eyes open. Just saying.",
                           "We're fine but don't linger." }
            npcLine = pool[math.random(#pool)]
            Notify('~o~They mentioned cops nearby. Stay sharp.', 'error')
            if math.random(100) <= 20 then
                TriggerServerEvent('zero-junkies:server:HeatAlert')
            end
        end

    elseif topic == 'smalltalk' then
        local pool = { "Can't complain. Steady flow.",
                       "Long enough. You're not the first today.",
                       "Business is business. You know how it is." }
        npcLine = pool[math.random(#pool)]
        if math.random(2) == 1 then
            moodDelta = 1
            Notify('~g~Good chat. They seem more relaxed.', 'success')
        end
    end

    -- Apply mood change
    if moodDelta ~= 0 then
        npcMood = math.max(-3, math.min(3, npcMood + moodDelta))
        TriggerServerEvent('zero-junkies:server:SaveAddiction', useCount, addictionLevel)
    end

    Wait(500)

    -- Push NPC response back to the dialogue UI
    SendNUIMessage({ type = 'npcLine',    text = npcLine })
    SendNUIMessage({ type = 'updateMood', mood = npcMood })

    Wait(2500)
    if DoesEntityExist(ped) then ClearPedTasks(ped) end

    -- Re-open dialogue after NPC responds
    Wait(300)
    if npcInCar and currentNPC and DoesEntityExist(currentNPC) then
        dialogueOpen = true
        SendNUIMessage({
            type       = 'openDialogue',
            buyerName  = npcLabel,
            buyerLabel = npcLabel,
            mood       = npcMood,
        })
    end
end

-- ── Tablet-aware trunk menu ───────────────────────────────────────
function OpenTrunkMenuTablet(veh)
    if trunkMenuOpen then return end
    trunkMenuOpen = true
    local labActive    = trunkLabInstalled and labVehicle == veh and GetEntitySpeed(veh) <= Config.TrunkLabMaxSpeed
    local labInstalled = trunkLabInstalled and labVehicle == veh
    OpenTablet({
        type         = 'openTablet',
        view         = 'trunk',
        showTabs     = false,
        labActive    = labActive,
        labInstalled = labInstalled,
    })
end

-- ── Tablet-aware phone menu ───────────────────────────────────────
function OpenPhoneMenuTablet()
    if phoneOpen then return end
    phoneOpen = true
    local delivData = nil
    if activeDelivery then
        local remaining = math.floor((activeDelivery.deadline - GetGameTimer()) / 1000)
        delivData = {
            amount    = activeDelivery.amount,
            drugLabel = activeDelivery.contact.drugLabel,
            location  = activeDelivery.location.label,
            pay       = activeDelivery.pay,
            remaining = remaining,
        }
    end
    OpenTablet({
        type           = 'openTablet',
        view           = 'phone',
        showTabs       = false,
        contacts       = Config.BurnerContacts,
        activeDelivery = delivData,
    })
end

-- ── Tablet-aware weed store ───────────────────────────────────────
function OpenWeedStoreTablet()
    if storeMenuOpen then return end
    storeMenuOpen = true

    local balance = 0
    if isQB and Framework then
        local pd = Framework.Functions.GetPlayerData()
        if pd and pd.money then balance = pd.money.cash or 0 end
    elseif isESX and Framework then
        balance = Framework.GetPlayerData().money or 0
    end

    -- Find nearest store label
    local locLabel = 'The Cookie Jar'
    local playerPos = GetEntityCoords(PlayerPedId())
    for _, loc in ipairs(Config.WeedStoreLocations) do
        if #(playerPos - vector3(loc.x, loc.y, loc.z)) < 50.0 then
            locLabel = loc.label; break
        end
    end

    SetNuiFocus(true, true)
    tabletOpen = true
    SendNUIMessage({
        type         = 'openStore',
        items        = Config.WeedStoreItems,
        balance      = balance,
        locationName = locLabel,
    })
end

-- Override the old menu functions to use tablet
OpenDialogueMenu  = OpenDialogueMenuTablet
OpenSellMenu      = OpenSellMenuTablet
OpenTrunkMenu     = OpenTrunkMenuTablet
OpenPhoneMenu     = OpenPhoneMenuTablet
OpenWeedStore     = OpenWeedStoreTablet
    local fw = string.lower(Config.Framework)
    if fw == 'esx' or (fw == 'auto' and GetResourceState('es_extended') == 'started') then
        Framework = exports['es_extended']:getSharedObject()
        isESX = true
    elseif fw == 'qbcore' or (fw == 'auto' and GetResourceState('qb-core') == 'started') then
        Framework = exports['qb-core']:GetCoreObject()
        isQB = true
    else
        TriggerEvent('esx:getSharedObject', function(obj) Framework = obj; isESX = true end)
    end
end

CreateThread(function() Wait(100); InitFramework() end)

-- Request saved addiction state from server on load
CreateThread(function()
    Wait(3000)   -- wait for framework to be ready
    TriggerServerEvent('zero-junkies:server:RequestAddiction')
end)

-- ─────────────────────────────────────────────
--  Notification wrapper
-- ─────────────────────────────────────────────
local function Notify(msg, ntype)
    if isESX and Framework then
        local t = 'info'
        if ntype == 'success' then t = 'success' elseif ntype == 'error' then t = 'error' end
        Framework.ShowNotification(msg, t)
    elseif isQB and Framework then
        Framework.Functions.Notify(msg, ntype or 'primary')
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(false, true)
    end
end

-- ─────────────────────────────────────────────
--  Subtitle helper  (shows text above minimap)
-- ─────────────────────────────────────────────
local function ShowSubtitle(msg, duration)
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandPrint(duration or 3000, true)
end

-- ─────────────────────────────────────────────
--  Anim dict loader  (returns true if loaded)
-- ─────────────────────────────────────────────
local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 60 do Wait(50); t = t + 1 end
    return HasAnimDictLoaded(dict)
end

local function LoadAnimSet(set)
    if HasAnimSetLoaded(set) then return true end
    RequestAnimSet(set)
    local t = 0
    while not HasAnimSetLoaded(set) and t < 60 do Wait(50); t = t + 1 end
    return HasAnimSetLoaded(set)
end

local function LoadModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 100 do Wait(50); t = t + 1 end
    return HasModelLoaded(hash)
end

-- ─────────────────────────────────────────────
--  State
-- ─────────────────────────────────────────────
local trapActive    = false
local sellMode      = 'car'     -- 'car' | 'window' | 'foot'
local currentNPC    = nil       -- current buyer ped
local currentBuyer  = nil       -- buyer type table (from Config.BuyerTypes)
local npcInCar      = false     -- buyer is ready to deal (in car OR alongside)
local trapBlip      = nil
local menuOpen      = false
local dialogueOpen  = false
local robActive     = false
local footRobActive = false     -- prevents overlapping foot robs
local shockActive   = false
local bleedActive   = false

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────
local function GetDriverVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(veh, -1) == ped then return veh end
    end
    return nil
end

-- Returns true if the vehicle is a bike/motorcycle (class 8 = motorcycle)
local function IsBike(veh)
    if not veh or not DoesEntityExist(veh) then return false end
    return GetVehicleClass(veh) == 8
end

-- Returns true if player is driving any supported vehicle (car or bike)
local function IsInSupportedVehicle()
    return GetDriverVehicle() ~= nil
end

local function SafeDeleteEntity(ent)
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
end

local function DeleteNPC()
    SafeDeleteEntity(currentNPC)
    currentNPC   = nil
    currentBuyer = nil
    npcInCar     = false
    menuOpen     = false
    dialogueOpen = false
    -- Kill dialogue camera if it was running
    StopDialogueCam()
end

-- ─────────────────────────────────────────────
--  Blip
-- ─────────────────────────────────────────────
local function AddTrapBlip()
    if not Config.ShowBlip then return end
    local c = GetEntityCoords(PlayerPedId())
    trapBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(trapBlip, Config.BlipSprite)
    SetBlipColour(trapBlip, Config.BlipColor)
    SetBlipScale(trapBlip, Config.BlipScale)
    SetBlipAsShortRange(trapBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.BlipLabel)
    EndTextCommandSetBlipName(trapBlip)
end

local function RemoveTrapBlip()
    if trapBlip and DoesBlipExist(trapBlip) then RemoveBlip(trapBlip) end
    trapBlip = nil
end


-- ═══════════════════════════════════════════════════════════════
--  NPC DIALOGUE SYSTEM
--  When buyer is in the car, player can press T to open a
--  conversation menu with questions/responses before selling.
--  Dialogue affects NPC mood and can unlock better prices.
-- ═══════════════════════════════════════════════════════════════

-- Mood modifier — starts at 0, goes up/down based on dialogue choices
-- Positive mood = NPC pays more. Negative = NPC pays less or leaves.
local npcMood = 0   -- range: -3 to +3

local function GetMoodLabel()
    if npcMood >= 2  then return '~g~Friendly'
    elseif npcMood >= 1 then return '~g~Relaxed'
    elseif npcMood <= -2 then return '~r~Hostile'
    elseif npcMood <= -1 then return '~o~Annoyed'
    else return '~w~Neutral' end
end

-- NPC response lines keyed by topic
local DialogueResponses = {
    greeting = {
        positive = {
            "Yo, good to see you man. You got the goods?",
            "Hey, my connect came through. What you holding?",
            "Alright, let's keep this quick and clean.",
            "Good timing. I been waiting on you.",
        },
        negative = {
            "You're late. I almost left.",
            "Took you long enough. Let's just do this.",
            "I don't like waiting. You know that.",
        },
    },
    price = {
        positive = {
            "Look, I'm a regular. Hook me up with a deal.",
            "I always pay on time. That's worth something right?",
            "Come on, give me the loyal customer rate.",
        },
        negative = {
            "I'll pay what you're asking. Just make it fast.",
            "Price is fine. Stop wasting my time.",
        },
        response_good = {
            "Alright, I can work with that. You're solid.",
            "That's fair. I'll remember that.",
            "Cool. You take care of me, I take care of you.",
        },
        response_bad = {
            "That's too much man. You're killing me.",
            "Nah, that's not right. I'm a regular.",
            "You serious? That's highway robbery.",
        },
    },
    quality = {
        positive = {
            "This the same stuff as last time? That was fire.",
            "Tell me it's not stepped on. I need the real thing.",
            "My people said your product is clean. That true?",
        },
        response_good = {
            "Straight off the brick. Nobody touched it.",
            "Same batch. You know I don't play with quality.",
            "Purest thing in the city right now. Trust.",
        },
    },
    heat = {
        lines = {
            "Cops been around here lately?",
            "You sure this spot is clean? I don't need heat.",
            "Nobody watching us right now?",
        },
        response_safe = {
            "Nah, we good. I been here all day.",
            "Clean as a whistle. Relax.",
            "Nobody's watching. Stop being paranoid.",
        },
        response_risky = {
            "Might wanna make this quick. Seen a cruiser earlier.",
            "Keep your eyes open. Just saying.",
            "We're fine but don't linger.",
        },
    },
    smalltalk = {
        lines = {
            "How's business been?",
            "You been out here long?",
            "You the only one working this area?",
        },
        responses = {
            "Can't complain. Steady flow.",
            "Long enough. You're not the first today.",
            "I got my spots. This is one of them.",
            "Business is business. You know how it is.",
        },
    },
    dismiss = {
        lines = { "Actually, never mind. I'm good.", "Forget it, I'll come back later." },
    },
}

-- ─────────────────────────────────────────────
--  Open NPC Dialogue Menu — routes to tablet UI
-- ─────────────────────────────────────────────
-- NOTE: The actual implementation is OpenDialogueMenuTablet,
-- assigned below after all functions are defined.
-- This stub is kept so call sites above the assignment work.
local function OpenDialogueMenu()
    -- Will be replaced by OpenDialogueMenuTablet after definition
    if dialogueOpen or menuOpen then return end
    if not currentNPC or not DoesEntityExist(currentNPC) then return end
    -- Fallback: play NPC gesture and open tablet
    if LoadAnimDict('gestures@m@standing@casual') then
        TaskPlayAnim(currentNPC, 'gestures@m@standing@casual', 'gesture_chat',
            2.0, -2.0, -1, 49, 0, false, false, false)
    end
    OpenDialogueMenuTablet()
end

-- ─────────────────────────────────────────────
--  Handle a dialogue topic choice
-- ─────────────────────────────────────────────
local function HandleDialogue(topic)
    dialogueOpen = false
    if not currentNPC or not DoesEntityExist(currentNPC) then return end

    local ped    = currentNPC
    local buyer  = currentBuyer
    local npcLabel = buyer and buyer.label or 'Buyer'

    -- NPC plays talk gesture
    if LoadAnimDict('gestures@m@standing@casual') then
        TaskPlayAnim(ped, 'gestures@m@standing@casual', 'gesture_chat', 2.0, -2.0, 2500, 49, 0, false, false, false)
    end

    if topic == 'greeting' then
        local pool = npcMood >= 0 and DialogueResponses.greeting.positive or DialogueResponses.greeting.negative
        local line = pool[math.random(#pool)]
        ShowSubtitle(('~b~[%s] ~w~%s'):format(npcLabel, line), 4000)
        PlayAmbientSpeech1(ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)
        npcMood = math.min(3, npcMood + 1)
        Wait(200); Notify('~g~The buyer seems more comfortable.', 'success')

    elseif topic == 'price' then
        -- Player tries to negotiate
        local askPool = DialogueResponses.price.positive
        local ask = askPool[math.random(#askPool)]
        ShowSubtitle(('~y~[You] ~w~%s'):format(ask), 3000)
        Wait(3000)
        if not DoesEntityExist(ped) then return end
        -- NPC responds based on mood
        if npcMood >= 1 then
            local resp = DialogueResponses.price.response_good
            ShowSubtitle(('~b~[%s] ~w~%s'):format(npcLabel, resp[math.random(#resp)]), 4000)
            PlayAmbientSpeech1(ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)
            npcMood = math.min(3, npcMood + 1)
            Notify('~g~Negotiation worked! Better payout this sale.', 'success')
        else
            local resp = DialogueResponses.price.response_bad
            ShowSubtitle(('~b~[%s] ~w~%s'):format(npcLabel, resp[math.random(#resp)]), 4000)
            PlayAmbientSpeech1(ped, 'GENERIC_CURSE_MED', 'SPEECH_PARAMS_FORCE', 0)
            npcMood = math.max(-3, npcMood - 1)
            Notify('~r~They didn\'t like that. Mood dropped.', 'error')
        end

    elseif topic == 'quality' then
        local ask = DialogueResponses.quality.positive
        ShowSubtitle(('~y~[You] ~w~%s'):format(ask[math.random(#ask)]), 3000)
        Wait(3000)
        if not DoesEntityExist(ped) then return end
        local resp = DialogueResponses.quality.response_good
        ShowSubtitle(('~b~[%s] ~w~%s'):format(npcLabel, resp[math.random(#resp)]), 4000)
        PlayAmbientSpeech1(ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)
        npcMood = math.min(3, npcMood + 1)
        Notify('~g~They trust the product. Mood improved.', 'success')

    elseif topic == 'heat' then
        local ask = DialogueResponses.heat.lines
        ShowSubtitle(('~y~[You] ~w~%s'):format(ask[math.random(#ask)]), 3000)
        Wait(3000)
        if not DoesEntityExist(ped) then return end
        -- Random: safe or risky response
        if math.random(1, 100) <= 60 then
            local resp = DialogueResponses.heat.response_safe
            ShowSubtitle(('~b~[%s] ~w~%s'):format(npcLabel, resp[math.random(#resp)]), 4000)
            PlayAmbientSpeech1(ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)
            Notify('~g~Area is clear. No extra heat.', 'success')
        else
            local resp = DialogueResponses.heat.response_risky
            ShowSubtitle(('~b~[%s] ~w~%s'):format(npcLabel, resp[math.random(#resp)]), 4000)
            PlayAmbientSpeech1(ped, 'GENERIC_CURSE_MED', 'SPEECH_PARAMS_FORCE', 0)
            Notify('~o~They mentioned cops nearby. Stay sharp.', 'error')
            -- Small chance of police alert from this conversation
            if math.random(1, 100) <= 20 then
                TriggerServerEvent('zero-junkies:server:HeatAlert')
            end
        end

    elseif topic == 'smalltalk' then
        local ask = DialogueResponses.smalltalk.lines
        ShowSubtitle(('~y~[You] ~w~%s'):format(ask[math.random(#ask)]), 3000)
        Wait(3000)
        if not DoesEntityExist(ped) then return end
        local resp = DialogueResponses.smalltalk.responses
        ShowSubtitle(('~b~[%s] ~w~%s'):format(npcLabel, resp[math.random(#resp)]), 4000)
        PlayAmbientSpeech1(ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)
        -- Small talk has a 50/50 mood effect
        if math.random(1, 2) == 1 then
            npcMood = math.min(3, npcMood + 1)
            Notify('~g~Good chat. They seem more relaxed.', 'success')
        else
            Notify('~w~They didn\'t say much. Mood unchanged.', 'error')
        end
    end

    -- Stop the gesture anim after response
    Wait(2500)
    if DoesEntityExist(ped) then ClearPedTasks(ped) end

    -- Re-open dialogue menu after a short pause
    Wait(500)
    if npcInCar and currentNPC and DoesEntityExist(currentNPC) then
        OpenDialogueMenu()
    end
end

-- Client events for dialogue (fired from qb-menu params)
RegisterNetEvent('zero-junkies:client:Dialogue')
AddEventHandler('zero-junkies:client:Dialogue', function(data)
    CreateThread(function() HandleDialogue(data.topic) end)
end)

RegisterNetEvent('zero-junkies:client:OpenSell')
AddEventHandler('zero-junkies:client:OpenSell', function()
    dialogueOpen = false
    -- Small delay so menu closes cleanly before sell menu opens
    Wait(150)
    TriggerEvent('zero-junkies:client:DoOpenSellMenu')
end)


-- ═══════════════════════════════════════════════════════════════
--  NPC SPAWN & APPROACH  (routes to correct sell mode)
-- ═══════════════════════════════════════════════════════════════

-- Shared: spawn a buyer ped near the given origin coords
local function SpawnBuyerPed(originCoords)
    local buyerType = Config.BuyerTypes[math.random(#Config.BuyerTypes)]
    local modelName = buyerType.models[math.random(#buyerType.models)]
    local model     = GetHashKey(modelName)
    if not LoadModel(model) then return nil, nil end

    local dist  = math.random(20, math.floor(Config.DetectionRadius))
    local angle = math.rad(math.random(0, 360))
    local sx    = originCoords.x + dist * math.cos(angle)
    local sy    = originCoords.y + dist * math.sin(angle)
    local sz    = originCoords.z

    local ped = CreatePed(4, model, sx, sy, sz, 0.0, true, true)
    SetModelAsNoLongerNeeded(model)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetEntityInvincible(ped, true)

    if buyerType.walkStyle and LoadAnimSet(buyerType.walkStyle) then
        SetPedMovementClipset(ped, buyerType.walkStyle, 0.5)
    end

    currentNPC   = ped
    currentBuyer = buyerType
    npcMood      = 0
    return ped, buyerType
end

-- Shared: NPC greets player and sets up timeout
local function BuyerReady(ped, buyerType, timeoutCallback)
    npcInCar = true
    local greet = buyerType.greetLines[math.random(#buyerType.greetLines)]
    ShowSubtitle(('~b~[%s] ~w~%s'):format(buyerType.label, greet), 4000)
    PlayAmbientSpeech1(ped, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)
    Notify(('~g~%s is ready. Press ~INPUT_CONTEXT~ to talk.'):format(buyerType.label), 'success')

    CreateThread(function()
        Wait(Config.NPCTimeout)
        if npcInCar and DoesEntityExist(ped) then
            ShowSubtitle(('~b~[%s] ~w~Forget it. I\'m out.'):format(buyerType.label), 3000)
            PlayAmbientSpeech1(ped, 'GENERIC_CURSE_MED', 'SPEECH_PARAMS_FORCE', 0)
            Notify('~r~Buyer got impatient and left.', 'error')
            if timeoutCallback then timeoutCallback() end
            Wait(3000)
            DeleteNPC()
        end
    end)
end

-- ── MODE: CAR — NPC gets in passenger seat ───────────────────────
local function SpawnBuyer_Car()
    local veh = GetDriverVehicle()
    if not veh then return end

    local ped, buyerType = SpawnBuyerPed(GetEntityCoords(veh))
    if not ped then return end

    TaskEnterVehicle(ped, veh, 15000, 0, 2.0, 1, 0)

    CreateThread(function()
        local waited = 0
        while DoesEntityExist(ped) and waited < 15000 do
            Wait(500); waited = waited + 500
            if IsPedInVehicle(ped, veh, false) then
                BuyerReady(ped, buyerType, function()
                    TaskLeaveVehicle(ped, veh, 0)
                end)
                return
            end
        end
        if DoesEntityExist(ped) and not npcInCar then DeleteNPC() end
    end)
end

-- ── MODE: WINDOW — NPC walks to driver window, player leans out ──
local function SpawnBuyer_Window()
    local veh = GetDriverVehicle()
    if not veh then return end

    local ped, buyerType = SpawnBuyerPed(GetEntityCoords(veh))
    if not ped then return end

    local vehCoords  = GetEntityCoords(veh)
    local vehHeading = GetEntityHeading(veh)

    -- Driver window: ~1.5m to the left of the vehicle
    local winX = vehCoords.x + 1.5 * math.cos(math.rad(vehHeading + 90))
    local winY = vehCoords.y + 1.5 * math.sin(math.rad(vehHeading + 90))
    local winZ = vehCoords.z

    TaskGoStraightToCoord(ped, winX, winY, winZ, 2.0, 15000, vehHeading + 180, 0.5)

    CreateThread(function()
        local waited = 0
        while DoesEntityExist(ped) and waited < 15000 do
            Wait(500); waited = waited + 500
            local dist = #(GetEntityCoords(ped) - vector3(winX, winY, winZ))
            if dist < 1.8 then
                ClearPedTasks(ped)
                TaskTurnPedToFaceEntity(ped, PlayerPedId(), 800)
                Wait(800)

                -- NPC leans on the car door/window frame
                -- Uses the leaning-on-wall scenario anim — most realistic for leaning on a car
                if LoadAnimDict('amb@world_human_leaning@male@wall@back@foot_up@idle_a') then
                    TaskPlayAnim(ped,
                        'amb@world_human_leaning@male@wall@back@foot_up@idle_a',
                        'idle_a',
                        2.0, -2.0, -1, 1, 0, false, false, false)
                end

                -- Player reaches hand out the window
                local playerPed = PlayerPedId()
                if LoadAnimDict('veh@std@ds@base') then
                    TaskPlayAnim(playerPed, 'veh@std@ds@base', 'get_out_driver_lhs',
                        3.0, -3.0, 2500, 49, 0, false, false, false)
                end

                BuyerReady(ped, buyerType, function()
                    ClearPedTasks(ped)
                    local pedPos  = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    TaskGoStraightToCoord(ped,
                        pedPos.x + 10.0 * math.cos(math.rad(heading + 180)),
                        pedPos.y + 10.0 * math.sin(math.rad(heading + 180)),
                        pedPos.z, 2.0, 5000, heading + 180, 0.2)
                end)
                return
            end
        end
        if DoesEntityExist(ped) and not npcInCar then DeleteNPC() end
    end)
end

-- ── MODE: FOOT — player on foot, NPC walks up, handshake on arrival ─
local function SpawnBuyer_Foot()
    local playerPed    = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local ped, buyerType = SpawnBuyerPed(playerCoords)
    if not ped then return end

    TaskGoToEntity(ped, playerPed, -1, 1.5, 1.5, 0, 0)

    CreateThread(function()
        local waited = 0
        while DoesEntityExist(ped) and waited < 15000 do
            Wait(500); waited = waited + 500
            local dist = #(GetEntityCoords(ped) - GetEntityCoords(playerPed))
            if dist < 2.0 then
                ClearPedTasks(ped)
                TaskTurnPedToFaceEntity(ped, playerPed, 800)
                Wait(800)

                -- ── Handshake / dap greeting ──────────────────────
                -- Both peds play the greeting handshake simultaneously
                if LoadAnimDict('mp_common') then
                    -- NPC side
                    TaskPlayAnim(ped, 'mp_common', 'givetake1_a',
                        3.0, -3.0, 2000, 49, 0, false, false, false)
                    -- Player side (mirrored receive)
                    TaskPlayAnim(playerPed, 'mp_common', 'givetake1_b',
                        3.0, -3.0, 2000, 49, 0, false, false, false)
                    Wait(2000)
                    ClearPedTasks(ped)
                    ClearPedTasks(playerPed)
                end

                BuyerReady(ped, buyerType, function()
                    local pedPos  = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    TaskGoStraightToCoord(ped,
                        pedPos.x + 15.0 * math.cos(math.rad(heading + 180)),
                        pedPos.y + 15.0 * math.sin(math.rad(heading + 180)),
                        pedPos.z, 2.5, 6000, heading + 180, 0.2)
                end)
                return
            end
        end
        if DoesEntityExist(ped) and not npcInCar then DeleteNPC() end
    end)
end

-- ── Router ───────────────────────────────────────────────────────
local function SpawnBuyer()
    if not trapActive then return end
    if currentNPC and DoesEntityExist(currentNPC) then return end

    if sellMode == 'window' then
        SpawnBuyer_Window()
    elseif sellMode == 'foot' then
        SpawnBuyer_Foot()
    else
        -- 'car' mode — also handles bike automatically
        local veh = GetDriverVehicle()
        if veh and IsBike(veh) then
            -- Bike: NPC walks alongside (same as foot approach)
            SpawnBuyer_Foot()
        else
            SpawnBuyer_Car()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  SELL MENU  (opened from dialogue or direct E press)
-- ═══════════════════════════════════════════════════════════════
local function OpenSellMenu()
    if menuOpen then return end
    menuOpen = true

    -- Apply mood-based price multiplier
    local moodMult = 1.0
    if npcMood >= 2 then moodMult = 1.25
    elseif npcMood >= 1 then moodMult = 1.10
    elseif npcMood <= -2 then moodMult = 0.75
    elseif npcMood <= -1 then moodMult = 0.90
    end

    local buyer = currentBuyer

    if isQB then
        local options = {}
        for i, drug in ipairs(Config.Drugs) do
            -- Check if this buyer prefers this drug
            local preferred = buyer and buyer.preferredDrug == drug.item
            local tag = preferred and ' ⭐' or ''
            local minP = math.floor(drug.minPrice * moodMult)
            local maxP = math.floor(drug.maxPrice * moodMult)
            options[#options + 1] = {
                header = drug.label .. tag,
                txt    = ('$%d – $%d per unit  [Mood: %s~w~]'):format(minP, maxP, GetMoodLabel()),
                params = {
                    event = 'zero-junkies:client:SellDrug',
                    args  = { index = i, moodMult = moodMult },
                },
            }
        end
        options[#options + 1] = {
            header = '💬 Keep talking',
            txt    = 'Go back to conversation',
            params = { event = 'zero-junkies:client:BackToDialogue' },
        }
        options[#options + 1] = {
            header = '❌ Never mind',
            txt    = 'Send the buyer away',
            params = { event = 'zero-junkies:client:DismissBuyer' },
        }
        exports['qb-menu']:openMenu(options)

    elseif isESX then
        local elements = {}
        for i, drug in ipairs(Config.Drugs) do
            local preferred = buyer and buyer.preferredDrug == drug.item
            local tag = preferred and ' ⭐' or ''
            local minP = math.floor(drug.minPrice * moodMult)
            local maxP = math.floor(drug.maxPrice * moodMult)
            elements[#elements + 1] = {
                label = ('%s%s  ($%d–$%d)'):format(drug.label, tag, minP, maxP),
                value = i,
            }
        end
        elements[#elements + 1] = { label = '💬 Keep talking', value = -1 }
        elements[#elements + 1] = { label = '❌ Never mind',   value = 0  }

        Framework.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_menu',
            { title = ('Deal with %s'):format(buyer and buyer.label or 'Buyer'), align = 'top-left', elements = elements },
            function(data, menu)
                menu.close(); menuOpen = false
                local v = data.current.value
                if v == 0 then
                    TriggerEvent('zero-junkies:client:DismissBuyer')
                elseif v == -1 then
                    TriggerEvent('zero-junkies:client:BackToDialogue')
                else
                    TriggerEvent('zero-junkies:client:SellDrug', { index = v, moodMult = moodMult })
                end
            end,
            function(_, menu) menu.close(); menuOpen = false end
        )
    end
end

RegisterNetEvent('zero-junkies:client:DoOpenSellMenu')
AddEventHandler('zero-junkies:client:DoOpenSellMenu', function() OpenSellMenu() end)

RegisterNetEvent('zero-junkies:client:BackToDialogue')
AddEventHandler('zero-junkies:client:BackToDialogue', function()
    menuOpen = false
    Wait(150)
    OpenDialogueMenu()
end)


-- ═══════════════════════════════════════════════════════════════
--  CLOTHING STRIP & RESTORE SYSTEM
--  When robbed: shirt and shoes are removed.
--  When player loots the robber's body: clothes are given back.
-- ═══════════════════════════════════════════════════════════════

local savedClothes = nil   -- { top, topTex, shoes, shoesTex }

local COMP_SHOES = 6
local COMP_TOP   = 11

local function GetBareFoot()
    -- Female freemode uses index 35, male uses 34
    if GetEntityModel(PlayerPedId()) == GetHashKey('mp_f_freemode_01') then
        return 35, 0
    end
    return 34, 0
end

local function GetBareTop()
    -- Both male and female freemode use 15 for shirtless/naked torso
    return 15, 0
end

local function SaveAndStripClothes()
    local ped = PlayerPedId()

    -- Save what they're wearing right now
    savedClothes = {
        top      = GetPedDrawableVariation(ped, COMP_TOP),
        topTex   = GetPedTextureVariation(ped, COMP_TOP),
        shoes    = GetPedDrawableVariation(ped, COMP_SHOES),
        shoesTex = GetPedTextureVariation(ped, COMP_SHOES),
    }

    -- Wait for ragdoll to settle before stripping
    Wait(900)
    ped = PlayerPedId()

    local bareTop,  bareTopTex  = GetBareTop()
    local bareFoot, bareFootTex = GetBareFoot()

    SetPedComponentVariation(ped, COMP_TOP,   bareTop,  bareTopTex,  2)
    SetPedComponentVariation(ped, COMP_SHOES, bareFoot, bareFootTex, 2)

    Notify('~r~They stripped your shirt and shoes!', 'error')
end

local function RestoreClothes()
    if not savedClothes then return end
    local ped = PlayerPedId()

    -- Dress-up animation
    if LoadAnimDict('mp_player_inteat@burger') then
        TaskPlayAnim(ped, 'mp_player_inteat@burger', 'loop',
            3.0, -3.0, 2500, 49, 0, false, false, false)
        Wait(2500)
        ClearPedTasks(ped)
    end

    SetPedComponentVariation(ped, COMP_TOP,   savedClothes.top,   savedClothes.topTex,   2)
    SetPedComponentVariation(ped, COMP_SHOES, savedClothes.shoes, savedClothes.shoesTex, 2)

    savedClothes = nil
    Notify('~g~You got your clothes back.', 'success')
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
end

-- ═══════════════════════════════════════════════════════════════
--  ROB SEQUENCE
-- ═══════════════════════════════════════════════════════════════
local function CleanupRob(robPed, robVeh)
    CancelMusicEvent('ROBBERY_STING')
    CancelMusicEvent('GETAWAY_DRIVER')
    CancelMusicEvent('HEIST_SETUP_COMPLETE')
    StopAudioScene('FBI_HEIST_FINALE_INTRO_AUDIO_SCENE')
    SafeDeleteEntity(robPed)
    SafeDeleteEntity(robVeh)
    robActive = false
end

local function SpawnRobber()
    if robActive then return end
    robActive = true

    local playerPed    = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Spawn point
    local angle  = math.rad(math.random(0, 360))
    local spawnX = playerCoords.x + Config.RobSpawnDistance * math.cos(angle)
    local spawnY = playerCoords.y + Config.RobSpawnDistance * math.sin(angle)
    local spawnZ = playerCoords.z

    -- Load vehicle
    local vehModelName = Config.RobberVehicles[math.random(#Config.RobberVehicles)]
    local vehModel     = GetHashKey(vehModelName)
    if not LoadModel(vehModel) then robActive = false; return end

    local robVeh = CreateVehicle(vehModel, spawnX, spawnY, spawnZ, 0.0, true, false)
    SetModelAsNoLongerNeeded(vehModel)
    SetVehicleEngineOn(robVeh, true, true, false)

    -- Load robber ped
    local pedModelName = Config.RobberModels[math.random(#Config.RobberModels)]
    local pedModel     = GetHashKey(pedModelName)
    if not LoadModel(pedModel) then SafeDeleteEntity(robVeh); robActive = false; return end

    local robPed = CreatePed(4, pedModel, spawnX, spawnY, spawnZ, 0.0, true, true)
    SetModelAsNoLongerNeeded(pedModel)
    SetPedIntoVehicle(robPed, robVeh, -1)
    SetPedFleeAttributes(robPed, 0, false)
    SetPedCombatAttributes(robPed, 46, true)
    SetBlockingOfNonTemporaryEvents(robPed, true)
    SetPedCanRagdoll(robPed, false)
    SetEntityInvincible(robPed, true)
    GiveWeaponToPed(robPed, GetHashKey('WEAPON_KNIFE'), 1, false, true)

    -- Approach with tension music
    Notify('~r~Heads up! Someone is rolling up on you!', 'error')
    TriggerMusicEvent('HEIST_SETUP_COMPLETE')
    StartAudioScene('FBI_HEIST_FINALE_INTRO_AUDIO_SCENE')

    TaskVehicleDriveToCoordLongrange(robPed, robVeh,
        playerCoords.x, playerCoords.y, playerCoords.z,
        25.0, 786603, 4.0)

    -- Wait until close
    local waited = 0
    while waited < 25000 do
        Wait(500); waited = waited + 500
        if not DoesEntityExist(robPed) then break end
        if #(GetEntityCoords(robPed) - GetEntityCoords(playerPed)) < 8.0 then break end
    end

    if not DoesEntityExist(robPed) then CleanupRob(robPed, robVeh); return end

    -- Get out and walk up
    TaskLeaveVehicle(robPed, robVeh, 0)
    Wait(2000)

    TaskGoToEntity(robPed, playerPed, -1, 1.5, 2.0, 0, 0)
    waited = 0
    while waited < 8000 do
        Wait(500); waited = waited + 500
        if not DoesEntityExist(robPed) then break end
        if #(GetEntityCoords(robPed) - GetEntityCoords(playerPed)) < 2.0 then break end
    end

    if not DoesEntityExist(robPed) then CleanupRob(robPed, robVeh); return end

    -- Face player
    TaskTurnPedToFaceEntity(robPed, playerPed, 1000)
    Wait(900)

    -- Shout threat
    PlayAmbientSpeech1(robPed, 'GENERIC_CURSE_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED', 0)
    ShowSubtitle('~r~[Robber] ~w~Give it up! Everything — NOW!', 3000)
    Wait(400)

    -- Music sting
    StopAudioScene('FBI_HEIST_FINALE_INTRO_AUDIO_SCENE')
    CancelMusicEvent('HEIST_SETUP_COMPLETE')
    TriggerMusicEvent('ROBBERY_STING')

    Notify('~r~You\'re being robbed!', 'error')

    -- Stab animation
    if LoadAnimDict('melee@knife@streamed_core') then
        TaskPlayAnim(robPed, 'melee@knife@streamed_core', 'short_0_attack', 8.0, -8.0, 1000, 0, 0, false, false, false)
    end

    -- Player ragdoll hit reaction
    Wait(350)
    SetPedToRagdoll(playerPed, 1200, 1200, 0, false, false, false)

    -- Sharp red flash x2
    StartScreenEffect('SwitchHUDIn', 0, false); Wait(60); StopScreenEffect('SwitchHUDIn')
    StartScreenEffect('SwitchHUDIn', 0, false); Wait(60); StopScreenEffect('SwitchHUDIn')
    PlaySoundFrontend(-1, 'PAIN', 'PLAYER_AUDIO_SOUNDSET', true)

    Wait(1200)

    -- Server takes loot
    TriggerServerEvent('zero-junkies:server:RobPlayer')

    -- Strip shirt and shoes
    CreateThread(SaveAndStripClothes)

    -- Make robber mortal — player can fight back
    SetEntityInvincible(robPed, false)
    SetPedCanRagdoll(robPed, true)

    -- ── Robber taunts and sprints away IN FRONT of player ──
    -- This gives the player a window to chase and stop them
    Wait(600)
    CancelMusicEvent('ROBBERY_STING')
    TriggerMusicEvent('GETAWAY_DRIVER')

    -- Shout as they run
    PlayAmbientSpeech1(robPed, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE_SHOUTED', 0)
    ShowSubtitle('~r~[Robber] ~w~Later sucker! Come get it!', 3000)

    -- Sprint directly away from the player (in front = same direction player is facing)
    -- so player can see them and has a fair chase window
    local playerHeading = GetEntityHeading(playerPed)
    local fleeX = playerCoords.x + 30.0 * math.cos(math.rad(playerHeading))
    local fleeY = playerCoords.y + 30.0 * math.sin(math.rad(playerHeading))
    local fleeZ = playerCoords.z

    -- Sprint on foot first — visible chase window (8 seconds)
    SetPedMaxMoveBlendRatio(robPed, 1.0)
    TaskGoStraightToCoord(robPed, fleeX, fleeY, fleeZ, 3.5, 8000, playerHeading, 0.3)

    Notify('~o~Chase him down! He\'s running!', 'error')

    -- Chase window — 8 seconds on foot before he reaches the car
    local chaseWindow  = 8000
    local chaseElapsed = 0
    local caughtOnFoot = false

    while chaseElapsed < chaseWindow do
        Wait(300); chaseElapsed = chaseElapsed + 300
        if not DoesEntityExist(robPed) then break end
        if IsEntityDead(robPed) then caughtOnFoot = true; break end
        -- If player gets within 2m during the sprint, robber is caught
        if #(GetEntityCoords(robPed) - GetEntityCoords(playerPed)) < 2.0 then
            caughtOnFoot = true; break
        end
    end

    -- If caught on foot — robber surrenders, no car escape
    if caughtOnFoot and DoesEntityExist(robPed) and not IsEntityDead(robPed) then
        ClearPedTasks(robPed)
        TaskHandsUp(robPed, 5000, playerPed, -1, false)
        Notify('~g~You caught him! Take him down!', 'success')
        -- Give player 5 more seconds to finish the job
        Wait(5000)
    end

    -- Now robber tries to reach the car and escape
    if DoesEntityExist(robPed) and not IsEntityDead(robPed) then
        if DoesEntityExist(robVeh) then
            TaskEnterVehicle(robPed, robVeh, 10000, -1, 2.0, 1, 0)
        end
    end

    -- Kill-watch window
    local killWindow  = Config.LootWindowTime * 1000
    local killElapsed = 0
    local robberKilled = false

    while killElapsed < killWindow do
        Wait(500); killElapsed = killElapsed + 500
        if not DoesEntityExist(robPed) then break end
        if IsEntityDead(robPed) then robberKilled = true; break end
    end

    -- Robber escaped
    if not robberKilled then
        CleanupRob(robPed, robVeh)
        return
    end

    -- Robber killed
    CancelMusicEvent('GETAWAY_DRIVER')
    StopAudioScene('FBI_HEIST_FINALE_INTRO_AUDIO_SCENE')

    if DoesEntityExist(robVeh) then
        SetVehicleEngineOn(robVeh, false, true, false)
    end

    SetPlayerWantedLevel(PlayerId(), Config.KillRobberWanted, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    TriggerServerEvent('zero-junkies:server:RobberKilled')

    Notify('~r~You killed the robber! Cops incoming — loot fast!', 'error')
    PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', true)

    -- Loot blip
    local bodyCoords = GetEntityCoords(robPed)
    local lootBlip   = AddBlipForCoord(bodyCoords.x, bodyCoords.y, bodyCoords.z)
    SetBlipSprite(lootBlip, 273)
    SetBlipColour(lootBlip, 1)
    SetBlipScale(lootBlip, 0.8)
    SetBlipAsShortRange(lootBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Robber Body')
    EndTextCommandSetBlipName(lootBlip)

    -- Loot prompt loop
    local lootDeadline = GetGameTimer() + (Config.LootWindowTime * 1000)
    local looted = false

    CreateThread(function()
        while GetGameTimer() < lootDeadline do
            Wait(0)
            if not DoesEntityExist(robPed) then break end
            local dist = #(GetEntityCoords(robPed) - GetEntityCoords(PlayerPedId()))
            if dist < 2.0 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to loot the body')
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, Config.LootKey) and not looted then
                    looted = true
                    TriggerServerEvent('zero-junkies:server:LootRobber')
                    CreateThread(RestoreClothes)
                    break
                end
            end
        end
        if DoesBlipExist(lootBlip) then RemoveBlip(lootBlip) end
        -- If player never looted, restore clothes after window expires
        if savedClothes then
            Notify('~o~You managed to find your clothes on the ground.', 'error')
            CreateThread(RestoreClothes)
        end
        Wait(5000)
        SafeDeleteEntity(robPed)
        SafeDeleteEntity(robVeh)
        robActive = false
    end)
end


-- ═══════════════════════════════════════════════════════════════
--  ON-FOOT ARMED ROB  (two NPCs, gunpoint)
--  Triggered after a foot sale with Config.FootRobChance probability.
--  Two robbers spawn nearby, surround the player, demand everything.
-- ═══════════════════════════════════════════════════════════════
local function FootRob()
    if footRobActive then return end
    footRobActive = true

    local playerPed    = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Spawn two robbers from opposite angles
    local robbers = {}
    local angles  = { math.random(0, 170), math.random(180, 350) }

    for i = 1, Config.FootRobberCount do
        local modelName = Config.FootRobberModels[math.random(#Config.FootRobberModels)]
        local model     = GetHashKey(modelName)
        if not LoadModel(model) then
            footRobActive = false; return
        end

        local spawnDist = math.random(25, 40)
        local angle     = math.rad(angles[i])
        local sx = playerCoords.x + spawnDist * math.cos(angle)
        local sy = playerCoords.y + spawnDist * math.sin(angle)
        local sz = playerCoords.z

        local ped = CreatePed(4, model, sx, sy, sz, 0.0, true, true)
        SetModelAsNoLongerNeeded(model)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAttributes(ped, 5, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, true)
        SetEntityInvincible(ped, false)   -- mortal from the start

        -- Give random weapon
        local weapon = Config.FootRobberWeapons[math.random(#Config.FootRobberWeapons)]
        GiveWeaponToPed(ped, weapon, 100, false, true)

        robbers[i] = ped
    end

    Notify('~r~Two guys are moving on you!', 'error')

    -- Both walk toward player
    for _, rob in ipairs(robbers) do
        TaskGoToEntity(rob, playerPed, -1, 1.8, 2.0, 0, 0)
    end

    -- Wait until both are close
    local waited = 0
    while waited < 15000 do
        Wait(500); waited = waited + 500
        local allClose = true
        for _, rob in ipairs(robbers) do
            if DoesEntityExist(rob) then
                if #(GetEntityCoords(rob) - GetEntityCoords(playerPed)) > 3.0 then
                    allClose = false
                end
            end
        end
        if allClose then break end
    end

    -- Check any survived
    local anyAlive = false
    for _, rob in ipairs(robbers) do
        if DoesEntityExist(rob) and not IsEntityDead(rob) then
            anyAlive = true; break
        end
    end

    if not anyAlive then
        footRobActive = false; return
    end

    -- Face player and aim weapons
    for _, rob in ipairs(robbers) do
        if DoesEntityExist(rob) and not IsEntityDead(rob) then
            ClearPedTasks(rob)
            TaskTurnPedToFaceEntity(rob, playerPed, 800)
        end
    end
    Wait(800)

    -- Aim at player (TaskAimGunAtEntity)
    for _, rob in ipairs(robbers) do
        if DoesEntityExist(rob) and not IsEntityDead(rob) then
            TaskAimGunAtEntity(rob, playerPed, 8000, false)
        end
    end

    -- Shout demand
    if robbers[1] and DoesEntityExist(robbers[1]) then
        PlayAmbientSpeech1(robbers[1], 'GENERIC_CURSE_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED', 0)
    end
    ShowSubtitle('~r~[Robber] ~w~Don\'t move! Drop everything — NOW!', 4000)
    Notify('~r~Armed robbery! You\'re surrounded!', 'error')

    -- Screen flash
    StartScreenEffect('SwitchHUDIn', 0, false); Wait(80); StopScreenEffect('SwitchHUDIn')

    Wait(3000)

    -- Check if player killed either robber before the rob fires
    local playerFoughtBack = false
    for _, rob in ipairs(robbers) do
        if DoesEntityExist(rob) and IsEntityDead(rob) then
            playerFoughtBack = true; break
        end
    end

    if not playerFoughtBack then
        -- Rob fires — take drugs and cash
        TriggerServerEvent('zero-junkies:server:RobPlayer')
        ShockEffect()
        BleedEffect()

        -- Strip shirt and shoes
        CreateThread(SaveAndStripClothes)

        -- Robbers back off after taking the goods
        Wait(1500)
        for _, rob in ipairs(robbers) do
            if DoesEntityExist(rob) and not IsEntityDead(rob) then
                ClearPedTasks(rob)
                PlayAmbientSpeech1(rob, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)
                -- Run away
                local pedPos  = GetEntityCoords(rob)
                local heading = GetEntityHeading(rob)
                TaskGoStraightToCoord(rob,
                    pedPos.x + 30.0 * math.cos(math.rad(heading + 180)),
                    pedPos.y + 30.0 * math.sin(math.rad(heading + 180)),
                    pedPos.z, 4.0, 8000, heading + 180, 0.2)
            end
        end

        -- Monitor if player kills fleeing robbers (loot window)
        local killDeadline = GetGameTimer() + (Config.LootWindowTime * 1000)
        local lootBlips    = {}

        CreateThread(function()
            -- Watch for kills
            while GetGameTimer() < killDeadline do
                Wait(500)
                for idx, rob in ipairs(robbers) do
                    if DoesEntityExist(rob) and IsEntityDead(rob) and not lootBlips[idx] then
                        -- Add loot blip
                        local bc = GetEntityCoords(rob)
                        local lb = AddBlipForCoord(bc.x, bc.y, bc.z)
                        SetBlipSprite(lb, 273); SetBlipColour(lb, 1); SetBlipScale(lb, 0.8)
                        SetBlipAsShortRange(lb, true)
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentString('Robber Body')
                        EndTextCommandSetBlipName(lb)
                        lootBlips[idx] = lb

                        -- Wanted level for the kill
                        SetPlayerWantedLevel(PlayerId(), Config.KillRobberWanted, false)
                        SetPlayerWantedLevelNow(PlayerId(), false)
                        TriggerServerEvent('zero-junkies:server:RobberKilled')
                        Notify('~r~Robber down! Loot the body fast!', 'error')
                    end
                end
            end

            -- Cleanup blips and bodies
            for _, lb in pairs(lootBlips) do
                if DoesBlipExist(lb) then RemoveBlip(lb) end
            end
            -- If player never looted, restore clothes anyway after window expires
            if savedClothes then
                Notify('~o~The robbers are gone. You found your clothes nearby.', 'error')
                CreateThread(RestoreClothes)
            end
            Wait(5000)
            for _, rob in ipairs(robbers) do SafeDeleteEntity(rob) end
            footRobActive = false
        end)

        -- Loot prompt loop for any downed robber
        CreateThread(function()
            local looted = {}
            while GetGameTimer() < killDeadline do
                Wait(0)
                for idx, rob in ipairs(robbers) do
                    if DoesEntityExist(rob) and IsEntityDead(rob) and not looted[idx] then
                        local dist = #(GetEntityCoords(rob) - GetEntityCoords(PlayerPedId()))
                        if dist < 2.0 then
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to loot the body')
                            EndTextCommandDisplayHelp(0, false, true, -1)
                            if IsControlJustReleased(0, Config.LootKey) then
                                looted[idx] = true
                                TriggerServerEvent('zero-junkies:server:LootRobber')
                                CreateThread(RestoreClothes)
                            end
                        end
                    end
                end
            end
        end)

    else
        -- Player fought back — robbers go hostile
        Notify('~r~They\'re shooting back!', 'error')
        for _, rob in ipairs(robbers) do
            if DoesEntityExist(rob) and not IsEntityDead(rob) then
                TaskCombatPed(rob, playerPed, 0, 16)
            end
        end

        -- Monitor fight
        local fightDeadline = GetGameTimer() + 45000
        CreateThread(function()
            while GetGameTimer() < fightDeadline do
                Wait(500)
                local allDead = true
                for _, rob in ipairs(robbers) do
                    if DoesEntityExist(rob) and not IsEntityDead(rob) then
                        allDead = false; break
                    end
                end
                if allDead then
                    Notify('~g~You took them both out!', 'success')
                    SetPlayerWantedLevel(PlayerId(), Config.KillRobberWanted, false)
                    SetPlayerWantedLevelNow(PlayerId(), false)
                    TriggerServerEvent('zero-junkies:server:RobberKilled')
                    break
                end
            end
            Wait(10000)
            for _, rob in ipairs(robbers) do SafeDeleteEntity(rob) end
            footRobActive = false
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  SHOCK EFFECT  (post-stab adrenaline response)
-- ═══════════════════════════════════════════════════════════════
local function ShockEffect()
    if shockActive then return end
    shockActive = true

    local ped      = PlayerPedId()
    local duration = Config.RobDrunkDuration * 1000
    local elapsed  = 0

    if LoadAnimSet('move_m@injured') then
        SetPedMovementClipset(ped, 'move_m@injured', 0.8)
    end

    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.25)
    SetTimecycleModifier('damage')
    SetTimecycleModifierStrength(0.6)
    Notify('~r~You\'re in shock — you\'ve been stabbed!', 'error')

    CreateThread(function()
        while elapsed < duration do
            Wait(200); elapsed = elapsed + 200
            ped = PlayerPedId()
            local p = elapsed / duration
            SetTimecycleModifierStrength(math.max(0.0, (1.0 - p) * 0.6))
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', math.max(0.0, (1.0 - p) * 0.2))
            local stumbleChance = math.floor((1.0 - p) * 10)
            if stumbleChance > 0 and math.random(100) <= stumbleChance then
                SetPedToRagdoll(ped, 600, 600, 0, false, false, false)
            end
        end
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
        ResetPedMovementClipset(ped, 0.5)
        RemoveAnimSet('move_m@injured')
        shockActive = false
        Notify('~y~The shock is fading. Get medical help.', 'error')
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  BLEED EFFECT  (health drain from stab wound)
-- ═══════════════════════════════════════════════════════════════
local function BleedEffect()
    if bleedActive then return end
    bleedActive = true

    local ped       = PlayerPedId()
    local ticks     = math.floor((Config.BleedDuration * 1000) / Config.BleedInterval)
    local ticksDone = 0

    LoadAnimDict('random@domestic')
    if HasAnimDictLoaded('random@domestic') then
        TaskPlayAnim(ped, 'random@domestic', 'idle_a', 3.0, -3.0, 2000, 49, 0, false, false, false)
    end
    Notify('~r~You\'re bleeding out — find medical help!', 'error')

    CreateThread(function()
        while ticksDone < ticks do
            Wait(Config.BleedInterval); ticksDone = ticksDone + 1
            ped = PlayerPedId()
            if IsEntityDead(ped) then break end
            local hp = GetEntityHealth(ped)
            if hp - Config.BleedDamage <= 101 then
                SetEntityHealth(ped, 101); break
            end
            SetEntityHealth(ped, hp - Config.BleedDamage)
            -- Blood-loss screen pulse
            StartScreenEffect('RampMichaelDeathImplosion', 0, false)
            Wait(80)
            StopScreenEffect('RampMichaelDeathImplosion')
            -- Pain anim every 3 ticks
            if ticksDone % 3 == 0 and HasAnimDictLoaded('random@domestic') then
                TaskPlayAnim(ped, 'random@domestic', 'idle_a', 3.0, -3.0, 1500, 49, 0, false, false, false)
            end
            -- Stumble every 5 ticks
            if ticksDone % 5 == 0 then
                SetPedToRagdoll(ped, 400, 400, 0, false, false, false)
            end
        end
        ResetPedMovementClipset(ped, 0.5)
        bleedActive = false
        if not IsEntityDead(ped) then
            Notify('~y~The bleeding is slowing. Get a medkit.', 'error')
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  ANGRY BUYER SEQUENCE
-- ═══════════════════════════════════════════════════════════════
local function AngryBuyer(drugLabel)
    if not currentNPC or not DoesEntityExist(currentNPC) then return end

    local ped    = currentNPC
    local player = PlayerPedId()
    local veh    = GetDriverVehicle()
    npcInCar     = false
    menuOpen     = false
    dialogueOpen = false

    local buyerLabel = currentBuyer and currentBuyer.label or 'Buyer'

    -- Get out
    if veh then TaskLeaveVehicle(ped, veh, 0); Wait(2000) end
    if not DoesEntityExist(ped) then DeleteNPC(); return end

    -- Walk up
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskGoToEntity(ped, player, -1, 1.8, 2.0, 0, 0)

    local waited = 0
    while waited < 6000 do
        Wait(400); waited = waited + 400
        if not DoesEntityExist(ped) then break end
        if #(GetEntityCoords(ped) - GetEntityCoords(player)) < 2.2 then break end
    end
    if not DoesEntityExist(ped) then DeleteNPC(); return end

    TaskTurnPedToFaceEntity(ped, player, 800); Wait(800)

    -- Angry gesture + shout
    if LoadAnimDict('gestures@m@standing@casual') then
        TaskPlayAnim(ped, 'gestures@m@standing@casual', 'gesture_angry', 3.0, -3.0, 3000, 49, 0, false, false, false)
    end
    PlayAmbientSpeech1(ped, 'GENERIC_CURSE_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED', 0)

    local line = Config.AngryLines[math.random(#Config.AngryLines)]:format(drugLabel)
    ShowSubtitle(('~r~[%s] ~w~%s'):format(buyerLabel, line), 4000)
    Wait(3000)

    if not DoesEntityExist(ped) then DeleteNPC(); return end

    local willFight = math.random(100) <= Config.BuyerAngryFightChance

    if willFight then
        Notify('~r~The buyer is coming at you!', 'error')
        SetEntityInvincible(ped, false)
        SetPedCanRagdoll(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAttributes(ped, 5, true)
        SetPedCombatRange(ped, 0)
        SetPedCombatMovement(ped, 2)
        SetPedCombatAbility(ped, 100)
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
        PlayAmbientSpeech1(ped, 'GENERIC_INSULT_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED', 0)
        Wait(300)
        TaskCombatPed(ped, player, 0, 16)

        local fightTimer = 0
        while fightTimer < 30000 do
            Wait(500); fightTimer = fightTimer + 500
            if not DoesEntityExist(ped) then break end
            if IsEntityDead(ped) then
                PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
                Notify('~g~You knocked the buyer out!', 'success')
                break
            end
            if #(GetEntityCoords(ped) - GetEntityCoords(player)) > 25.0 then
                Notify('~y~The buyer backed off.', 'error'); break
            end
        end

        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            ClearPedTasks(ped)
            if LoadAnimSet('move_m@injured') then
                SetPedMovementClipset(ped, 'move_m@injured', 0.5)
            end
            Wait(1500)
        end
    else
        local leaveLines = {
            ('~r~[%s] ~w~Man forget you! I\'m out.'):format(buyerLabel),
            ('~r~[%s] ~w~You\'re a waste of time.'):format(buyerLabel),
            ('~r~[%s] ~w~I\'ll find someone else.'):format(buyerLabel),
        }
        ShowSubtitle(leaveLines[math.random(#leaveLines)], 3000)
        PlayAmbientSpeech1(ped, 'GENERIC_CURSE_MED', 'SPEECH_PARAMS_FORCE', 0)
        Notify('~y~The buyer stormed off.', 'error')

        local pedPos  = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        TaskGoStraightToCoord(ped,
            pedPos.x + 20.0 * math.cos(math.rad(heading + 180)),
            pedPos.y + 20.0 * math.sin(math.rad(heading + 180)),
            pedPos.z, 2.5, 6000, heading + 180, 0.2)
        Wait(5000)
    end

    Wait(1500)
    SafeDeleteEntity(ped)
    currentNPC   = nil
    currentBuyer = nil
    npcInCar     = false
    menuOpen     = false
    dialogueOpen = false
end


-- ═══════════════════════════════════════════════════════════════
--  TRAP TOGGLE
-- ═══════════════════════════════════════════════════════════════
local function StartTrap(mode)
    mode = mode or Config.DefaultSellMode

    -- Validate mode
    if mode ~= 'car' and mode ~= 'window' and mode ~= 'foot' then
        Notify('~r~Unknown mode. Use: /trap car | /trap window | /trap foot', 'error')
        return
    end

    -- Foot mode doesn't need a vehicle
    if mode ~= 'foot' then
        if not GetDriverVehicle() then
            Notify('~r~You must be driving a vehicle for ' .. mode .. ' mode.', 'error')
            return
        end
    else
        if GetDriverVehicle() then
            Notify('~r~Get out of your vehicle to sell on foot.', 'error')
            return
        end
    end

    if trapActive then
        Notify('~o~Trap mode is already ON. Use /trap to stop first.', 'error')
        return
    end

    sellMode   = mode
    trapActive = true
    npcMood    = 0

    local modeLabels = { car = 'Car', window = 'Window', foot = 'On Foot' }
    Notify(('~g~Trap mode ON [%s]. Buyers will approach.'):format(modeLabels[mode]), 'success')
    AddTrapBlip()

    -- Register trunk target zone on the player's current vehicle
    local veh = GetDriverVehicle()
    if veh and TargetLib then
        RegisterTrunkZone(veh)
    end

    CreateThread(function()
        while trapActive do
            SpawnBuyer()
            Wait(Config.SpawnInterval)
        end
    end)
end

local function StopTrap()
    if not trapActive then
        Notify('~o~Trap mode is already OFF.', 'error')
        return
    end

    -- ── Stop the spawn loop ──
    trapActive = false

    -- ── Close any open menus / dialogue ──
    menuOpen     = false
    dialogueOpen = false

    -- ── Dismiss current buyer if one is in the car ──
    if currentNPC and DoesEntityExist(currentNPC) then
        local veh = GetDriverVehicle()
        local buyerLabel = currentBuyer and currentBuyer.label or 'Buyer'
        ShowSubtitle(('~b~[%s] ~w~Alright, I\'m out. Be safe.'):format(buyerLabel), 3000)
        if veh and npcInCar then
            TaskLeaveVehicle(currentNPC, veh, 0)
        end
        -- Give them a moment to exit before deleting
        CreateThread(function()
            Wait(2500)
            DeleteNPC()
        end)
    else
        DeleteNPC()
    end

    -- ── Kill any lingering rob music / audio ──
    CancelMusicEvent('ROBBERY_STING')
    CancelMusicEvent('GETAWAY_DRIVER')
    CancelMusicEvent('HEIST_SETUP_COMPLETE')
    StopAudioScene('FBI_HEIST_FINALE_INTRO_AUDIO_SCENE')

    -- ── Clear any active screen effects / camera shake ──
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)

    -- ── Remove blip + trunk zone ──
    RemoveTrapBlip()
    UnregisterTrunkZone()

    Notify('~r~Trap mode OFF. All sales stopped.', 'error')
end

-- ═══════════════════════════════════════════════════════════════
--  /trap COMMAND
-- ═══════════════════════════════════════════════════════════════
RegisterCommand(Config.TrapCommand, function(source, args)
    local mode = args[1] and string.lower(args[1]) or nil
    if trapActive then
        StopTrap()
    else
        StartTrap(mode)
    end
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.TrapCommand, 'Toggle trap mode. Modes: car, window, foot', {
    { name = 'mode', help = 'car | window | foot  (default: car)' }
})

-- ═══════════════════════════════════════════════════════════════
--  CLIENT EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════

-- Sell drug (fired from sell menu)
RegisterNetEvent('zero-junkies:client:SellDrug')
AddEventHandler('zero-junkies:client:SellDrug', function(data)
    menuOpen = false
    if not npcInCar or not currentNPC or not DoesEntityExist(currentNPC) then
        Notify('~r~No buyer in the car.', 'error')
        return
    end
    local drug = Config.Drugs[data.index]
    if not drug then return end

    -- Apply mood multiplier to price range
    local mult   = data.moodMult or 1.0
    local minP   = math.floor(drug.minPrice * mult)
    local maxP   = math.floor(drug.maxPrice * mult)

    -- Apply buyer-type multiplier on top if available
    local buyer  = currentBuyer
    if buyer then
        minP = math.floor(minP * buyer.priceMultMin)
        maxP = math.floor(maxP * buyer.priceMultMax)
    end

    TriggerServerEvent('zero-junkies:server:SellDrug', {
        item              = drug.item,
        label             = drug.label,
        minPrice          = minP,
        maxPrice          = maxP,
        minAmt            = buyer and buyer.minAmount or drug.minAmount,
        maxAmt            = buyer and buyer.maxAmount or drug.maxAmount,
        policeAlertBonus  = buyer and buyer.policeAlertBonus or 0,
    })
end)

-- Dismiss buyer
RegisterNetEvent('zero-junkies:client:DismissBuyer')
AddEventHandler('zero-junkies:client:DismissBuyer', function()
    menuOpen     = false
    dialogueOpen = false
    local veh = GetDriverVehicle()
    if currentNPC and DoesEntityExist(currentNPC) then
        local buyerLabel = currentBuyer and currentBuyer.label or 'Buyer'
        ShowSubtitle(('~b~[%s] ~w~Alright, I\'m out. Hit me up later.'):format(buyerLabel), 3000)
        if veh then TaskLeaveVehicle(currentNPC, veh, 0) end
        Wait(2500)
        DeleteNPC()
    end
end)

-- Sale confirmed by server
RegisterNetEvent('zero-junkies:client:SaleSuccess')
AddEventHandler('zero-junkies:client:SaleSuccess', function(label, amount, price)
    local buyerLabel = currentBuyer and currentBuyer.label or 'Buyer'
    Notify(('~g~Sold %dx %s to %s for $%d'):format(amount, label, buyerLabel, price), 'success')
    PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true)

    local npc = currentNPC
    local buyer = currentBuyer
    local veh = GetDriverVehicle()
    local playerPed = PlayerPedId()

    if npc and DoesEntityExist(npc) then
        ShowSubtitle(('~b~[%s] ~w~Good looking out. Same time next week.'):format(buyerLabel), 3000)
        PlayAmbientSpeech1(npc, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE', 0)
    end

    -- ── Mode-specific sell animations ────────────────────────────
    if sellMode == 'window' and npc and DoesEntityExist(npc) then
        -- Player reaches hand out window to pass the product
        -- NPC reaches up to receive it
        CreateThread(function()
            if LoadAnimDict('veh@std@ds@base') then
                TaskPlayAnim(playerPed, 'veh@std@ds@base', 'get_out_driver_lhs',
                    4.0, -4.0, 2000, 49, 0, false, false, false)
            end
            if LoadAnimDict('mp_common') then
                TaskPlayAnim(npc, 'mp_common', 'givetake1_b',
                    4.0, -4.0, 2000, 49, 0, false, false, false)
            end
            Wait(2000)
            if DoesEntityExist(npc) then ClearPedTasks(npc) end
            -- NPC walks away from window
            Wait(500)
            if DoesEntityExist(npc) then
                local pedPos  = GetEntityCoords(npc)
                local heading = GetEntityHeading(npc)
                TaskGoStraightToCoord(npc,
                    pedPos.x + 12.0 * math.cos(math.rad(heading + 180)),
                    pedPos.y + 12.0 * math.sin(math.rad(heading + 180)),
                    pedPos.z, 2.5, 5000, heading + 180, 0.2)
                Wait(4000)
                DeleteNPC()
            end
        end)

    elseif sellMode == 'foot' and npc and DoesEntityExist(npc) then
        -- Closing handshake / dap after the deal
        CreateThread(function()
            TaskTurnPedToFaceEntity(npc, playerPed, 500)
            Wait(500)
            if LoadAnimDict('mp_common') then
                TaskPlayAnim(npc, 'mp_common', 'givetake1_a',
                    4.0, -4.0, 2000, 49, 0, false, false, false)
                TaskPlayAnim(playerPed, 'mp_common', 'givetake1_b',
                    4.0, -4.0, 2000, 49, 0, false, false, false)
                Wait(2000)
                ClearPedTasks(playerPed)
            end
            if DoesEntityExist(npc) then
                local pedPos  = GetEntityCoords(npc)
                local heading = GetEntityHeading(npc)
                TaskGoStraightToCoord(npc,
                    pedPos.x + 15.0 * math.cos(math.rad(heading + 180)),
                    pedPos.y + 15.0 * math.sin(math.rad(heading + 180)),
                    pedPos.z, 2.5, 6000, heading + 180, 0.2)
                Wait(5000)
                DeleteNPC()
            end
        end)

    else
        -- Car mode — NPC leaves vehicle normally
        if npc and DoesEntityExist(npc) then
            if veh then TaskLeaveVehicle(npc, veh, 0) end
            Wait(3000)
            DeleteNPC()
        end
    end

    -- ── In-car gun rob chance ─────────────────────────────────────
    -- After a car-mode sale, small chance the buyer pulls a gun
    -- before they leave and demands everything back
    if sellMode == 'car' and npc and DoesEntityExist(npc) then
        if math.random(100) <= (Config.RobChance / 2) then
            CreateThread(function()
                Wait(1500)
                if not DoesEntityExist(npc) then return end

                -- NPC pulls weapon inside the car
                SetEntityInvincible(npc, false)
                SetPedCanRagdoll(npc, true)
                GiveWeaponToPed(npc, GetHashKey('WEAPON_PISTOL'), 30, false, true)
                SetCurrentPedWeapon(npc, GetHashKey('WEAPON_PISTOL'), true)

                -- Aim at player from passenger seat
                TaskAimGunAtEntity(npc, playerPed, 6000, false)
                PlayAmbientSpeech1(npc, 'GENERIC_CURSE_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED', 0)
                ShowSubtitle(('~r~[%s] ~w~Give it ALL back. NOW. Don\'t move!'):format(buyerLabel), 4000)
                Notify('~r~The buyer pulled a gun on you!', 'error')

                -- Screen flash
                StartScreenEffect('SwitchHUDIn', 0, false); Wait(80); StopScreenEffect('SwitchHUDIn')

                Wait(3000)

                -- If NPC still alive — rob fires
                if DoesEntityExist(npc) and not IsEntityDead(npc) then
                    TriggerServerEvent('zero-junkies:server:RobPlayer')
                    ShockEffect()

                    -- NPC gets out and flees
                    if veh then TaskLeaveVehicle(npc, veh, 0) end
                    Wait(2000)
                    SetEntityInvincible(npc, false)
                    SetPedCanRagdoll(npc, true)

                    -- Make mortal so player can chase
                    local pedPos  = GetEntityCoords(playerPed)
                    local heading = GetEntityHeading(playerPed)
                    TaskGoStraightToCoord(npc,
                        pedPos.x + 25.0 * math.cos(math.rad(heading)),
                        pedPos.y + 25.0 * math.sin(math.rad(heading)),
                        pedPos.z, 3.5, 8000, heading, 0.3)

                    Notify('~o~Chase him down!', 'error')

                    -- Kill-watch
                    local deadline = GetGameTimer() + (Config.LootWindowTime * 1000)
                    local killed   = false
                    while GetGameTimer() < deadline do
                        Wait(500)
                        if not DoesEntityExist(npc) then break end
                        if IsEntityDead(npc) then killed = true; break end
                    end

                    if killed then
                        SetPlayerWantedLevel(PlayerId(), Config.KillRobberWanted, false)
                        SetPlayerWantedLevelNow(PlayerId(), false)
                        TriggerServerEvent('zero-junkies:server:RobberKilled')
                        Notify('~g~Got him! Loot the body.', 'success')
                        -- Loot blip
                        local bc = GetEntityCoords(npc)
                        local lb = AddBlipForCoord(bc.x, bc.y, bc.z)
                        SetBlipSprite(lb, 273); SetBlipColour(lb, 1); SetBlipScale(lb, 0.8)
                        SetBlipAsShortRange(lb, true)
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentString('Body')
                        EndTextCommandSetBlipName(lb)
                        Wait(Config.LootWindowTime * 1000)
                        if DoesBlipExist(lb) then RemoveBlip(lb) end
                    end

                    Wait(5000)
                    SafeDeleteEntity(npc)
                    currentNPC = nil
                end
            end)
            return   -- skip normal rob roll below
        end
    end

    -- ── Standard rob chance rolls ─────────────────────────────────
    if math.random(100) <= Config.RobChance then
        Wait(math.random(3000, 8000))
        CreateThread(SpawnRobber)
    end

    if sellMode == 'foot' and math.random(100) <= Config.FootRobChance then
        Wait(math.random(2000, 6000))
        CreateThread(FootRob)
    end
end)

-- No stock — buyer gets angry
RegisterNetEvent('zero-junkies:client:NoStock')
AddEventHandler('zero-junkies:client:NoStock', function(label)
    menuOpen     = false
    dialogueOpen = false
    Notify(('~r~You don\'t have any %s!'):format(label), 'error')
    CreateThread(function() AngryBuyer(label) end)
end)

-- Rob result — stab effects
RegisterNetEvent('zero-junkies:client:RobResult')
AddEventHandler('zero-junkies:client:RobResult', function(cashTaken, drugLines)
    local msg = ('~r~Robbed! Lost $%d cash'):format(cashTaken)
    if #drugLines > 0 then
        msg = msg .. ' and ' .. table.concat(drugLines, ', ')
    end
    Notify(msg, 'error')
    PlaySoundFrontend(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', true)
    ShockEffect()
    BleedEffect()
end)

-- Loot result — drugs recovered from robber body
RegisterNetEvent('zero-junkies:client:LootResult')
AddEventHandler('zero-junkies:client:LootResult', function(recoveredLines)
    if #recoveredLines > 0 then
        Notify('~g~Looted body: recovered ' .. table.concat(recoveredLines, ', '), 'success')
    else
        Notify('~y~Nothing left on the body.', 'error')
    end
    PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true)
end)

-- Police alert (received by on-duty officers)
RegisterNetEvent('zero-junkies:client:PoliceAlert')
AddEventHandler('zero-junkies:client:PoliceAlert', function(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('~r~[DISPATCH] ~w~' .. msg)
    EndTextCommandThefeedPostTicker(false, true)
    PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', true)
end)

-- ═══════════════════════════════════════════════════════════════
--  E KEY INTERACTION LOOP
--  When buyer is in car: press E to open dialogue.
--  Dialogue menu has a "Make the deal" option to sell.
-- ═══════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(0)
        if npcInCar and not menuOpen and not dialogueOpen then
            -- Show context prompt
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to talk to buyer')
            EndTextCommandDisplayHelp(0, false, true, -1)

            if IsControlJustReleased(0, Config.SellKey) then
                OpenDialogueMenu()
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  DRUG USE & ADDICTION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local addictionLevel = 0   -- 0=clean, 1=hooked, 2=dependent, 3=strung out
local useCount       = 0   -- total lifetime uses (drives addiction level)
local lastUseTime    = 0   -- GetGameTimer() at last use (drives withdrawal)
local withdrawalActive = false
local hospitalBlip   = nil

local AddictionLabels = { [0]='Clean', [1]='Hooked', [2]='Dependent', [3]='Strung Out' }

-- ── Lookup a useable drug by item name ──────────────────────────
local function GetUseableDrug(itemName)
    for _, d in ipairs(Config.UseableDrugs) do
        if d.item == itemName then return d end
    end
    return nil
end

-- ── Screen effects per drug type ────────────────────────────────
local function ApplyDrugEffect(effectType, level)
    -- level 1-3 scales intensity
    local intensity = 0.4 + (level * 0.2)   -- 0.6 / 0.8 / 1.0

    if effectType == 'weed' then
        -- Mellow, slow, slightly blurry
        SetTimecycleModifier('drug_flying_base')
        SetTimecycleModifierStrength(intensity * 0.6)
        ShakeGameplayCam('DRUNK_SHAKE', intensity * 0.15)
        -- Slow movement
        if LoadAnimSet('move_m@drunk@slightlydrunk') then
            SetPedMovementClipset(PlayerPedId(), 'move_m@drunk@slightlydrunk', 0.5)
        end

    elseif effectType == 'meth' then
        -- Hyper, twitchy, desaturated
        SetTimecycleModifier('damage')
        SetTimecycleModifierStrength(intensity * 0.5)
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity * 0.1)
        -- Fast movement
        if LoadAnimSet('move_m@brave') then
            SetPedMovementClipset(PlayerPedId(), 'move_m@brave', 0.8)
        end

    elseif effectType == 'coke' then
        -- Sharp, bright, energetic
        SetTimecycleModifier('NG_filmic01')
        SetTimecycleModifierStrength(intensity * 0.7)
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity * 0.08)

    elseif effectType == 'lean' then
        -- Slow, woozy, purple tint
        SetTimecycleModifier('drug_flying_base')
        SetTimecycleModifierStrength(intensity * 0.8)
        ShakeGameplayCam('DRUNK_SHAKE', intensity * 0.25)
        if LoadAnimSet('move_m@drunk@verydrunk') then
            SetPedMovementClipset(PlayerPedId(), 'move_m@drunk@verydrunk', 0.6)
        end

    elseif effectType == 'pill' then
        -- Euphoric, bright flash then warm
        StartScreenEffect('SwitchHUDIn', 0, false)
        Wait(100)
        StopScreenEffect('SwitchHUDIn')
        SetTimecycleModifier('drug_flying_base')
        SetTimecycleModifierStrength(intensity * 0.5)

    elseif effectType == 'tar' then
        -- Heavy, dark, slow — heroin nod
        SetTimecycleModifier('damage')
        SetTimecycleModifierStrength(intensity * 0.9)
        ShakeGameplayCam('DRUNK_SHAKE', intensity * 0.3)
        if LoadAnimSet('move_m@injured') then
            SetPedMovementClipset(PlayerPedId(), 'move_m@injured', 0.7)
        end
    end
end

-- ── Fade out drug effects after duration ────────────────────────
local function FadeDrugEffect(duration)
    local elapsed  = 0
    local interval = 500
    CreateThread(function()
        while elapsed < duration do
            Wait(interval); elapsed = elapsed + interval
            local p = elapsed / duration
            SetTimecycleModifierStrength(math.max(0.0, (1.0 - p) * 0.6))
            ShakeGameplayCam('DRUNK_SHAKE', math.max(0.0, (1.0 - p) * 0.2))
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', math.max(0.0, (1.0 - p) * 0.1))
        end
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
        ResetPedMovementClipset(PlayerPedId(), 0.5)
    end)
end

-- ── Update addiction level from use count ───────────────────────
local function UpdateAddictionLevel()
    local prev = addictionLevel
    if useCount >= Config.AddictionThreshold[3] then
        addictionLevel = 3
    elseif useCount >= Config.AddictionThreshold[2] then
        addictionLevel = 2
    elseif useCount >= Config.AddictionThreshold[1] then
        addictionLevel = 1
    else
        addictionLevel = 0
    end
    if addictionLevel ~= prev and addictionLevel > prev then
        Notify(('~r~Addiction worsened: %s'):format(AddictionLabels[addictionLevel]), 'error')
        TriggerServerEvent('zero-junkies:server:SaveAddiction', useCount, addictionLevel)
    end
end

-- ── Hospital blip ───────────────────────────────────────────────
local function ShowHospitalBlip()
    if hospitalBlip and DoesBlipExist(hospitalBlip) then return end
    hospitalBlip = AddBlipForCoord(Config.HospitalCoords.x, Config.HospitalCoords.y, Config.HospitalCoords.z)
    SetBlipSprite(hospitalBlip, 61)      -- hospital cross
    SetBlipColour(hospitalBlip, 2)       -- green
    SetBlipScale(hospitalBlip, 0.9)
    SetBlipAsShortRange(hospitalBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Hospital — Addiction Treatment')
    EndTextCommandSetBlipName(hospitalBlip)
end

local function HideHospitalBlip()
    if hospitalBlip and DoesBlipExist(hospitalBlip) then RemoveBlip(hospitalBlip) end
    hospitalBlip = nil
end

-- ── Withdrawal debuffs ──────────────────────────────────────────
local function ApplyWithdrawal()
    if addictionLevel == 0 then return end
    local ped = PlayerPedId()
    if IsEntityDead(ped) then return end

    local timeSinceUse = (GetGameTimer() - lastUseTime) / 1000   -- seconds

    -- Withdrawal only kicks in after 5 minutes without using
    if timeSinceUse < 300 then return end

    if addictionLevel == 1 then
        -- Mild: slight shake, small health drain
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
        Wait(300); StopGameplayCamShaking(true)
        local hp = GetEntityHealth(ped)
        if hp - 2 > 101 then SetEntityHealth(ped, hp - 2) end
        Notify('~o~You\'re feeling the itch... you need a fix.', 'error')

    elseif addictionLevel == 2 then
        -- Moderate: vomit anim, health drain, blurry vision
        if LoadAnimDict('mp_player_intupclose_walkup') then
            TaskPlayAnim(ped, 'mp_player_intupclose_walkup', 'idle', 3.0, -3.0, 3000, 49, 0, false, false, false)
        end
        SetTimecycleModifier('damage')
        SetTimecycleModifierStrength(0.4)
        Wait(3000)
        ClearTimecycleModifier()
        local hp = GetEntityHealth(ped)
        if hp - 5 > 101 then SetEntityHealth(ped, hp - 5) end
        ShakeGameplayCam('DRUNK_SHAKE', 0.3)
        Wait(2000); StopGameplayCamShaking(true)
        Notify('~r~Withdrawal is hitting hard. Get to a hospital or use.', 'error')

    elseif addictionLevel == 3 then
        -- Severe: ragdoll, heavy health drain, screen goes dark
        SetTimecycleModifier('damage')
        SetTimecycleModifierStrength(0.8)
        ShakeGameplayCam('DRUNK_SHAKE', 0.6)
        Wait(1000)
        SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
        Wait(2000)
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
        local hp = GetEntityHealth(ped)
        if hp - 10 > 101 then SetEntityHealth(ped, hp - 10) end
        Notify('~r~You\'re strung out. Get to a hospital NOW.', 'error')
        ShowHospitalBlip()
    end
end

-- ── Withdrawal tick loop ─────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(Config.WithdrawalInterval)
        if addictionLevel > 0 then
            ApplyWithdrawal()
        end
    end
end)

-- ── Hospital proximity loop ──────────────────────────────────────
CreateThread(function()
    while true do
        Wait(1000)
        if addictionLevel > 0 then
            local ped  = PlayerPedId()
            local pos  = GetEntityCoords(ped)
            local hpos = Config.HospitalCoords
            local dist = #(vector3(pos.x, pos.y, pos.z) - vector3(hpos.x, hpos.y, hpos.z))

            if dist < Config.HospitalRadius then
                -- Show cure prompt
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(
                    ('Press ~INPUT_CONTEXT~ to treat addiction (%s) — $%d'):format(
                        AddictionLabels[addictionLevel],
                        Config.HospitalCureCost[addictionLevel]
                    )
                )
                EndTextCommandDisplayHelp(0, false, true, -1)

                if IsControlJustReleased(0, Config.SellKey) then
                    TriggerServerEvent('zero-junkies:server:CureAddiction')
                end
            end
        end
    end
end)

-- ── /use command ─────────────────────────────────────────────────
RegisterCommand(Config.DrugUseCommand, function(source, args)
    local itemName = args[1]
    if not itemName then
        Notify('~r~Usage: /' .. Config.DrugUseCommand .. ' [item]  e.g. /use joint2g', 'error')
        return
    end

    local drug = GetUseableDrug(itemName)
    if not drug then
        Notify('~r~That item is not useable.', 'error')
        return
    end

    -- Check player has the item
    TriggerServerEvent('zero-junkies:server:UseDrug', itemName)
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.DrugUseCommand, 'Use a drug from your inventory.', {
    { name = 'item', help = 'Item name e.g. joint2g, meth10g, coke10g' }
})

-- ── Server confirms item exists, client plays the effect ─────────
RegisterNetEvent('zero-junkies:client:DoUseDrug')
AddEventHandler('zero-junkies:client:DoUseDrug', function(itemName)
    local drug = GetUseableDrug(itemName)
    if not drug then return end

    local ped = PlayerPedId()

    -- Play use animation
    if LoadAnimDict(drug.animDict) then
        TaskPlayAnim(ped, drug.animDict, drug.animName,
            3.0, -3.0, drug.animDuration, 49, 0, false, false, false)
    end

    -- Particle effect — smoke
    UseParticleFxAssetNextCall('core')
    local ptfx = StartParticleFxLoopedOnEntity('exp_grd_bzgas_smoke',
        ped, 0.0, 0.0, 0.2, 0.0, 0.0, 0.0, 0.3, false, false, false)

    Wait(drug.animDuration)
    StopParticleFxLooped(ptfx, false)
    ClearPedTasks(ped)

    -- Apply health/stamina boosts
    if drug.healthBoost > 0 then
        local hp = GetEntityHealth(ped)
        SetEntityHealth(ped, math.min(200, hp + drug.healthBoost))
    end
    if drug.staminaBoost then
        RestorePlayerStamina(PlayerId(), 1.0)
    end

    -- Apply screen effect
    ApplyDrugEffect(drug.effect, math.max(1, addictionLevel))

    -- Fade out after 60 seconds
    FadeDrugEffect(60000)

    -- Update addiction
    useCount    = useCount + drug.addictionAdd
    lastUseTime = GetGameTimer()
    UpdateAddictionLevel()

    Notify(('~g~Used %s. Feeling it...'):format(drug.label), 'success')

    -- If clean now, hide hospital blip
    if addictionLevel == 0 then HideHospitalBlip() end
end)

-- ── Server: addiction cured ──────────────────────────────────────
RegisterNetEvent('zero-junkies:client:AddictionCured')
AddEventHandler('zero-junkies:client:AddictionCured', function()
    addictionLevel = 0
    useCount       = 0
    lastUseTime    = 0
    HideHospitalBlip()
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    ResetPedMovementClipset(PlayerPedId(), 0.5)
    Notify('~g~You\'ve been treated. You\'re clean now. Stay that way.', 'success')
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
end)

-- ── Server: not enough money for cure ───────────────────────────
RegisterNetEvent('zero-junkies:client:CureFailed')
AddEventHandler('zero-junkies:client:CureFailed', function(cost)
    Notify(('~r~Not enough cash. Treatment costs $%d.'):format(cost), 'error')
end)

-- ── Server: load saved addiction on join ────────────────────────
RegisterNetEvent('zero-junkies:client:LoadAddiction')
AddEventHandler('zero-junkies:client:LoadAddiction', function(savedUseCount, savedLevel)
    useCount       = savedUseCount or 0
    addictionLevel = savedLevel    or 0
    lastUseTime    = GetGameTimer()   -- reset timer on join
    if addictionLevel > 0 then
        Notify(('~o~Addiction status loaded: %s'):format(AddictionLabels[addictionLevel]), 'error')
        if addictionLevel >= 3 then ShowHospitalBlip() end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  TRUNK / CRAFTING SYSTEM
--  On foot near your vehicle → third-eye prompt on trunk
--  Menu: Open Trunk | Craft Drug | Sell From Trunk
-- ═══════════════════════════════════════════════════════════════

local trunkMenuOpen  = false
local craftingActive = false

-- ── Get the trunk (boot) position of a vehicle ──────────────────
local function GetTrunkCoords(veh)
    -- Offset behind the vehicle based on its heading
    local pos     = GetEntityCoords(veh)
    local heading = GetEntityHeading(veh)
    local len     = GetModelDimensions(GetEntityModel(veh))   -- returns min/max vectors
    -- Approximate trunk: 2.5m behind vehicle centre
    local trunkX = pos.x + 2.5 * math.cos(math.rad(heading + 180))
    local trunkY = pos.y + 2.5 * math.sin(math.rad(heading + 180))
    return vector3(trunkX, trunkY, pos.z)
end

-- ── Open trunk animation ─────────────────────────────────────────
local function OpenTrunkAnim(veh)
    -- Set the boot door open (door index 5 = boot)
    SetVehicleDoorOpen(veh, 5, false, false)
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    Notify('~g~Trunk opened.', 'success')
end

-- ── Craft menu ───────────────────────────────────────────────────
local function OpenCraftMenu(veh)
    if trunkMenuOpen then return end
    trunkMenuOpen = true

    if isQB then
        local options = {
            { header = '🧪 Craft Drugs', isMenuHeader = true },
        }
        for i, recipe in ipairs(Config.CraftRecipes) do
            -- Build ingredient string
            local ingList = {}
            for _, ing in ipairs(recipe.ingredients) do
                ingList[#ingList + 1] = ing.amount .. 'x ' .. ing.item
            end
            options[#options + 1] = {
                header = recipe.label,
                txt    = 'Needs: ' .. table.concat(ingList, ', ') .. '  →  ' .. recipe.outputAmt .. 'x ' .. recipe.output,
                params = {
                    event = 'zero-junkies:client:CraftDrug',
                    args  = { recipeIndex = i },
                },
            }
        end
        options[#options + 1] = {
            header = '← Back',
            txt    = 'Return to trunk menu',
            params = { event = 'zero-junkies:client:OpenTrunkMenu' },
        }
        exports['qb-menu']:openMenu(options)

    elseif isESX then
        local elements = {}
        for i, recipe in ipairs(Config.CraftRecipes) do
            local ingList = {}
            for _, ing in ipairs(recipe.ingredients) do
                ingList[#ingList + 1] = ing.amount .. 'x ' .. ing.item
            end
            elements[#elements + 1] = {
                label = recipe.label .. '  [' .. table.concat(ingList, ' + ') .. ']',
                value = i,
            }
        end
        elements[#elements + 1] = { label = '← Back', value = 0 }

        Framework.UI.Menu.Open('default', GetCurrentResourceName(), 'craft_menu',
            { title = '🧪 Craft Drugs', align = 'top-left', elements = elements },
            function(data, menu)
                menu.close(); trunkMenuOpen = false
                if data.current.value == 0 then
                    TriggerEvent('zero-junkies:client:OpenTrunkMenu')
                else
                    TriggerEvent('zero-junkies:client:CraftDrug', { recipeIndex = data.current.value })
                end
            end,
            function(_, menu) menu.close(); trunkMenuOpen = false end
        )
    end
end

-- ── Main trunk menu ──────────────────────────────────────────────
local function OpenTrunkMenu(veh)
    if trunkMenuOpen then return end
    trunkMenuOpen = true

    if isQB then
        local options = {
            { header = '🚗 Trunk Options', isMenuHeader = true },
            {
                header = '🔓 Open Trunk',
                txt    = 'Pop the boot',
                params = { event = 'zero-junkies:client:TrunkOpen' },
            },
            {
                header = '🧪 Craft Drugs',
                txt    = 'Use ingredients to make product',
                params = { event = 'zero-junkies:client:TrunkCraft' },
            },
            {
                header = '💊 Sell From Trunk',
                txt    = 'Start selling — buyers approach your car',
                params = { event = 'zero-junkies:client:TrunkSell' },
            },
            {
                header = '❌ Close',
                txt    = '',
                params = { event = 'zero-junkies:client:TrunkClose' },
            },
        }
        exports['qb-menu']:openMenu(options)

    elseif isESX then
        local elements = {
            { label = '🔓 Open Trunk',       value = 'open'  },
            { label = '🧪 Craft Drugs',       value = 'craft' },
            { label = '💊 Sell From Trunk',   value = 'sell'  },
            { label = '❌ Close',             value = 'close' },
        }
        Framework.UI.Menu.Open('default', GetCurrentResourceName(), 'trunk_menu',
            { title = '🚗 Trunk Options', align = 'top-left', elements = elements },
            function(data, menu)
                menu.close(); trunkMenuOpen = false
                local v = data.current.value
                if v == 'open'  then TriggerEvent('zero-junkies:client:TrunkOpen')  end
                if v == 'craft' then TriggerEvent('zero-junkies:client:TrunkCraft') end
                if v == 'sell'  then TriggerEvent('zero-junkies:client:TrunkSell')  end
            end,
            function(_, menu) menu.close(); trunkMenuOpen = false end
        )
    end
end

-- ── Trunk menu client events ─────────────────────────────────────
RegisterNetEvent('zero-junkies:client:OpenTrunkMenu')
AddEventHandler('zero-junkies:client:OpenTrunkMenu', function()
    trunkMenuOpen = false
    local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()).x,
                                   GetEntityCoords(PlayerPedId()).y,
                                   GetEntityCoords(PlayerPedId()).z,
                                   Config.TrunkRadius, 0, 70)
    if veh and veh ~= 0 then
        Wait(100); OpenTrunkMenu(veh)
    end
end)

RegisterNetEvent('zero-junkies:client:TrunkOpen')
AddEventHandler('zero-junkies:client:TrunkOpen', function()
    trunkMenuOpen = false
    local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()).x,
                                   GetEntityCoords(PlayerPedId()).y,
                                   GetEntityCoords(PlayerPedId()).z,
                                   Config.TrunkRadius, 0, 70)
    if veh and veh ~= 0 then OpenTrunkAnim(veh) end
end)

RegisterNetEvent('zero-junkies:client:TrunkCraft')
AddEventHandler('zero-junkies:client:TrunkCraft', function()
    trunkMenuOpen = false
    local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()).x,
                                   GetEntityCoords(PlayerPedId()).y,
                                   GetEntityCoords(PlayerPedId()).z,
                                   Config.TrunkRadius, 0, 70)
    if veh and veh ~= 0 then Wait(100); OpenCraftMenu(veh) end
end)

RegisterNetEvent('zero-junkies:client:TrunkSell')
AddEventHandler('zero-junkies:client:TrunkSell', function()
    trunkMenuOpen = false
    -- Start trap in car mode from this vehicle position
    if trapActive then
        Notify('~o~Trap mode is already running.', 'error')
        return
    end
    local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()).x,
                                   GetEntityCoords(PlayerPedId()).y,
                                   GetEntityCoords(PlayerPedId()).z,
                                   Config.TrunkRadius, 0, 70)
    if not veh or veh == 0 then
        Notify('~r~No vehicle found nearby.', 'error')
        return
    end
    -- Warp player into driver seat to enable trap, then allow them to get back out
    Notify('~g~Trunk sell mode — buyers will approach your car.', 'success')
    sellMode   = 'car'
    trapActive = true
    npcMood    = 0
    AddTrapBlip()
    CreateThread(function()
        while trapActive do
            SpawnBuyer()
            Wait(Config.SpawnInterval)
        end
    end)
end)

RegisterNetEvent('zero-junkies:client:TrunkClose')
AddEventHandler('zero-junkies:client:TrunkClose', function()
    trunkMenuOpen = false
end)

-- ── Craft drug event ─────────────────────────────────────────────
RegisterNetEvent('zero-junkies:client:CraftDrug')
AddEventHandler('zero-junkies:client:CraftDrug', function(data)
    trunkMenuOpen = false
    if craftingActive then
        Notify('~o~Already crafting.', 'error')
        return
    end

    local recipe = Config.CraftRecipes[data.recipeIndex]
    if not recipe then return end

    craftingActive = true
    local ped = PlayerPedId()

    -- Play crafting animation
    if LoadAnimDict(recipe.animDict) then
        TaskPlayAnim(ped, recipe.animDict, recipe.animName,
            3.0, -3.0, recipe.craftTime, 49, 0, false, false, false)
    end

    -- Progress bar notification
    Notify(('~y~Crafting %s... (%ds)'):format(recipe.label, math.floor(recipe.craftTime / 1000)), 'error')

    -- Show a simple countdown in subtitles
    CreateThread(function()
        local remaining = recipe.craftTime
        while remaining > 0 do
            Wait(1000); remaining = remaining - 1000
            if remaining > 0 then
                ShowSubtitle(('~y~Crafting: %s — %ds remaining'):format(recipe.label, math.floor(remaining / 1000)), 1100)
            end
        end
    end)

    Wait(recipe.craftTime)
    ClearPedTasks(ped)
    craftingActive = false

    -- Tell server to check ingredients and give output
    TriggerServerEvent('zero-junkies:server:CraftDrug', data.recipeIndex)
end)

-- ── Server confirms craft success ────────────────────────────────
RegisterNetEvent('zero-junkies:client:CraftSuccess')
AddEventHandler('zero-junkies:client:CraftSuccess', function(label, amount)
    Notify(('~g~Crafted %dx %s!'):format(amount, label), 'success')
    PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true)
end)

-- ── Server: missing ingredients ──────────────────────────────────
RegisterNetEvent('zero-junkies:client:CraftFailed')
AddEventHandler('zero-junkies:client:CraftFailed', function(missing)
    Notify(('~r~Missing: %s'):format(missing), 'error')
    craftingActive = false
end)

-- ═══════════════════════════════════════════════════════════════
--  TARGET SYSTEM BOOTSTRAP
--  Detects ox_target or qb-target and wraps them into a single API.
--  AddZone(name, coords, size, options)
--  AddEntityZone(name, entity, options)
--  RemoveZone(name)
-- ═══════════════════════════════════════════════════════════════

local TargetLib = nil   -- 'ox' | 'qb' | nil

local function InitTarget()
    local cfg = string.lower(Config.TargetSystem or 'auto')
    if cfg == 'ox' or (cfg == 'auto' and GetResourceState('ox_target') == 'started') then
        TargetLib = 'ox'
    elseif cfg == 'qb' or (cfg == 'auto' and GetResourceState('qb-target') == 'started') then
        TargetLib = 'qb'
    end
end

CreateThread(function()
    Wait(200)
    InitTarget()
    if TargetLib then
        RegisterStoreZones()
        RegisterYouToolsZone()
    end
end)

-- ── Add a box zone ───────────────────────────────────────────────
local function AddZone(name, coords, size, options)
    if TargetLib == 'ox' then
        exports.ox_target:addBoxZone({
            coords  = coords,
            size    = size,
            options = options,
            debug   = false,
        })
    elseif TargetLib == 'qb' then
        exports['qb-target']:AddBoxZone(name, coords, size.x, size.y, {
            name    = name,
            heading = 0,
            debugPoly = false,
        }, {
            options  = options,
            distance = math.max(size.x, size.y) + 0.5,
        })
    end
end

-- ── Add a zone on a vehicle entity ──────────────────────────────
local function AddEntityZone(name, entity, options)
    if not DoesEntityExist(entity) then return end
    if TargetLib == 'ox' then
        exports.ox_target:addEntityZone(name, entity, {
            options = options,
            debug   = false,
        })
    elseif TargetLib == 'qb' then
        exports['qb-target']:AddTargetEntity(entity, {
            options  = options,
            distance = 2.5,
        })
    end
end

-- ── Remove a zone ────────────────────────────────────────────────
local function RemoveZone(name)
    if TargetLib == 'ox' then
        exports.ox_target:removeZone(name)
    elseif TargetLib == 'qb' then
        exports['qb-target']:RemoveZone(name)
    end
end

local function RemoveEntityZone(name, entity)
    if TargetLib == 'ox' then
        exports.ox_target:removeEntityZone(name)
    elseif TargetLib == 'qb' then
        if entity and DoesEntityExist(entity) then
            exports['qb-target']:RemoveTargetEntity(entity)
        end
    end
end

-- ── Weed store zones ─────────────────────────────────────────────
function RegisterStoreZones()
    for i, loc in ipairs(Config.WeedStoreLocations) do
        AddZone('zj_store_' .. i,
            vector3(loc.x, loc.y, loc.z),
            vector3(2.0, 2.0, 2.0),
            {
                {
                    label   = '🌿 Enter ' .. loc.label,
                    icon    = 'fas fa-cannabis',
                    action  = function()
                        OpenWeedStore()
                    end,
                },
            }
        )
    end
end

-- ── YouTools zone ────────────────────────────────────────────────
function RegisterYouToolsZone()
    local loc = Config.YouToolsLocation
    AddZone('zj_youtools',
        vector3(loc.x, loc.y, loc.z),
        vector3(2.0, 2.0, 2.0),
        {
            {
                label  = '🔧 Buy Trunk Lab Kit — $' .. Config.TrunkLabKitPrice,
                icon   = 'fas fa-toolbox',
                action = function()
                    TriggerServerEvent('zero-junkies:server:BuyTrunkLab')
                end,
            },
        }
    )
end

-- ── Trunk vehicle zone (registered when trap starts) ─────────────
local trunkZoneVeh = nil

function RegisterTrunkZone(veh)
    if not DoesEntityExist(veh) then return end
    trunkZoneVeh = veh

    local labActive    = trunkLabInstalled and labVehicle == veh
                         and GetEntitySpeed(veh) <= (Config.TrunkLabMaxSpeed or 1.0)
    local labInstalled = trunkLabInstalled and labVehicle == veh

    local opts = {
        {
            label  = '🔓 Open Trunk',
            icon   = 'fas fa-car',
            action = function() OpenTrunkAnim(veh) end,
        },
        {
            label  = '🧪 Craft Drugs' .. (labActive and ' [LAB 2x]' or ''),
            icon   = 'fas fa-flask',
            action = function()
                trunkMenuOpen = false
                local la = trunkLabInstalled and labVehicle == veh
                           and GetEntitySpeed(veh) <= (Config.TrunkLabMaxSpeed or 1.0)
                OpenTablet({
                    type      = 'openTablet',
                    view      = 'craft',
                    showTabs  = false,
                    recipes   = Config.CraftRecipes,
                    labActive = la,
                })
            end,
        },
        {
            label  = '💊 Sell From Trunk',
            icon   = 'fas fa-pills',
            action = function() TriggerEvent('zero-junkies:client:TrunkSell') end,
        },
        {
            label    = '🔧 Install Trunk Lab',
            icon     = 'fas fa-wrench',
            canInteract = function()
                return not (trunkLabInstalled and labVehicle == veh)
            end,
            action   = function() TriggerEvent('zero-junkies:client:TrunkInstallLab') end,
        },
    }

    if TargetLib then
        AddEntityZone('zj_trunk_' .. veh, veh, opts)
    end
end

function UnregisterTrunkZone()
    if trunkZoneVeh then
        RemoveEntityZone('zj_trunk_' .. trunkZoneVeh, trunkZoneVeh)
        trunkZoneVeh = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--  BURNER PHONE / DELIVERY SYSTEM
-- ═══════════════════════════════════════════════════════════════

local phoneOpen        = false
local activeDelivery   = nil    -- current delivery order table
local deliveryBlip     = nil
local deliveryTimer    = nil    -- GetGameTimer() deadline
local callCount        = 0      -- total calls made this session (drives intercept chance)

local DeliveryTypeIcons = {
    home   = '🏠',
    office = '🏢',
    corner = '🚦',
    hotel  = '🏨',
}

-- ── Clean up delivery state ──────────────────────────────────────
local function ClearDelivery()
    if deliveryBlip and DoesBlipExist(deliveryBlip) then
        RemoveBlip(deliveryBlip)
    end
    deliveryBlip   = nil
    activeDelivery = nil
    deliveryTimer  = nil
end

-- ── Spawn delivery blip ──────────────────────────────────────────
local function SpawnDeliveryBlip(loc, contactName)
    if deliveryBlip and DoesBlipExist(deliveryBlip) then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(deliveryBlip, 1)        -- standard circle
    SetBlipColour(deliveryBlip, 5)        -- yellow
    SetBlipScale(deliveryBlip, 0.9)
    SetBlipRoute(deliveryBlip, true)      -- GPS route
    SetBlipRouteColour(deliveryBlip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Delivery — ' .. contactName)
    EndTextCommandSetBlipName(deliveryBlip)
end

-- ── Open phone contact list ──────────────────────────────────────
local function OpenPhoneMenu()
    if phoneOpen then return end
    if activeDelivery then
        Notify('~o~You already have an active delivery. Complete it first.', 'error')
        return
    end
    phoneOpen = true

    -- Phone open animation
    if LoadAnimDict('cellphone@in_car@ds') then
        TaskPlayAnim(PlayerPedId(), 'cellphone@in_car@ds', 'cellphone_call_listen_base',
            3.0, -3.0, 3000, 49, 0, false, false, false)
    end
    PlaySoundFrontend(-1, 'Ringtone_Default', 'Phone_SoundSet_Default', true)

    if isQB then
        local options = {
            { header = '📱 Burner Phone — Contacts', isMenuHeader = true },
        }
        for i, contact in ipairs(Config.BurnerContacts) do
            local icon = DeliveryTypeIcons[contact.type] or '📦'
            options[#options + 1] = {
                header = icon .. ' ' .. contact.name .. '  [' .. contact.number .. ']',
                txt    = contact.description .. '  |  $' .. contact.minPay .. '–$' .. contact.maxPay,
                params = {
                    event = 'zero-junkies:client:CallContact',
                    args  = { contactIndex = i },
                },
            }
        end
        options[#options + 1] = {
            header = '❌ Hang Up',
            txt    = 'Close phone',
            params = { event = 'zero-junkies:client:HangUp' },
        }
        exports['qb-menu']:openMenu(options)

    elseif isESX then
        local elements = {}
        for i, contact in ipairs(Config.BurnerContacts) do
            local icon = DeliveryTypeIcons[contact.type] or '📦'
            elements[#elements + 1] = {
                label = icon .. ' ' .. contact.name .. ' — ' .. contact.description,
                value = i,
            }
        end
        elements[#elements + 1] = { label = '❌ Hang Up', value = 0 }

        Framework.UI.Menu.Open('default', GetCurrentResourceName(), 'phone_menu',
            { title = '📱 Burner Phone', align = 'top-left', elements = elements },
            function(data, menu)
                menu.close(); phoneOpen = false
                if data.current.value == 0 then
                    TriggerEvent('zero-junkies:client:HangUp')
                else
                    TriggerEvent('zero-junkies:client:CallContact', { contactIndex = data.current.value })
                end
            end,
            function(_, menu) menu.close(); phoneOpen = false end
        )
    end
end

-- ── Call a contact — place the order ────────────────────────────
local function CallContact(contactIndex)
    phoneOpen = false
    local contact = Config.BurnerContacts[contactIndex]
    if not contact then return end

    -- Increment call count — more calls = higher intercept risk
    callCount = callCount + 1

    -- Check intercept chance
    local interceptRoll = math.random(100)
    local interceptChance = Config.PhoneInterceptChance + (callCount * 2)
    if interceptRoll <= interceptChance then
        -- Cops intercepted the call
        Notify('~r~[BURNER] Line went dead. Might be hot — lay low.', 'error')
        TriggerServerEvent('zero-junkies:server:PhoneIntercept')
        return
    end

    -- Pick random amount and payout
    local amount = math.random(contact.minAmount, contact.maxAmount)
    local pay    = math.random(contact.minPay, contact.maxPay) * amount

    -- Pick random delivery location for this type
    local locs = Config.DeliveryLocations[contact.type]
    local loc  = locs[math.random(#locs)]

    -- Build order
    activeDelivery = {
        contact      = contact,
        amount       = amount,
        pay          = pay,
        location     = loc,
        deadline     = GetGameTimer() + (contact.timeLimit * 1000),
    }

    -- Phone call animation + dialogue
    if LoadAnimDict('cellphone@in_car@ds') then
        TaskPlayAnim(PlayerPedId(), 'cellphone@in_car@ds', 'cellphone_call_listen_base',
            3.0, -3.0, 4000, 49, 0, false, false, false)
    end

    Wait(500)
    ShowSubtitle(('~b~[%s] ~w~Bring me %dx %s. You got %d minutes. %s.'):format(
        contact.name, amount, contact.drugLabel,
        math.floor(contact.timeLimit / 60), loc.label), 6000)
    PlaySoundFrontend(-1, 'Ringtone_Default', 'Phone_SoundSet_Default', true)

    Wait(4000)
    ClearPedTasks(PlayerPedId())

    Notify(('~g~Order from %s: %dx %s → %s  ($%d)'):format(
        contact.name, amount, contact.drugLabel, loc.label, pay), 'success')

    -- Spawn GPS blip
    SpawnDeliveryBlip(loc, contact.name)

    -- Start countdown thread
    CreateThread(function()
        while activeDelivery do
            Wait(1000)
            if not activeDelivery then break end
            local remaining = math.floor((activeDelivery.deadline - GetGameTimer()) / 1000)
            if remaining <= 0 then
                -- Time expired
                ClearDelivery()
                Notify('~r~Delivery failed — ' .. contact.name .. ' stopped answering.', 'error')
                break
            elseif remaining <= 60 then
                -- Last minute warning
                Notify(('~o~Hurry! %ds left to deliver to %s.'):format(remaining, contact.name), 'error')
            end
        end
    end)
end

-- ── Delivery proximity loop ──────────────────────────────────────
CreateThread(function()
    while true do
        Wait(0)
        if activeDelivery then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local loc = activeDelivery.location
            local dist = #(pos - vector3(loc.x, loc.y, loc.z))

            if dist < Config.DeliveryRadius then
                local remaining = math.floor((activeDelivery.deadline - GetGameTimer()) / 1000)
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(
                    ('Press ~INPUT_CONTEXT~ to deliver  [%ds left]'):format(remaining))
                EndTextCommandDisplayHelp(0, false, true, -1)

                if IsControlJustReleased(0, Config.DeliveryKey) then
                    -- Tell server to check inventory and pay
                    TriggerServerEvent('zero-junkies:server:CompleteDelivery', {
                        item         = activeDelivery.contact.drug,
                        amount       = activeDelivery.amount,
                        pay          = activeDelivery.pay,
                        heatChance   = activeDelivery.contact.heatChance,
                        contactName  = activeDelivery.contact.name,
                    })
                    ClearDelivery()
                end
            end
        end
    end
end)

-- ── Client events ────────────────────────────────────────────────
RegisterNetEvent('zero-junkies:client:CallContact')
AddEventHandler('zero-junkies:client:CallContact', function(data)
    CreateThread(function() CallContact(data.contactIndex) end)
end)

RegisterNetEvent('zero-junkies:client:HangUp')
AddEventHandler('zero-junkies:client:HangUp', function()
    phoneOpen = false
    ClearPedTasks(PlayerPedId())
    Notify('~w~Hung up.', 'error')
end)

-- Server: delivery success
RegisterNetEvent('zero-junkies:client:DeliverySuccess')
AddEventHandler('zero-junkies:client:DeliverySuccess', function(contactName, pay)
    Notify(('~g~Delivered! %s paid you $%d. Clean.'):format(contactName, pay), 'success')
    PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true)
    -- Delivery animation — hand off package
    if LoadAnimDict('mp_common') then
        TaskPlayAnim(PlayerPedId(), 'mp_common', 'givetake1_a',
            3.0, -3.0, 2000, 49, 0, false, false, false)
        Wait(2000)
        ClearPedTasks(PlayerPedId())
    end
end)

-- Server: not enough drugs
RegisterNetEvent('zero-junkies:client:DeliveryNoStock')
AddEventHandler('zero-junkies:client:DeliveryNoStock', function(needed, have, label)
    Notify(('~r~You need %dx %s but only have %d.'):format(needed, label, have), 'error')
    -- Restore the delivery so player can go get more
    -- (activeDelivery was already cleared on E press — re-notify)
    Notify('~o~Get the product and come back before time runs out.', 'error')
end)

-- /phone command
RegisterCommand(Config.PhoneCommand, function()
    if activeDelivery then
        -- Show current order status
        local remaining = math.floor((activeDelivery.deadline - GetGameTimer()) / 1000)
        local d = activeDelivery
        Notify(('~y~Active order: %dx %s → %s  $%d  [%ds left]'):format(
            d.amount, d.contact.drugLabel, d.location.label, d.pay, remaining), 'error')
        return
    end
    OpenPhoneMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.PhoneCommand,
    'Open your burner phone to call clients for home/office deliveries.')

-- ═══════════════════════════════════════════════════════════════
--  WEED STORE SYSTEM
-- ═══════════════════════════════════════════════════════════════

local storeMenuOpen = false

local function OpenWeedStore()
    if storeMenuOpen then return end
    storeMenuOpen = true

    if isQB then
        local options = {
            { header = '🌿 Smoke Shop', isMenuHeader = true },
        }
        for i, item in ipairs(Config.WeedStoreItems) do
            options[#options + 1] = {
                header = item.label .. '  — $' .. item.price,
                txt    = item.description,
                params = {
                    event = 'zero-junkies:client:BuyStoreItem',
                    args  = { index = i },
                },
            }
        end
        options[#options + 1] = {
            header = '❌ Leave',
            txt    = '',
            params = { event = 'zero-junkies:client:StoreClose' },
        }
        exports['qb-menu']:openMenu(options)

    elseif isESX then
        local elements = {}
        for i, item in ipairs(Config.WeedStoreItems) do
            elements[#elements + 1] = {
                label = item.label .. '  $' .. item.price .. '  — ' .. item.description,
                value = i,
            }
        end
        elements[#elements + 1] = { label = '❌ Leave', value = 0 }

        Framework.UI.Menu.Open('default', GetCurrentResourceName(), 'weed_store',
            { title = '🌿 Smoke Shop', align = 'top-left', elements = elements },
            function(data, menu)
                menu.close(); storeMenuOpen = false
                if data.current.value > 0 then
                    TriggerEvent('zero-junkies:client:BuyStoreItem', { index = data.current.value })
                end
            end,
            function(_, menu) menu.close(); storeMenuOpen = false end
        )
    end
end

RegisterNetEvent('zero-junkies:client:BuyStoreItem')
AddEventHandler('zero-junkies:client:BuyStoreItem', function(data)
    storeMenuOpen = false
    local item = Config.WeedStoreItems[data.index]
    if not item then return end
    TriggerServerEvent('zero-junkies:server:BuyStoreItem', data.index)
end)

RegisterNetEvent('zero-junkies:client:StoreClose')
AddEventHandler('zero-junkies:client:StoreClose', function()
    storeMenuOpen = false
end)

RegisterNetEvent('zero-junkies:client:StoreBuySuccess')
AddEventHandler('zero-junkies:client:StoreBuySuccess', function(label, price)
    Notify(('~g~Bought %s for $%d.'):format(label, price), 'success')
    PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true)
end)

RegisterNetEvent('zero-junkies:client:StoreBuyFail')
AddEventHandler('zero-junkies:client:StoreBuyFail', function(price)
    Notify(('~r~Not enough cash. Need $%d.'):format(price), 'error')
end)

-- Store zones are registered via target system at init (RegisterStoreZones)
-- Fallback proximity loop for servers without a target system
CreateThread(function()
    if TargetLib then return end   -- target system handles it
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        for _, loc in ipairs(Config.WeedStoreLocations) do
            local dist = #(pos - vector3(loc.x, loc.y, loc.z))
            if dist < (Config.WeedStoreRadius or 4.0) then
                Wait(0)
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to enter ~g~' .. loc.label)
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, Config.SellKey) and not storeMenuOpen then
                    OpenWeedStore()
                end
                break
            end
        end
    end
end)

-- /dispensary command
RegisterCommand(Config.WeedStoreCommand, function()
    OpenWeedStore()
end, false)
TriggerEvent('chat:addSuggestion', '/' .. Config.WeedStoreCommand, 'Open The Cookie Jar dispensary.')

-- ═══════════════════════════════════════════════════════════════
--  ROLLING BLUNT MINIGAME
--  /roll — requires weed4g + rolpaper in inventory
--  Press the correct key sequence to roll a joint.
-- ═══════════════════════════════════════════════════════════════

local rollingActive = false

local function StartRollMinigame()
    if rollingActive then return end

    -- Check items server-side first
    TriggerServerEvent('zero-junkies:server:CheckRollItems')
end

RegisterNetEvent('zero-junkies:client:StartRoll')
AddEventHandler('zero-junkies:client:StartRoll', function()
    if rollingActive then return end
    rollingActive = true

    local ped    = PlayerPedId()
    local cfg    = Config.RollMinigame
    local passed = true

    -- Sit-down / idle animation while rolling
    if LoadAnimDict('amb@world_human_smoking@male@idle_a') then
        TaskPlayAnim(ped, 'amb@world_human_smoking@male@idle_a', 'idle_a',
            2.0, -2.0, -1, 49, 0, false, false, false)
    end

    Notify('~y~Rolling a blunt... follow the prompts!', 'error')
    Wait(1000)

    -- Generate random key sequence
    local sequence = {}
    for i = 1, cfg.steps do
        sequence[i] = cfg.keyPool[math.random(#cfg.keyPool)]
    end

    -- Run through each step
    for step, key in ipairs(sequence) do
        local label = cfg.keyLabels[key] or '?'
        local deadline = GetGameTimer() + cfg.timePerStep
        local pressed  = false

        -- Show prompt
        ShowSubtitle(('~y~Step %d/%d — Press ~INPUT_CONTEXT~ [~b~%s~w~]'):format(
            step, cfg.steps, label), cfg.timePerStep)

        while GetGameTimer() < deadline do
            Wait(0)
            -- Show flashing key hint
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(
                ('Roll step %d/%d — Press ~b~%s'):format(step, cfg.steps, label))
            EndTextCommandDisplayHelp(0, false, true, -1)

            if IsControlJustReleased(0, key) then
                pressed = true
                PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
                break
            end
        end

        if not pressed then
            passed = false
            Notify(('~r~Missed step %d! You fumbled the roll.'):format(step), 'error')
            break
        end

        Wait(200)
    end

    ClearPedTasks(ped)
    rollingActive = false

    if passed then
        -- Success — server gives joint, removes ingredients
        TriggerServerEvent('zero-junkies:server:RollSuccess')
        Notify('~g~Rolled a fat one. Light it up with /use joint2g.', 'success')
        PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true)
    else
        -- Fail — server removes ingredients, no joint
        TriggerServerEvent('zero-junkies:server:RollFail')
        Notify('~r~Wasted the weed. Better luck next time.', 'error')
    end
end)

RegisterNetEvent('zero-junkies:client:RollNoItems')
AddEventHandler('zero-junkies:client:RollNoItems', function(missing)
    Notify('~r~Need to roll: ' .. missing, 'error')
end)

RegisterCommand('roll', function()
    StartRollMinigame()
end, false)
TriggerEvent('chat:addSuggestion', '/roll', 'Roll a blunt using weed4g + rolpaper from your inventory.')

-- ═══════════════════════════════════════════════════════════════
--  TRUNK DRUG LAB SYSTEM
--  Buy kit from YouTools. Install in parked car trunk.
--  Craft drugs 2x faster while car is stationary.
-- ═══════════════════════════════════════════════════════════════

local trunkLabInstalled = false   -- true if player has installed lab in current vehicle
local labVehicle        = nil     -- entity handle of the vehicle with the lab

-- YouTools zone registered via target system at init (RegisterYouToolsZone)
-- Fallback proximity loop for servers without a target system
CreateThread(function()
    if TargetLib then return end   -- target system handles it
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local loc = Config.YouToolsLocation
        local dist = #(pos - vector3(loc.x, loc.y, loc.z))
        if dist < (Config.YouToolsRadius or 5.0) then
            Wait(0)
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to shop at ~y~' .. loc.label)
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustReleased(0, Config.SellKey) then
                TriggerServerEvent('zero-junkies:server:BuyTrunkLab')
            end
        end
    end
end)

RegisterNetEvent('zero-junkies:client:TrunkLabBought')
AddEventHandler('zero-junkies:client:TrunkLabBought', function()
    Notify('~g~Trunk Lab Kit purchased! Get in your car and open the trunk to install it.', 'success')
    PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true)
end)

RegisterNetEvent('zero-junkies:client:TrunkLabBuyFail')
AddEventHandler('zero-junkies:client:TrunkLabBuyFail', function(price)
    Notify(('~r~Need $%d to buy the Trunk Lab Kit.'):format(price), 'error')
end)

-- Install lab from trunk menu (called when player picks "Install Lab" option)
local function InstallTrunkLab()
    local veh = GetClosestVehicle(
        GetEntityCoords(PlayerPedId()).x,
        GetEntityCoords(PlayerPedId()).y,
        GetEntityCoords(PlayerPedId()).z,
        Config.TrunkRadius, 0, 70)

    if not veh or veh == 0 then
        Notify('~r~No vehicle nearby.', 'error'); return
    end

    -- Must be parked
    if GetEntitySpeed(veh) > Config.TrunkLabMaxSpeed then
        Notify('~r~Vehicle must be parked to install the lab.', 'error'); return
    end

    TriggerServerEvent('zero-junkies:server:InstallTrunkLab')
end

RegisterNetEvent('zero-junkies:client:TrunkLabInstalled')
AddEventHandler('zero-junkies:client:TrunkLabInstalled', function()
    local veh = GetClosestVehicle(
        GetEntityCoords(PlayerPedId()).x,
        GetEntityCoords(PlayerPedId()).y,
        GetEntityCoords(PlayerPedId()).z,
        Config.TrunkRadius, 0, 70)

    if veh and veh ~= 0 then
        trunkLabInstalled = true
        labVehicle        = veh
        -- Open trunk door
        SetVehicleDoorOpen(veh, 5, false, false)
    end

    -- Installation animation
    local ped = PlayerPedId()
    if LoadAnimDict('amb@world_human_mechanics@male@base') then
        TaskPlayAnim(ped, 'amb@world_human_mechanics@male@base', 'base',
            3.0, -3.0, 5000, 49, 0, false, false, false)
        Wait(5000)
        ClearPedTasks(ped)
    end

    Notify('~g~Trunk Lab installed! Open trunk menu to craft drugs 2x faster.', 'success')
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
end)

RegisterNetEvent('zero-junkies:client:TrunkLabInstallFail')
AddEventHandler('zero-junkies:client:TrunkLabInstallFail', function(reason)
    Notify('~r~' .. reason, 'error')
end)

-- Override OpenCraftMenu to show lab indicator and use faster times
-- Patch the trunk menu to add Install Lab option when player has the kit
RegisterNetEvent('zero-junkies:client:CheckLabStatus')
AddEventHandler('zero-junkies:client:CheckLabStatus', function(hasKit, hasInstalled)
    if hasKit and not trunkLabInstalled then
        -- Prompt to install
        Notify('~y~You have a Trunk Lab Kit. Open trunk menu to install it.', 'error')
    end
    trunkLabInstalled = hasInstalled
end)

-- Patch trunk menu to add lab options
local _origOpenTrunkMenu = OpenTrunkMenu
OpenTrunkMenu = function(veh)
    if trunkMenuOpen then return end
    trunkMenuOpen = true

    -- Check if car is parked for lab use
    local speed    = GetEntitySpeed(veh)
    local labReady = trunkLabInstalled and labVehicle == veh and speed <= Config.TrunkLabMaxSpeed
    local labTag   = labReady and ' ~g~[LAB ACTIVE]' or ''

    if isQB then
        local options = {
            { header = '🚗 Trunk Options' .. labTag, isMenuHeader = true },
            {
                header = '🔓 Open Trunk',
                txt    = 'Pop the boot',
                params = { event = 'zero-junkies:client:TrunkOpen' },
            },
            {
                header = '🧪 Craft Drugs' .. labTag,
                txt    = labReady and '2x speed — Lab active' or 'Use ingredients to make product',
                params = { event = 'zero-junkies:client:TrunkCraft' },
            },
            {
                header = '💊 Sell From Trunk',
                txt    = 'Start selling — buyers approach your car',
                params = { event = 'zero-junkies:client:TrunkSell' },
            },
            {
                header = '🔧 Install Trunk Lab',
                txt    = trunkLabInstalled and 'Lab already installed' or 'Requires Trunk Lab Kit from YouTools',
                params = { event = 'zero-junkies:client:TrunkInstallLab' },
            },
            {
                header = '❌ Close',
                txt    = '',
                params = { event = 'zero-junkies:client:TrunkClose' },
            },
        }
        exports['qb-menu']:openMenu(options)

    elseif isESX then
        local elements = {
            { label = '🔓 Open Trunk',                                    value = 'open'    },
            { label = '🧪 Craft Drugs' .. labTag,                         value = 'craft'   },
            { label = '💊 Sell From Trunk',                               value = 'sell'    },
            { label = '🔧 Install Trunk Lab',                             value = 'install' },
            { label = '❌ Close',                                         value = 'close'   },
        }
        Framework.UI.Menu.Open('default', GetCurrentResourceName(), 'trunk_menu',
            { title = '🚗 Trunk Options', align = 'top-left', elements = elements },
            function(data, menu)
                menu.close(); trunkMenuOpen = false
                local v = data.current.value
                if v == 'open'    then TriggerEvent('zero-junkies:client:TrunkOpen')       end
                if v == 'craft'   then TriggerEvent('zero-junkies:client:TrunkCraft')      end
                if v == 'sell'    then TriggerEvent('zero-junkies:client:TrunkSell')       end
                if v == 'install' then TriggerEvent('zero-junkies:client:TrunkInstallLab') end
            end,
            function(_, menu) menu.close(); trunkMenuOpen = false end
        )
    end
end

RegisterNetEvent('zero-junkies:client:TrunkInstallLab')
AddEventHandler('zero-junkies:client:TrunkInstallLab', function()
    trunkMenuOpen = false
    if trunkLabInstalled then
        Notify('~o~Lab is already installed in this vehicle.', 'error'); return
    end
    InstallTrunkLab()
end)

-- Patch CraftDrug to use lab speed multiplier when active
local _origCraftDrug = nil
RegisterNetEvent('zero-junkies:client:CraftDrug')
AddEventHandler('zero-junkies:client:CraftDrug', function(data)
    trunkMenuOpen = false
    if craftingActive then Notify('~o~Already crafting.', 'error'); return end

    local recipe = Config.CraftRecipes[data.recipeIndex]
    if not recipe then return end

    -- Check if lab is active in this vehicle
    local veh = GetClosestVehicle(
        GetEntityCoords(PlayerPedId()).x,
        GetEntityCoords(PlayerPedId()).y,
        GetEntityCoords(PlayerPedId()).z,
        Config.TrunkRadius, 0, 70)

    local labBoost = false
    if trunkLabInstalled and veh and veh == labVehicle then
        local speed = GetEntitySpeed(veh)
        if speed <= Config.TrunkLabMaxSpeed then
            labBoost = true
        else
            Notify('~o~Lab requires vehicle to be parked.', 'error')
        end
    end

    local craftTime = labBoost
        and math.floor(recipe.craftTime * Config.TrunkLabSpeedMult)
        or  recipe.craftTime

    craftingActive = true
    local ped = PlayerPedId()

    if LoadAnimDict(recipe.animDict) then
        TaskPlayAnim(ped, recipe.animDict, recipe.animName,
            3.0, -3.0, craftTime, 49, 0, false, false, false)
    end

    local labStr = labBoost and ' ~g~[LAB 2x]' or ''
    Notify(('~y~Crafting %s...%s (%ds)'):format(
        recipe.label, labStr, math.floor(craftTime / 1000)), 'error')

    CreateThread(function()
        local remaining = craftTime
        while remaining > 0 do
            Wait(1000); remaining = remaining - 1000
            if remaining > 0 then
                ShowSubtitle(('~y~Crafting: %s%s — %ds'):format(
                    recipe.label, labStr, math.floor(remaining / 1000)), 1100)
            end
        end
    end)

    Wait(craftTime)
    ClearPedTasks(ped)
    craftingActive = false

    TriggerServerEvent('zero-junkies:server:CraftDrug', data.recipeIndex)
end)

-- ═══════════════════════════════════════════════════════════════
--  RESOURCE CLEANUP
-- ═══════════════════════════════════════════════════════════════
AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    DeleteNPC()
    RemoveTrapBlip()
    UnregisterTrunkZone()
    HideHospitalBlip()
    ClearDelivery()
    StopDialogueCam()
    if savedClothes then RestoreClothes() end
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    ResetPedMovementClipset(PlayerPedId(), 0.5)
    CancelMusicEvent('ROBBERY_STING')
    CancelMusicEvent('GETAWAY_DRIVER')
    CancelMusicEvent('HEIST_SETUP_COMPLETE')
    StopAudioScene('FBI_HEIST_FINALE_INTRO_AUDIO_SCENE')
end)

-- ═══════════════════════════════════════════════════════════════
--  zero-junkies | server/main.lua
--  Supports ESX & QBCore (auto-detected via Config.Framework)
-- ═══════════════════════════════════════════════════════════════

local Framework = nil
local isESX     = false
local isQB      = false

-- ─────────────────────────────────────────────
--  Framework bootstrap
-- ─────────────────────────────────────────────

local function InitFramework()
    local fw = string.lower(Config.Framework)

    if fw == 'esx' or (fw == 'auto' and GetResourceState('es_extended') == 'started') then
        Framework = exports['es_extended']:getSharedObject()
        isESX     = true
    elseif fw == 'qbcore' or (fw == 'auto' and GetResourceState('qb-core') == 'started') then
        Framework = exports['qb-core']:GetCoreObject()
        isQB      = true
    else
        -- ESX legacy callback
        TriggerEvent('esx:getSharedObject', function(obj)
            Framework = obj
            isESX     = true
        end)
    end
end

CreateThread(function()
    Wait(100)
    InitFramework()
end)

-- ─────────────────────────────────────────────
--  Shared helpers
-- ─────────────────────────────────────────────

-- Returns the player object for the given source (framework-agnostic)
local function GetPlayer(src)
    if isQB then
        return Framework.Functions.GetPlayer(src)
    elseif isESX then
        return Framework.GetPlayerFromId(src)
    end
    return nil
end

-- Returns item count from player inventory
local function GetItemCount(player, itemName)
    if isQB then
        local item = player.Functions.GetItemByName(itemName)
        return item and item.amount or 0
    elseif isESX then
        local item = player.getInventoryItem(itemName)
        return item and item.count or 0
    end
    return 0
end

-- Removes items from player inventory
local function RemoveItem(player, itemName, amount)
    if isQB then
        player.Functions.RemoveItem(itemName, amount)
        -- Refresh inventory hotbar
        TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source,
            Framework.Shared.Items[itemName], 'remove')
    elseif isESX then
        player.removeInventoryItem(itemName, amount)
    end
end

-- Adds cash to player
local function AddMoney(player, amount)
    if isQB then
        player.Functions.AddMoney('cash', amount, 'zero-junkies-drug-sale')
    elseif isESX then
        player.addMoney(amount)
    end
end

-- ─────────────────────────────────────────────
--  Police alert helper
-- ─────────────────────────────────────────────

local function TriggerPoliceAlert(sellerName)
    if Config.PoliceAlertChance <= 0 then return end
    if math.random(1, 100) > Config.PoliceAlertChance then return end

    local policeCount = 0
    local policeSources = {}

    if isQB then
        local players = Framework.Functions.GetQBPlayers()
        for _, v in pairs(players) do
            local job = v.PlayerData.job
            if job then
                for _, jobName in ipairs(Config.PoliceJobs) do
                    if job.name == jobName and job.onduty then
                        policeCount = policeCount + 1
                        policeSources[#policeSources + 1] = v.PlayerData.source
                        break
                    end
                end
            end
        end
    elseif isESX then
        local players = Framework.GetExtendedPlayers()
        for _, v in ipairs(players) do
            local job = v.getJob()
            if job then
                for _, jobName in ipairs(Config.PoliceJobs) do
                    if job.name == jobName then
                        policeCount = policeCount + 1
                        policeSources[#policeSources + 1] = v.source
                        break
                    end
                end
            end
        end
    end

    if policeCount < Config.MinPoliceForAlert then return end

    for _, pSrc in ipairs(policeSources) do
        TriggerClientEvent('zero-junkies:client:PoliceAlert', pSrc,
            ('Possible drug transaction near %s'):format(sellerName))
    end
end

-- ─────────────────────────────────────────────
--  Main sell handler
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:SellDrug')
AddEventHandler('zero-junkies:server:SellDrug', function(data)
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local item  = data.item
    local label = data.label

    -- How much does the buyer want?
    local wantedAmt = math.random(data.minAmt, data.maxAmt)
    local haveAmt   = GetItemCount(player, item)

    if haveAmt <= 0 then
        TriggerClientEvent('zero-junkies:client:NoStock', src, label, data.wantedLabel or label)
        return
    end

    -- Sell whatever the player has if less than wanted
    local sellAmt = math.min(wantedAmt, haveAmt)

    -- Payout
    local pricePerUnit = math.random(data.minPrice, data.maxPrice)
    local total        = pricePerUnit * sellAmt

    RemoveItem(player, item, sellAmt)
    AddMoney(player, total)

    TriggerClientEvent('zero-junkies:client:SaleSuccess', src, label, sellAmt, total)

    -- Admin log (QBCore)
    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies Sale', 'green',
            ('**%s** sold **%dx %s** for **$%d**'):format(GetPlayerName(src), sellAmt, label, total))
    end

    -- Police alert — apply bonus chance if buyer type has one
    local alertBonus = data.policeAlertBonus or 0
    local savedChance = Config.PoliceAlertChance
    Config.PoliceAlertChance = math.min(100, savedChance + alertBonus)
    TriggerPoliceAlert(GetPlayerName(src))
    Config.PoliceAlertChance = savedChance
end)

-- ─────────────────────────────────────────────
--  Rob handler
--  Removes a portion of cash and some drugs from the player
-- ─────────────────────────────────────────────

-- Per-player table storing what was stolen so loot is accurate
local stolenGoods = {}   -- [src] = { cashTaken, drugItems = { {item, amount, label} } }

RegisterNetEvent('zero-junkies:server:RobPlayer')
AddEventHandler('zero-junkies:server:RobPlayer', function()
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local cashTaken = 0
    local drugLines = {}
    local drugItems = {}   -- stored for loot recovery

    -- ── Steal cash ──
    if isQB then
        local cash = player.Functions.GetMoney('cash')
        if cash > 0 then
            cashTaken = math.floor(cash * (Config.RobCashPercent / 100))
            if cashTaken > 0 then
                player.Functions.RemoveMoney('cash', cashTaken, 'zero-junkies-rob')
            end
        end
    elseif isESX then
        local cash = player.getMoney()
        if cash > 0 then
            cashTaken = math.floor(cash * (Config.RobCashPercent / 100))
            if cashTaken > 0 then
                player.removeMoney(cashTaken)
            end
        end
    end

    -- ── Steal drugs ──
    for _, drug in ipairs(Config.Drugs) do
        local have = GetItemCount(player, drug.item)
        if have > 0 then
            local take = math.min(math.random(1, Config.RobDrugAmount), have)
            RemoveItem(player, drug.item, take)
            drugLines[#drugLines + 1] = ('%dx %s'):format(take, drug.label)
            drugItems[#drugItems + 1] = { item = drug.item, amount = take, label = drug.label }
        end
    end

    -- Store stolen goods so player can loot them back if they kill the robber
    stolenGoods[src] = { cashTaken = cashTaken, drugItems = drugItems }

    TriggerClientEvent('zero-junkies:client:RobResult', src, cashTaken, drugLines)

    -- Admin log (QBCore)
    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies Rob', 'red',
            ('**%s** was robbed — lost **$%d** cash and drugs: %s')
            :format(GetPlayerName(src), cashTaken, table.concat(drugLines, ', ')))
    end
end)

-- ─────────────────────────────────────────────
--  Robber killed — alert police, log it
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:RobberKilled')
AddEventHandler('zero-junkies:server:RobberKilled', function()
    local src  = source
    local name = GetPlayerName(src)
    TriggerPoliceAlert(name .. ' (SHOTS FIRED / HOMICIDE — suspect armed)')

    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies Robber Killed', 'orange',
            ('**%s** killed the robber'):format(name))
    end
end)

-- ─────────────────────────────────────────────
--  Loot robber body — return stolen drugs
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:LootRobber')
AddEventHandler('zero-junkies:server:LootRobber', function()
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local goods = stolenGoods[src]
    if not goods then
        TriggerClientEvent('zero-junkies:client:LootResult', src, {})
        return
    end

    local recoveredLines = {}

    -- Give back stolen drugs
    for _, entry in ipairs(goods.drugItems or {}) do
        if entry.amount > 0 then
            if isQB then
                player.Functions.AddItem(entry.item, entry.amount)
                TriggerClientEvent('inventory:client:ItemBox', src,
                    Framework.Shared.Items[entry.item], 'add')
            elseif isESX then
                player.addInventoryItem(entry.item, entry.amount)
            end
            recoveredLines[#recoveredLines + 1] = ('%dx %s'):format(entry.amount, entry.label)
        end
    end

    -- Clear the stored loot for this player
    stolenGoods[src] = nil

    TriggerClientEvent('zero-junkies:client:LootResult', src, recoveredLines)

    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies Loot', 'green',
            ('**%s** looted robber body — recovered: %s'):format(
                GetPlayerName(src), table.concat(recoveredLines, ', ')))
    end
end)

-- ─────────────────────────────────────────────
--  Delivery completion — check stock, pay player, alert police
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:CompleteDelivery')
AddEventHandler('zero-junkies:server:CompleteDelivery', function(data)
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local have = GetItemCount(player, data.item)

    if have < data.amount then
        TriggerClientEvent('zero-junkies:client:DeliveryNoStock', src,
            data.amount, have, data.item)
        return
    end

    -- Remove drugs
    RemoveItem(player, data.item, data.amount)

    -- Pay player
    AddMoney(player, data.pay)

    TriggerClientEvent('zero-junkies:client:DeliverySuccess', src,
        data.contactName, data.pay)

    -- Police alert based on contact heat chance
    local savedChance = Config.PoliceAlertChance
    Config.PoliceAlertChance = math.min(100, data.heatChance)
    TriggerPoliceAlert(GetPlayerName(src) .. ' (delivery)')
    Config.PoliceAlertChance = savedChance

    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies Delivery', 'blue',
            ('**%s** delivered **%dx %s** to **%s** for **$%d**'):format(
                GetPlayerName(src), data.amount, data.item, data.contactName, data.pay))
    end
end)

-- ─────────────────────────────────────────────
--  Phone intercept — cops picked up the call
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:PhoneIntercept')
AddEventHandler('zero-junkies:server:PhoneIntercept', function()
    local src = source
    -- Always alert police on intercept
    local policeSources = {}
    if isQB then
        local players = Framework.Functions.GetQBPlayers()
        for _, v in pairs(players) do
            local job = v.PlayerData.job
            if job then
                for _, jobName in ipairs(Config.PoliceJobs) do
                    if job.name == jobName and job.onduty then
                        policeSources[#policeSources + 1] = v.PlayerData.source
                        break
                    end
                end
            end
        end
    elseif isESX then
        local players = Framework.GetExtendedPlayers()
        for _, v in ipairs(players) do
            local job = v.getJob()
            if job then
                for _, jobName in ipairs(Config.PoliceJobs) do
                    if job.name == jobName then
                        policeSources[#policeSources + 1] = v.source
                        break
                    end
                end
            end
        end
    end
    for _, pSrc in ipairs(policeSources) do
        TriggerClientEvent('zero-junkies:client:PoliceAlert', pSrc,
            ('Intercepted burner call from %s — possible drug delivery'):format(GetPlayerName(src)))
    end
end)

-- ─────────────────────────────────────────────
--  Craft drug handler — check ingredients, remove them, give output
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:CraftDrug')
AddEventHandler('zero-junkies:server:CraftDrug', function(recipeIndex)
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local recipe = Config.CraftRecipes[recipeIndex]
    if not recipe then return end

    -- Check all ingredients
    local missing = {}
    for _, ing in ipairs(recipe.ingredients) do
        local have = GetItemCount(player, ing.item)
        if have < ing.amount then
            missing[#missing + 1] = ing.amount .. 'x ' .. ing.item
                .. ' (have ' .. have .. ')'
        end
    end

    if #missing > 0 then
        TriggerClientEvent('zero-junkies:client:CraftFailed', src,
            table.concat(missing, ', '))
        return
    end

    -- Remove ingredients
    for _, ing in ipairs(recipe.ingredients) do
        RemoveItem(player, ing.item, ing.amount)
    end

    -- Give output
    if isQB then
        player.Functions.AddItem(recipe.output, recipe.outputAmt)
        TriggerClientEvent('inventory:client:ItemBox', src,
            Framework.Shared.Items[recipe.output], 'add')
    elseif isESX then
        player.addInventoryItem(recipe.output, recipe.outputAmt)
    end

    TriggerClientEvent('zero-junkies:client:CraftSuccess', src,
        recipe.label, recipe.outputAmt)

    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies Craft', 'blue',
            ('**%s** crafted **%dx %s**'):format(GetPlayerName(src), recipe.outputAmt, recipe.output))
    end
end)

-- ─────────────────────────────────────────────
--  Drug use handler — verify item, remove it, tell client to play effect
-- ─────────────────────────────────────────────

-- In-memory addiction store (persists per session; swap for oxmysql if you want DB persistence)
local playerAddiction = {}   -- [src] = { useCount, level }

RegisterNetEvent('zero-junkies:server:UseDrug')
AddEventHandler('zero-junkies:server:UseDrug', function(itemName)
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    -- Verify player has the item
    local count = GetItemCount(player, itemName)
    if count <= 0 then
        TriggerClientEvent('zero-junkies:client:NoStock', src, itemName)
        return
    end

    -- Remove one unit
    RemoveItem(player, itemName, 1)

    -- Tell client to play the effect
    TriggerClientEvent('zero-junkies:client:DoUseDrug', src, itemName)
end)

-- ─────────────────────────────────────────────
--  Save addiction state (called from client on level change)
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:SaveAddiction')
AddEventHandler('zero-junkies:server:SaveAddiction', function(useCount, level)
    local src = source
    playerAddiction[src] = { useCount = useCount, level = level }
end)

-- ─────────────────────────────────────────────
--  Cure addiction at hospital
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:CureAddiction')
AddEventHandler('zero-junkies:server:CureAddiction', function()
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local data  = playerAddiction[src] or { useCount = 0, level = 0 }
    local level = data.level or 0

    if level == 0 then
        TriggerClientEvent('zero-junkies:client:AddictionCured', src)
        return
    end

    local cost = Config.HospitalCureCost[level] or 500

    -- Check cash
    local hasCash = false
    if isQB then
        hasCash = player.Functions.GetMoney('cash') >= cost
        if hasCash then
            player.Functions.RemoveMoney('cash', cost, 'zero-junkies-hospital')
        end
    elseif isESX then
        hasCash = player.getMoney() >= cost
        if hasCash then
            player.removeMoney(cost)
        end
    end

    if not hasCash then
        TriggerClientEvent('zero-junkies:client:CureFailed', src, cost)
        return
    end

    -- Clear addiction
    playerAddiction[src] = { useCount = 0, level = 0 }
    TriggerClientEvent('zero-junkies:client:AddictionCured', src)

    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies Hospital', 'green',
            ('**%s** cured addiction (level %d) for $%d'):format(GetPlayerName(src), level, cost))
    end
end)

-- ─────────────────────────────────────────────
--  Load addiction on player join
-- ─────────────────────────────────────────────

AddEventHandler('playerJoining', function()
    -- Nothing to load yet — client will request on spawn
end)

RegisterNetEvent('zero-junkies:server:RequestAddiction')
AddEventHandler('zero-junkies:server:RequestAddiction', function()
    local src  = source
    local data = playerAddiction[src] or { useCount = 0, level = 0 }
    TriggerClientEvent('zero-junkies:client:LoadAddiction', src, data.useCount, data.level)
end)

-- Clean up on player drop
AddEventHandler('playerDropped', function()
    playerAddiction[source] = nil
end)

-- ─────────────────────────────────────────────
--  Heat alert — fired from NPC dialogue (heat topic)
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:HeatAlert')
AddEventHandler('zero-junkies:server:HeatAlert', function()
    local src = source
    -- Bypass the normal chance check — this always fires if police are on duty
    local policeSources = {}
    if isQB then
        local players = Framework.Functions.GetQBPlayers()
        for _, v in pairs(players) do
            local job = v.PlayerData.job
            if job then
                for _, jobName in ipairs(Config.PoliceJobs) do
                    if job.name == jobName and job.onduty then
                        policeSources[#policeSources + 1] = v.PlayerData.source
                        break
                    end
                end
            end
        end
    elseif isESX then
        local players = Framework.GetExtendedPlayers()
        for _, v in ipairs(players) do
            local job = v.getJob()
            if job then
                for _, jobName in ipairs(Config.PoliceJobs) do
                    if job.name == jobName then
                        policeSources[#policeSources + 1] = v.source
                        break
                    end
                end
            end
        end
    end
    for _, pSrc in ipairs(policeSources) do
        TriggerClientEvent('zero-junkies:client:PoliceAlert', pSrc,
            ('Suspicious activity reported near %s'):format(GetPlayerName(src)))
    end
end)

-- ─────────────────────────────────────────────
--  Police alert client event (received by cops)
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:client:PoliceAlert')
-- (handled client-side via the notification wrapper — no server logic needed)

-- ─────────────────────────────────────────────
--  Store cart checkout — buy multiple items at once
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:PurchaseCart')
AddEventHandler('zero-junkies:server:PurchaseCart', function(cart)
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    -- Build a lookup of store items by item name
    local storeMap = {}
    for _, si in ipairs(Config.WeedStoreItems) do
        storeMap[si.item] = si
    end

    -- Calculate total
    local total = 0
    for _, entry in ipairs(cart) do
        local si = storeMap[entry.item]
        if si then
            total = total + (si.price * (entry.qty or 1))
        end
    end

    -- Check cash
    local hasCash = false
    if isQB then
        hasCash = player.Functions.GetMoney('cash') >= total
        if hasCash then
            player.Functions.RemoveMoney('cash', total, 'zero-junkies-store')
        end
    elseif isESX then
        hasCash = player.getMoney() >= total
        if hasCash then
            player.removeMoney(total)
        end
    end

    if not hasCash then
        TriggerClientEvent('zero-junkies:client:StoreBuyFail', src, total)
        SendNUIMessage({ type = 'storePurchaseResult', success = false, message = 'Not enough cash.' })
        return
    end

    -- Give all items
    for _, entry in ipairs(cart) do
        local si  = storeMap[entry.item]
        local qty = entry.qty or 1
        if si and qty > 0 then
            if isQB then
                player.Functions.AddItem(si.item, qty)
                TriggerClientEvent('inventory:client:ItemBox', src,
                    Framework.Shared.Items[si.item], 'add')
            elseif isESX then
                player.addInventoryItem(si.item, qty)
            end
        end
    end

    TriggerClientEvent('zero-junkies:client:StoreBuySuccess', src,
        #cart .. ' items', total)

    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies Store', 'blue',
            ('**%s** bought cart for **$%d**'):format(GetPlayerName(src), total))
    end
end)

-- ─────────────────────────────────────────────
--  Weed store purchase (single item — legacy)
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:BuyStoreItem')
AddEventHandler('zero-junkies:server:BuyStoreItem', function(index)
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local item = Config.WeedStoreItems[index]
    if not item then return end

    local hasCash = false
    if isQB then
        hasCash = player.Functions.GetMoney('cash') >= item.price
        if hasCash then
            player.Functions.RemoveMoney('cash', item.price, 'zero-junkies-store')
            player.Functions.AddItem(item.item, 1)
            TriggerClientEvent('inventory:client:ItemBox', src,
                Framework.Shared.Items[item.item], 'add')
        end
    elseif isESX then
        hasCash = player.getMoney() >= item.price
        if hasCash then
            player.removeMoney(item.price)
            player.addInventoryItem(item.item, 1)
        end
    end

    if hasCash then
        TriggerClientEvent('zero-junkies:client:StoreBuySuccess', src, item.label, item.price)
    else
        TriggerClientEvent('zero-junkies:client:StoreBuyFail', src, item.price)
    end
end)

-- ─────────────────────────────────────────────
--  Rolling minigame — check items
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:CheckRollItems')
AddEventHandler('zero-junkies:server:CheckRollItems', function()
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local weed   = GetItemCount(player, 'weed4g')
    local papers = GetItemCount(player, 'rolpaper')
    local missing = {}

    if weed   < 1 then missing[#missing + 1] = '1x weed4g'   end
    if papers < 1 then missing[#missing + 1] = '1x rolpaper' end

    if #missing > 0 then
        TriggerClientEvent('zero-junkies:client:RollNoItems', src,
            table.concat(missing, ' + '))
        return
    end

    -- Items confirmed — start minigame on client
    TriggerClientEvent('zero-junkies:client:StartRoll', src)
end)

-- ─────────────────────────────────────────────
--  Rolling minigame — success
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:RollSuccess')
AddEventHandler('zero-junkies:server:RollSuccess', function()
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    RemoveItem(player, 'weed4g',   1)
    RemoveItem(player, 'rolpaper', 1)

    if isQB then
        player.Functions.AddItem('joint2g', 1)
        TriggerClientEvent('inventory:client:ItemBox', src,
            Framework.Shared.Items['joint2g'], 'add')
    elseif isESX then
        player.addInventoryItem('joint2g', 1)
    end
end)

-- ─────────────────────────────────────────────
--  Rolling minigame — fail (consume ingredients, no output)
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:RollFail')
AddEventHandler('zero-junkies:server:RollFail', function()
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    RemoveItem(player, 'weed4g',   1)
    RemoveItem(player, 'rolpaper', 1)
end)

-- ─────────────────────────────────────────────
--  Buy Trunk Lab Kit from YouTools
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:BuyTrunkLab')
AddEventHandler('zero-junkies:server:BuyTrunkLab', function()
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local price = Config.TrunkLabKitPrice

    -- Check if already owns one
    local has = GetItemCount(player, Config.TrunkLabItem)
    if has > 0 then
        TriggerClientEvent('zero-junkies:client:TrunkLabBuyFail', src, 0)
        TriggerClientEvent('zero-junkies:client:PoliceAlert', src,
            'You already have a Trunk Lab Kit.')
        -- Reuse fail event with price 0 as "already owned" signal
        return
    end

    local hasCash = false
    if isQB then
        hasCash = player.Functions.GetMoney('cash') >= price
        if hasCash then
            player.Functions.RemoveMoney('cash', price, 'zero-junkies-trunklab')
            player.Functions.AddItem(Config.TrunkLabItem, 1)
            TriggerClientEvent('inventory:client:ItemBox', src,
                Framework.Shared.Items[Config.TrunkLabItem], 'add')
        end
    elseif isESX then
        hasCash = player.getMoney() >= price
        if hasCash then
            player.removeMoney(price)
            player.addInventoryItem(Config.TrunkLabItem, 1)
        end
    end

    if hasCash then
        TriggerClientEvent('zero-junkies:client:TrunkLabBought', src)
        if isQB then
            TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies TrunkLab', 'blue',
                ('**%s** bought a Trunk Lab Kit for $%d'):format(GetPlayerName(src), price))
        end
    else
        TriggerClientEvent('zero-junkies:client:TrunkLabBuyFail', src, price)
    end
end)

-- ─────────────────────────────────────────────
--  Install Trunk Lab — verify item, remove it
-- ─────────────────────────────────────────────

RegisterNetEvent('zero-junkies:server:InstallTrunkLab')
AddEventHandler('zero-junkies:server:InstallTrunkLab', function()
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local has = GetItemCount(player, Config.TrunkLabItem)
    if has < 1 then
        TriggerClientEvent('zero-junkies:client:TrunkLabInstallFail', src,
            'You need a Trunk Lab Kit. Buy one from YouTools.')
        return
    end

    RemoveItem(player, Config.TrunkLabItem, 1)
    TriggerClientEvent('zero-junkies:client:TrunkLabInstalled', src)

    if isQB then
        TriggerEvent('qb-log:server:CreateLog', 'drug-sales', 'zero-junkies TrunkLab', 'green',
            ('**%s** installed a Trunk Lab'):format(GetPlayerName(src)))
    end
end)

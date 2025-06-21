ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterCommand("ac130", "user", function(xPlayer, args, showError)
    local hasItem = xPlayer.getInventoryItem("ac130_controller")
    if hasItem and hasItem.count > 0 then
        TriggerClientEvent("bucko_ac130:toggleAC130", xPlayer.source)
    else
        TriggerClientEvent('esx:showNotification', xPlayer.source, "You don't have the AC130 controller item!")
    end
end, false, {help = "Toggle AC130 mode (requires controller item)"})

RegisterNetEvent("bucko_ac130:removeController")
AddEventHandler("bucko_ac130:removeController", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.removeInventoryItem("ac130_controller", 1)
    end
end)

--Variables
local recoltDistance = 10
local timeForRecolt = 4000 --1000 for 1 second
--

local near
local jobId = 1
JOBS = {}
BLIPS = {}

RegisterNetEvent("jobs:getJobs")
RegisterNetEvent("cli:getJobs")
RegisterNetEvent("recolt:updateJobs")

AddEventHandler("recolt:updateJobs", function(id)
    jobId = id
	TriggerServerEvent("jobs:getJobs")
end)

AddEventHandler("playerSpawned", function()
    TriggerServerEvent("jobs:getJobs")
end)

-- Get the list of all jobs in the database and create the blip associated
AddEventHandler("cli:getJobs", function(listJobs)
    JOBS = listJobs
	
	for k, existingBlip in ipairs(BLIPS) do
        RemoveBlip(existingBlip)
    end
	
    Citizen.CreateThread(function()
        for _, item in pairs(JOBS) do
			if(item.job_id == jobId) then
				setBlip(item.fx, item.fy, item.fz, 17)
				setBlip(item.tx, item.ty, item.tz, 18)
				setBlip(item.sx, item.sy, item.sz, 19)
			end
        end
    end)
end)

-- Control if the player of is near of a place of job
function IsNear()
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)
	if(IsPedInAnyVehicle(ply, true) == false) then
		for k, item in ipairs(JOBS) do
			if(item.job_id == jobId or item.job_id == 6) then
				local distance_field = GetDistanceBetweenCoords(item.fx, item.fy, item.fz, plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
				local distance_treatment = GetDistanceBetweenCoords(item.tx, item.ty, item.tz, plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
				local distance_seller = GetDistanceBetweenCoords(item.sx, item.sy, item.sz, plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
				if (distance_field <= recoltDistance) then
					--jobId = k
					return 'field', item
				elseif (distance_treatment <= recoltDistance) then
					--jobId = k
					return 'treatment', item
				elseif (distance_seller <= recoltDistance) then
					--jobId = k
					return 'seller', item
				end
			end
		end
	end
end

-- Display the message of recolting/treating/selling and trigger the associated event(s)
function recolt(text, item, rl)
    if (text == 'Récolte') then
        TriggerEvent("mt:missiontext", text .. ' de ~g~' .. tostring(item.raw_item) .. ' ~s~ en cours ...', timeForRecolt - 800)
        Citizen.Wait(timeForRecolt - 800)
        TriggerEvent("player:receiveItem", tonumber(item.raw_id), 1)
        TriggerEvent("mt:missiontext", rl .. ' ~g~' .. tostring(item.raw_item) .. '~s~...', 800)
    elseif (text == 'Traitement') then
        TriggerEvent("mt:missiontext", text .. ' de ~g~' .. tostring(item.raw_item) .. ' ~s~ en cours ...', timeForRecolt - 800)
        Citizen.Wait(timeForRecolt - 800)
        TriggerEvent("player:looseItem", tonumber(item.raw_id), 1)
        TriggerEvent("player:receiveItem", tonumber(item.treat_id), 1)
        TriggerEvent("mt:missiontext", rl .. ' ~g~' .. tostring(item.treat_item) .. '~s~...', 800)
    elseif (text == 'Vente') then
        TriggerEvent("mt:missiontext", text .. ' de ~g~' .. tostring(item.treat_item) .. ' ~s~ en cours ...', timeForRecolt - 800)
        Citizen.Wait(timeForRecolt - 800)
        TriggerEvent("player:sellItem", tonumber(item.treat_id), tonumber(item.price))
        TriggerEvent("mt:missiontext", rl .. ' ~g~' .. tostring(item.treat_item) .. ' ~s~...', 800)
    end
    Citizen.Wait(800)
end

function setBlip(x, y, z, num)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, tonumber(num))
    SetBlipAsShortRange(blip, true)
	
	local name = ""
	if(tonumber(num) == 17) then
		name = "Récolte"
	else 
		if(tonumber(num) == 18) then
			name = "Traitement"
		else
			name = "Vente"
		end
	end
	
	BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
	
	table.insert(BLIPS, blip)
end

-- Constantly check the position of the player
Citizen.CreateThread(function()
    Citizen.Wait(5000)
    while true do
        Citizen.Wait(1)
        near, item = IsNear()
        if (exports.vdk_inventory:notFull() == true) then
            if (near == 'field' and exports.vdk_inventory:getQuantity(item.raw_id) < item.raw_lim ) then
                recolt('Récolte', item, '+1')
            elseif (near == 'treatment' and exports.vdk_inventory:getQuantity(item.raw_id) > 0 and exports.vdk_inventory:getQuantity(item.treat_id) < item.treat_lim) then
                recolt('Traitement', item, '+1')
            elseif (near == 'seller' and exports.vdk_inventory:getQuantity(item.treat_id) > 0) then
                recolt('Vente', item, '-1')
            end
        else
            if (near == 'treatment' and exports.vdk_inventory:getQuantity(item.raw_id) > 0 and exports.vdk_inventory:getQuantity(item.treat_id) < item.treat_lim) then
                recolt('Traitement', item, '+1')
            elseif (near == 'seller' and exports.vdk_inventory:getQuantity(item.treat_id) > 0) then
                recolt('Vente', item, '-1')
            end
        end
    end
end)

function Chat(debugg)
    TriggerEvent("chatMessage", '', { 0, 0x99, 255 }, tostring(debugg))
end
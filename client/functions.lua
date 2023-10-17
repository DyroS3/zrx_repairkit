local GetVehicleClass = GetVehicleClass
local GetEntityModel = GetEntityModel
local SetVehicleUndriveable = SetVehicleUndriveable
local SetVehicleDoorOpen = SetVehicleDoorOpen
local SetVehicleDoorShut = SetVehicleDoorShut
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local TaskLeaveVehicle = TaskLeaveVehicle
local GetEntityCoords = GetEntityCoords
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsControlJustPressed = IsControlJustPressed
local SetEntityHeading = SetEntityHeading
local GetHeadingFromVector_2d = GetHeadingFromVector_2d
local Wait = Wait
local TriggerServerEvent = TriggerServerEvent
local DoesEntityExist = DoesEntityExist
local vector3 = vector3
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity

RepairVehicle = function(vehicle, index, heading)
    BUSY = true
    local temp = Config.RepairKits[index]

    CreateThread(function()
        while BUSY do
            SetVehicleUndriveable(vehicle, true)
            Wait(1000)
        end
    end)

    if heading then
        SetHeadingToEntity(vehicle)
    end
    SetVehicleDoorOpen(vehicle, 4, false, false)
    CORE.Bridge.notification(Strings.rep_started)

    lib.progressBar({
        duration = temp.usetime,
        label = Strings.rep_progress,
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = temp.anim.dict,
            clip = temp.anim.lib
        },
    })

    BUSY = false
    TaskLeaveVehicle(cache.ped, vehicle, 0)
    SetVehicleDoorShut(vehicle, 4, false)
    SetVehicleUndriveable(vehicle, false)
    CORE.Bridge.notification(Strings.rep_success)
    TriggerServerEvent('zrx_repairkit:server:syncRepair', vehicle, index, NetworkGetNetworkIdFromEntity(vehicle))
end

StartThread = function(index)
    local temp = Config.RepairKits[index]

    if not DoesEntityExist(cache.vehicle) then
        return CORE.Bridge.notification(Strings.not_in_vehicle)
    end

    local vehicle = cache.vehicle
    local carHood = GetWorldPositionOfEntityBone(cache.vehicle, GetEntityBoneIndexByName(cache.vehicle, 'bonnet'))

    if temp.allowedClasses and not temp.allowedClasses[GetVehicleClass(vehicle)] then
        TriggerServerEvent('zrx_repairkit:server:cancelRepair')
        return CORE.Bridge.notification(Strings.rep_wrong)
    end

    if temp.allowedVehicles and not temp.allowedVehicles[GetEntityModel(vehicle)] then
        TriggerServerEvent('zrx_repairkit:server:cancelRepair')
        return CORE.Bridge.notification(Strings.rep_wrong)
    end

    if temp.allowedJobs and not temp.allowedJobs[CORE.Bridge.getVariables().job.name] then
        TriggerServerEvent('zrx_repairkit:server:cancelRepair')
        return CORE.Bridge.notification(Strings.rep_cannot)
    end

    CreateThread(function()
        SHOW = true
        local pedCoords

        print(carHood)
        if type(carHood) == 'vector3' and carHood.x > 0.0 then
            TaskLeaveVehicle(cache.ped, cache.vehicle, 0)
            Wait(1000)

            Config.TextUI('open', Strings.press)

            while SHOW do
                pedCoords = GetEntityCoords(cache.ped)

                if #(vector3(pedCoords.x, pedCoords.y, pedCoords.z) - vector3(carHood.x, carHood.y, carHood.z)) < 2 and
                not IsPedInAnyVehicle(cache.ped, false) and IsControlJustPressed(0, 51) then
                    SHOW = false
                    Config.TextUI('close')
                    RepairVehicle(vehicle, index, true)
                elseif IsPedInAnyVehicle(cache.ped, true) or #(vector3(pedCoords.x, pedCoords.y, pedCoords.z) - vector3(carHood.x, carHood.y, carHood.z)) > 2 then
                    SHOW = false
                    BUSY = false
                    Config.TextUI('close')
                    CORE.Bridge.notification(Strings.rep_error)
                    TriggerServerEvent('zrx_repairkit:server:cancelRepair')
                end

                Wait()
            end
        else
            RepairVehicle(vehicle, index, false)
        end
    end)
end

StartCooldown = function()
    if not Config.Cooldown then return end
    COOLDOWN = true

    CreateThread(function()
        SetTimeout(Config.Cooldown * 1000, function()
            COOLDOWN = false
        end)
    end)
end

SetHeadingToEntity = function(target)
    local carHood = GetWorldPositionOfEntityBone(target, GetEntityBoneIndexByName(target, 'bonnet'))
    local c1, c2 = GetEntityCoords(cache.ped), GetEntityCoords(target)

    if type(carHood) == 'vector3' then
        c2 = carHood
    end

    SetEntityHeading(cache.ped, GetHeadingFromVector_2d(c2.x - c1.x, c2.y - c1.y))
end
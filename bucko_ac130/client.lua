local ESX = nil
local isActive = false
local cam = nil
local camRot = vector3(0.0, 0.0, 0.0)
local camCoords = vector3(0.0, 0.0, 0.0)
local missileCount = 10

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local function Notify(text)
    ESX.ShowNotification(text)
end

local function GetForwardVector(rot)
    local rotRad = vector3(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z))
    local cx = math.cos(rotRad.z)
    local sx = math.sin(rotRad.z)
    local cy = math.cos(rotRad.x)
    local sy = math.sin(rotRad.x)

    return vector3(-sx * cy, cx * cy, sy)
end

local function CreateCamera()
    local playerPed = PlayerPedId()
    camCoords = GetEntityCoords(playerPed) + vector3(0, 0, 50)
    camRot = vector3(-90.0, 0.0, GetEntityHeading(playerPed))

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)
    SetCamFov(cam, 50.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
end

local function DestroyCamera()
    if cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        cam = nil
    end
end

local function DropBomb()
    if missileCount <= 0 then
        Notify("No bombs left! Exiting AC130 mode.")
        isActive = false
        DestroyCamera()
        TriggerServerEvent("bucko_ac130:removeController") -- Remove the controller item here
        return
    end

    missileCount = missileCount - 1

    local camCoordsLocal = GetCamCoord(cam)
    local camRotVec = GetCamRot(cam, 2)
    local forwardVector = GetForwardVector(camRotVec)
    local dropDistance = 50.0 -- distance ahead to drop bomb

    local dropX = camCoordsLocal.x + forwardVector.x * dropDistance
    local dropY = camCoordsLocal.y + forwardVector.y * dropDistance
    local dropZ = camCoordsLocal.z + 50.0 -- starting height above cam

    local foundGround, groundZ = GetGroundZFor_3dCoord(dropX, dropY, dropZ, false)
    if not foundGround then
        groundZ = dropZ - 20.0
    end

    AddExplosion(dropX, dropY, groundZ, 2, 100.0, true, false, 1.0, true)
    PlaySoundFromCoord(-1, "Explosion", dropX, dropY, groundZ, 0, 0, 0, 0)

    Notify("Bomb dropped! Bombs left: " .. missileCount)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isActive and cam then
            local rightAxisX = GetDisabledControlNormal(0, 220)
            local rightAxisY = GetDisabledControlNormal(0, 221)

            camRot = vector3(
                math.max(math.min(camRot.x - rightAxisY * 2.0, 0), -90),
                0,
                (camRot.z + rightAxisX * 2.0) % 360
            )

            local forward = GetDisabledControlNormal(0, 32)
            local backward = GetDisabledControlNormal(0, 33)
            local left = GetDisabledControlNormal(0, 34)
            local right = GetDisabledControlNormal(0, 35)

            local moveVector = vector3(0, 0, 0)
            local rotRadZ = math.rad(camRot.z)

            local forwardVec = vector3(-math.sin(rotRadZ), math.cos(rotRadZ), 0)
            local rightVec = vector3(math.cos(rotRadZ), math.sin(rotRadZ), 0)

            moveVector = moveVector + forwardVec * forward
            moveVector = moveVector - forwardVec * backward
            moveVector = moveVector - rightVec * left
            moveVector = moveVector + rightVec * right

            camCoords = camCoords + moveVector * 0.5

            if IsControlPressed(0, 44) then
                camCoords = camCoords + vector3(0, 0, -0.5)
            elseif IsControlPressed(0, 38) then
                camCoords = camCoords + vector3(0, 0, 0.5)
            end

            SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
            SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)

            local camCoordsLocal = GetCamCoord(cam)
            local camRotVec = GetCamRot(cam, 2)
            local forwardVector = GetForwardVector(camRotVec)
            local aimX = camCoordsLocal.x + forwardVector.x * 50.0
            local aimY = camCoordsLocal.y + forwardVector.y * 50.0
            local aimZ = camCoordsLocal.z + 50.0

            local foundGround, groundZ = GetGroundZFor_3dCoord(aimX, aimY, aimZ, false)
            if not foundGround then groundZ = aimZ - 20.0 end
            local aimCoords = vector3(aimX, aimY, groundZ + 0.5)

            DrawMarker(2, aimCoords.x, aimCoords.y, aimCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                1.0, 1.0, 1.0, 255, 0, 0, 150, false, false, 2, false, nil, nil, false)

            if IsControlJustPressed(0, 22) then
                DropBomb()
            end
        else
            Citizen.Wait(500)
        end
    end
end)

RegisterNetEvent("bucko_ac130:toggleAC130")
AddEventHandler("bucko_ac130:toggleAC130", function()
    if not isActive then
        isActive = true
        missileCount = 10
        CreateCamera()
        Notify("AC130 mode activated! Use WASD to move, mouse/right-stick to aim, SPACE to drop bombs.")
    else
        isActive = false
        DestroyCamera()
        Notify("AC130 mode deactivated.")
    end
end)

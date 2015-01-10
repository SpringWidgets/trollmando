function widget:GetInfo()
    return {
        name      = "Trollmando v1",
        desc      = "Shows commando build range + binds mine build to z key",
        author    = "[teh]decay aka [teh]undertaker aka [DoR]Saruman",
        date      = "10 jan 2015",
        license   = "The BSD License",
        layer     = 0,
        version   = 1,
        enabled   = true  -- loaded by default
    }
end

-- project page on github: https://github.com/SpringWidgets/trollmando

--Changelog
-- v2

local GetUnitPosition     = Spring.GetUnitPosition
local glColor = gl.Color
local glDepthTest = gl.DepthTest
local glDrawGroundCircle  = gl.DrawGroundCircle
local GetUnitDefID = Spring.GetUnitDefID
local spGetAllUnits = Spring.GetAllUnits
local spGetSpectatingState = Spring.GetSpectatingState
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spIsGUIHidden = Spring.IsGUIHidden

local cmdMoveState = CMD.MOVE_STATE
local cmdFireState = CMD.FIRE_STATE

local blastCircleDivs   = 100

local udefTab			= UnitDefs


local coreCommando = UnitDefNames["commando"]

local coreCommandoId = coreCommando.id

local commandos = {}

local spectatorMode = false

function setCommandoToRoamingMode(unitID, unitDefID)
    spGiveOrderToUnit(unitID, cmdFireState, { 0 }, {  })
    spGiveOrderToUnit(unitID, cmdMoveState, { 0 }, {})
end

function isCommando(unitDefID)
    if unitDefID == coreCommandoId then
        return true
    end
    return false
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    if isCommando(unitDefID) then
        commandos[unitID] = true
        setCommandoToRoamingMode(unitID, unitDefID)
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if commandos[unitID] then
        commandos[unitID] = nil
    end
end

function widget:UnitEnteredLos(unitID, unitTeam)
    if not spectatorMode then
        local unitDefID = GetUnitDefID(unitID)
        if isCommando(unitDefID) then
            commandos[unitID] = true
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if isCommando(unitDefID) then
        commandos[unitID] = true
        setCommandoToRoamingMode(unitID, unitDefID)
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    if isCommando(unitDefID) then
        commandos[unitID] = true
        setCommandoToRoamingMode(unitID, unitDefID)
    end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    if isCommando(unitDefID) then
        commandos[unitID] = true
        setCommandoToRoamingMode(unitID, unitDefID)
    end
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
    if not spectatorMode then
        if commandos[unitID] then
            commandos[unitID] = nil
        end
    end
end

function widget:DrawWorldPreUnit()
    local _, specFullView, _ = spGetSpectatingState()

    if not specFullView then
        notInSpecfullmode = true
    else
        if notInSpecfullmode then
            detectSpectatorView()
        end
        notInSpecfullmode = false
    end

    if spIsGUIHidden() then return end

    glDepthTest(true)

    for unitID in pairs(commandos) do
        local x,y,z = GetUnitPosition(unitID)
        local udefId = GetUnitDefID(unitID);
        if udefId ~= nil then
            local udef = udefTab[udefId]

            glColor(1, 0, 0, .7)
            glDrawGroundCircle(x, y, z, udef.buildDistance, blastCircleDivs)

        end
    end
    glDepthTest(false)
end

function widget:PlayerChanged(playerID)
    detectSpectatorView()
    return true
end

function widget:Initialize()
    detectSpectatorView()
    return true
end

function detectSpectatorView()
    local _, _, spec, teamId = spGetPlayerInfo(spGetMyPlayerID())

    if spec then
        spectatorMode = true
    end

    local visibleUnits = spGetAllUnits()
    if visibleUnits ~= nil then
        for _, unitID in ipairs(visibleUnits) do
            local udefId = GetUnitDefID(unitID)
            if udefId ~= nil then
                if isCommando(udefId) then
                    commandos[unitID] = true
                end
            end
        end
    end
end


local binds={
    "bind z buildunit_cormine4",
    "bind shift+z buildunit_cormine4"
}

function widget:Initialize()
    for k,v in ipairs(binds) do
        Spring.SendCommands(v)
    end
end

function widget:Shutdown()
    for k,v in ipairs(binds) do
        Spring.SendCommands("un"..v)
    end
end
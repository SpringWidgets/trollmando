function widget:GetInfo()
    return {
        name      = "Trollmando v2",
        desc      = "Shows commando build range + binds mine build to z key",
        author    = "[teh]decay aka [teh]undertaker aka [DoR]Saruman",
        date      = "14 feb 2015",
        license   = "The BSD License",
        layer     = 0,
        version   = 3,
        enabled   = true  -- loaded by default
    }
end

-- project page on github: https://github.com/SpringWidgets/trollmando

--Changelog
-- v2 [teh]decay fixed some minor bugs
-- v3 Floris Added fade on camera distance changed to thicker and more transparant line style + options + onlyDrawRangeWhenSelected


--------------------------------------------------------------------------------
-- OPTIONS
--------------------------------------------------------------------------------

local onlyDrawRangeWhenSelected	= true
local fadeOnCameraDistance		= true
local showLineGlow 				= true		-- a ticker but faint 2nd line will be drawn underneath	
local opacityMultiplier			= 1.15
local fadeMultiplier			= 0.8		-- lower value: fades out sooner
local circleDivs				= 96		-- detail of range circle

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local GetUnitPosition		= Spring.GetUnitPosition
local glColor				= gl.Color
local glLineWidth 			= gl.LineWidth
local glDepthTest			= gl.DepthTest
local glDrawGroundCircle	= gl.DrawGroundCircle
local GetUnitDefID			= Spring.GetUnitDefID
local spGetAllUnits			= Spring.GetAllUnits
local spGetSpectatingState	= Spring.GetSpectatingState
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGiveOrderToUnit		= Spring.GiveOrderToUnit
local spIsGUIHidden			= Spring.IsGUIHidden
local spGetCameraPosition 	= Spring.GetCameraPosition
local spValidUnitID			= Spring.ValidUnitID
local spGetUnitPosition		= Spring.GetUnitPosition
local spIsSphereInView		= Spring.IsSphereInView
local spIsUnitSelected		= Spring.IsUnitSelected

local cmdMoveState			= CMD.MOVE_STATE
local cmdFireState			= CMD.FIRE_STATE

local udefTab				= UnitDefs


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

function addCommando(unitID, unitDefID)
	
	local udef = udefTab[unitDefID]
	commandos[unitID] = {udef.buildDistance}
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    if isCommando(unitDefID) then
        addCommando(unitID, unitDefID)
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
            addCommando(unitID, unitDefID)
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if not spValidUnitID(unitID) then return end --because units can be created AND destroyed on the same frame, in which case luaui thinks they are destroyed before they are created
	
    if isCommando(unitDefID) then
        addCommando(unitID, unitDefID)
        setCommandoToRoamingMode(unitID, unitDefID)
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    if isCommando(unitDefID) then
        addCommando(unitID, unitDefID)
        setCommandoToRoamingMode(unitID, unitDefID)
    end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    if isCommando(unitDefID) then
        addCommando(unitID, unitDefID)
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

	local camX, camY, camZ = spGetCameraPosition()
	
    glDepthTest(true)
    for unitID, property in pairs(commandos) do
        local x,y,z = GetUnitPosition(unitID)
		if ((onlyDrawRangeWhenSelected and spIsUnitSelected(unitID)) or onlyDrawRangeWhenSelected == false) and spIsSphereInView(x,y,z,property[1]) then
			local xDifference = camX - x
			local yDifference = camY - y
			local zDifference = camZ - z
			local camDistance = math.sqrt(xDifference*xDifference + yDifference*yDifference + zDifference*zDifference)
			
			local lineWidthMinus = (camDistance/2000)
			if lineWidthMinus > 1.8 then
				lineWidthMinus = 1.8
			end
			local lineOpacityMultiplier = 0.85
			if fadeOnCameraDistance then
				lineOpacityMultiplier = (1100/camDistance)*fadeMultiplier
				if lineOpacityMultiplier > 1 then
					lineOpacityMultiplier = 1
				end
			end
			if lineOpacityMultiplier > 0.15 then
				
				if showLineGlow then
					glLineWidth(10)
					glColor(0, 1, 0,  .025*lineOpacityMultiplier*opacityMultiplier)
					glDrawGroundCircle(x, y, z, property[1], circleDivs)
				end
				glLineWidth(2.2-lineWidthMinus)
				glColor(0, 1, 0,  .33*lineOpacityMultiplier*opacityMultiplier)
				glDrawGroundCircle(x, y, z, property[1], circleDivs)
			end
		end
    end
    glDepthTest(false)
end

function widget:PlayerChanged(playerID)
    detectSpectatorView()
    return true
end

function detectSpectatorView()
    local _, _, spec, teamId = spGetPlayerInfo(spGetMyPlayerID())

    if spec then
        spectatorMode = true
    end

    refreshCommandosInfo()
end

function refreshCommandosInfo()
    commandos = {}

    local visibleUnits = spGetAllUnits()
    if visibleUnits ~= nil then
        for _, unitID in ipairs(visibleUnits) do
            local unitDefID = GetUnitDefID(unitID)
            if unitDefID ~= nil then
                if isCommando(unitDefID) then
                    addCommando(unitID, unitDefID)
                end
            end
        end
    end
end

local binds = {
    "bind z buildunit_cormine4",
    "bind shift+z buildunit_cormine4"
}

function widget:Initialize()
    detectSpectatorView()

    for k,v in ipairs(binds) do
        Spring.SendCommands(v)
    end

    return true
end

function widget:Shutdown()
    for k,v in ipairs(binds) do
        Spring.SendCommands("un"..v)
    end
end

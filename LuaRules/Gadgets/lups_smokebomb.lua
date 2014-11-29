--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Smokebomb",
    desc      = "poof",
    author    = "KingRaptor (based on jK code)",
    date      = "2014-11-22",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = not (Game.version:find('91.0') == 1),
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then
  return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- speed ups + some table functions
--

--local tinsert = table.insert
local tinsert = function(tab, insert)
  tab[#tab+1] = insert
end

local type  = type
local pairs = pairs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Lups  --// Lua Particle System
local particleIDs = {}
local initialized = false --// if LUPS isn't started yet, we try it once a gameframe later
local tryloading  = 1     --// try to activate lups if it isn't found

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  «« some basic functions »»
--

local supportedFxs = {}
local function fxSupported(fxclass)
  if (supportedFxs[fxclass]~=nil) then
    return supportedFxs[fxclass]
  else
    supportedFxs[fxclass] = Lups.HasParticleClass(fxclass)
    return supportedFxs[fxclass]
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local smokeFX = {
    speed        = 1,
    count        = 300,
    
    colormap     = {	{0.25, 0.25, 0.25, 0.01},
			{0.4, 0.4, 0.4, 0.01},
			{0.25, 0.25, 0.25, 0.20},
			{0, 0, 0, 0.01} },
    
    life         = 25,
    lifeSpread   = 10,
    --delaySpread  = 900,
    rotSpeed     = 1,
    rotSpeedSpread = -2,
    rotSpread    = 360,	
    size = 30,
    sizeSpread   = 5,
    sizeGrowth   = 2,
    emitVector   = {0,1,0},
    emitRotSpread = 60,
	
    texture      = 'bitmaps/smoke/smoke01.tga',
}

local function SpawnSmoke(px, py, pz, radius, height)
  if (Lups==nil) then return end

  local radius = radius or 40
  local height = height or 40
  local count = count or 60
  
  --// get wind and random values
  local wx, wy, wz = Spring.GetWind()
  wx, wy, wz = wx*0.09, wy*0.09, wz*0.09
  smokeFX.force       = {wx,wy+0.5,wz}

  --// send particles to LUPS
  smokeFX.pos     = {px,py,pz}
  -- FIXME: should be sphere instead of cylinder
  smokeFX.partpos = "r*sin(alpha),h,r*cos(alpha) | alpha=rand()*2*pi, r=rand()*"..radius..", h=rand()*"..height	
  smokeFX.texture = "bitmaps/smoke/smoke0" .. math.random(1,9) .. ".tga"
  smokeFX.count = count
  particleIDs[#particleIDs+1] = Lups.AddParticles('SimpleParticles2',smokeFX)
end

local function SpawnSmokeUnit(unitID,unitDefID)
  local px, py, pz = Spring.GetUnitPosition(unitID)
  local radius = Spring.GetUnitRadius(unitID)
  local height = Spring.GetUnitHeight(unitID)
  count = math.floor(radius*radius/2)
  SpawnSmoke(px, py, pz, radius * 1.4 + 15, height * 1.2 + 5, count)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- morphed
function gadget:UnitDestroyed(unitID,unitDefID)
  local newUnit = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
  if newUnit then
    local newDefID = Spring.GetUnitDefID(newUnit)
    SpawnSmokeUnit(newUnit, newDefID)
  end
end
  
function gadget:UnitCreated(unitID,unitDefID)
  SpawnSmokeUnit(unitID, unitDefID)
end

function gadget:Update()
  if (Spring.GetGameFrame()<1) then 
    return
  end

  Lups  = GG['Lups']
  if (Lups) then
    initialized = true
  else
    return
  end
  GG.LUPS = GG.LUPS or {}
  GG.LUPS.SpawnSmoke = SpawnSmoke
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Shutdown()
  if (initialized) then
    for _,unitFxIDs in pairs(particleIDs) do
      for i=1,#unitFxIDs do
	Lups.RemoveParticles(unitFxIDs[i])
      end    
    end
    particleIDs = {}
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- ActiveSky XP 
-- Version 0.4
-- Carlos Eduardo Sampaio - 2021

-- Description: It get METAR information from activeSkype API
-- Based on SimBrief Helper Plugin


-- Modules
local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")

-- Public Variables
local socket = require "socket"
local http = require "socket.http"
local LIP = require("LIP");
local ActiveSkyXMLFile = "metar_asxp.xml"

local DataASXP = {}
local asxpICAO = ""
local asxpMetar = ""
local asxpTimestamp = 0
local getMetar = false
local changedMetar = true

DataRef("asxpZulu", "sim/time/zulu_time_sec")

if not SUPPORTS_FLOATING_WINDOWS then
  -- to make sure the script doesn't stop old FlyWithLua versions
  logMsg("imgui not supported by your FlyWithLua version")
  return
end

function timeConvert(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "no data";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    return hours..":"..mins
  end
end

function metarGet()
  local webRespose, webStatus = http.request("http://localhost:19285/ActiveSky/API/GetMetarInfoAt?ICAO=" .. asxpICAO)

  if webStatus ~= 200 then
    logMsg("ActiveSky API is not responding OK")
	asxpMetar = "Cannot contact ActiveSky"
    return false
  end

  if asxpMetar == webRespose then
	changedMetar = false
  else
    changedMetar = true
  end 
  
  asxpMetar = webRespose;
  return true
end

function asxp_on_build(sb_wnd, x, y)
  imgui.TextUnformatted(string.format("Airport ICAO"))
  imgui.SameLine()
  
  local changed, tmpICAO = imgui.InputText(" ", asxpICAO, 5)
  if changed then
   asxpICAO = tmpICAO:upper()
  end
  
    -- BUTTON
  if imgui.Button("Get Metar") then
    if asxpICAO ~= nil then
	  if metarGet() then
        asxpTimestamp = timeConvert(asxpZulu)
	  end
	  
	  asxpTimestamp = timeConvert(asxpZulu)
	  getMetar = true
    end
  end
  
  if getMetar then
	if asxpTimestamp ~= "" then
	  imgui.SameLine()
	  
      if changedMetar then
	    imgui.PushStyleColor(imgui.constant.Col.Text, 0xFFFFFF00)
      end
	
	  imgui.TextUnformatted(string.format("  Last Refresh: " .. asxpTimestamp .. "z"))
	  
      if changedMetar then
	    imgui.PopStyleColor()
       end
	end
	
	imgui.TextUnformatted(string.format(" "))
	imgui.TextUnformatted(string.sub(asxpMetar, 0, 67))
	imgui.TextUnformatted(string.sub(asxpMetar, 68, 136))
	imgui.TextUnformatted(string.sub(asxpMetar, 137, 203))
	
  end
end

asxp_wnd = nil
function asxp_show_wnd()
  asxp_wnd = float_wnd_create(500, 150, 1, true)
  --float_wnd_set_imgui_font(asxp_wnd, 2)
  float_wnd_set_title(asxp_wnd, "ActiveSky Metar")
  float_wnd_set_imgui_builder(asxp_wnd, "asxp_on_build")
  float_wnd_set_onclose(asxp_wnd, "asxp_hide_wnd")
end

function asxp_hide_wnd()
  if asxp_wnd then
    float_wnd_destroy(asxp_wnd)
  end
end

asxp_show_only_once = 0
asxp_hide_only_once = 0

function toggle_asxp_helper_interface()
  sb_show_window = not sb_show_window
  if sb_show_window then
    if asxp_show_only_once == 0 then
      asxp_show_wnd()
      asxp_show_only_once = 1
      asxp_hide_only_once = 0
    end
  else
    if asxp_hide_only_once == 0 then
      asxp_hide_wnd()
      asxp_hide_only_once = 1
      asxp_show_only_once = 0
    end
  end
end

add_macro("ActiveSky Metar", "asxp_show_wnd()", "asxp_hide_wnd()", "deactivate")
create_command("FlyWithLua/ActiveSkypeMetar/show_toggle", "open/close ActiveSkype Metar", "toggle_asxp_helper_interface()", "", "")

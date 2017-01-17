--アドオン名（大文字）
local addonName = "KAGURASHOW";
local addonNameLower = string.lower(addonName);
--作者名
local author = "dolls";

--アドオン内で使用する領域を作成。以下、ファイル内のスコープではグローバル変数gでアクセス可
_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][author] = _G["ADDONS"][author] or {};
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {};
local g = _G["ADDONS"][author][addonName];

--設定ファイル保存先
g.settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower);

--ライブラリ読み込み
local acutil = require('acutil');

--デフォルト設定
if not g.loaded then
  g.settings = {
    --有効/無効
    enable = true
  };
end

--lua読み込み時のメッセージ
CHAT_SYSTEM(string.format("%s.lua is loaded", addonName));

function KAGURASHOW_SAVE_SETTINGS()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end

--マップ読み込み時処理（1度だけ）
function KAGURASHOW_ON_INIT(addon, frame)
  g.addon = addon;
  g.frame = frame;

  frame:ShowWindow(0);
  acutil.slashCommand("/"..addonNameLower, KAGURASHOW_PROCESS_COMMAND);
  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
    if err then
      --設定ファイル読み込み失敗時処理
      CHAT_SYSTEM(string.format("[%s] cannot load setting files", addonName));
    else
      --設定ファイル読み込み成功時処理
      g.settings = t;
    end
    g.loaded = true;
  end

  --設定ファイル保存処理
  KAGURASHOW_SAVE_SETTINGS();
  --メッセージ受信登録処理
  addon:RegisterMsg('CAST_END', 'KAGURASHOW_CAST_END');
  addon:RegisterMsg('DYNAMIC_CAST_BEGIN', 'KAGURASHOW_CAST_BEGIN');
  addon:RegisterMsg('DYNAMIC_CAST_END', 'KAGURASHOW_CAST_END');
end

function KAGURASHOW_CAST_BEGIN(frame, msg, argStr, maxTime, isVisivle)
  if (not g.settings.enable) then
    return;
  end
  if (argStr == nil or argStr == "") then
    return;
  end
  if (maxTime == nil or maxTime <= 0) then
    return;
  end
  local skillClass = GetClass("Skill", argStr);
  if (skillClass == nil) then
    return;
  end
  if (skillClass.ClassID ~= 40106 and skillClass.ClassID ~= 41605) then
    return;
  end
  g.skillName = skillClass.Name;
  g.maxTime = maxTime;
  local timer = frame:GetChild("addontimer");
  tolua.cast(timer, "ui::CAddOnTimer");
  timer:SetUpdateScript("KAGURASHOW_UPDATE_CASTTIME");
  timer:SetValue( imcTime.GetDWTime() );
  timer:Start(0.01);
  frame:ShowWindow(isVisivle);
  frame:Invalidate();
end

function KAGURASHOW_CAST_END(frame, msg, argStr, maxTime, isVisivle)
  ui.Chat("!!");
  local timer = frame:GetChild("addontimer");
  tolua.cast(timer, "ui::CAddOnTimer");
  timer:Stop();
end

function KAGURASHOW_UPDATE_CASTTIME(frame)
  local timer = frame:GetChild("addontimer");
  tolua.cast(timer, "ui::CAddOnTimer");
  local time = (imcTime.GetDWTime() - timer:GetValue()) / 1000;
  local maxTime = g.maxTime;
  if (maxTime > time) then
    ui.Chat(string.format("!!casting %s ...%d", g.skillName, math.ceil(maxTime - time)));
  else
    ui.Chat("!!");
    timer:Stop();
    frame:ShowWindow(0);
  end
end

--チャットコマンド処理（acutil使用時）
function KAGURASHOW_PROCESS_COMMAND(command)
  local cmd = "";

  if #command > 0 then
    cmd = table.remove(command, 1);
  else
    local msg = "/kagurashow on|off"
    return ui.MsgBox(msg,"","Nope")
  end

  if cmd == "on" then
    --有効
    g.settings.enable = true;
    CHAT_SYSTEM(string.format("[%s] is enable", addonName));
    KAGURASHOW_SAVESETTINGS();
    return;
  elseif cmd == "off" then
    --無効
    g.settings.enable = false;
    CHAT_SYSTEM(string.format("[%s] is disable", addonName));
    KAGURASHOW_SAVESETTINGS();
    return;
  end
  CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName));
end
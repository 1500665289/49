local tbThing = GameMain:GetMod("ThingHelper"):GetThing("Cg20_Building")

-- 常量定义
local TEMP_ADJUST_INTERVAL = 6.0  -- 温度调节间隔（秒）
local TEMP_PER_ITEM = 25.0        -- 每个物品调节的温度值
local DEFAULT_TARGET_TEMP = 10.0  -- 默认目标温度

function tbThing:OnInit()
    -- 初始化可以留空，或者添加初始化逻辑
end

-- 初始化变量
function tbThing:InitializeVariables()
    if not self._initialized then
        self.Time = 0
        self.WenDu = DEFAULT_TARGET_TEMP
        self.processstepcount = 0
        self.it.StuffCount = 0
        
        -- 获取物品定义
        self.item_Yin_def = ThingMgr:GetDef(g_emThingType.Item, "Item_C20_Yin", false)
        self.item_Yang_def = ThingMgr:GetDef(g_emThingType.Item, "Item_C20_Yang", false)
        self.item_Zero_def = ThingMgr:GetDef(g_emThingType.Item, "Item_C20_Zero", false)
        
        -- 设置建筑属性
        self.it.def.Building.RemovePriceFactor = -1.0
        
        -- 从MOD数据加载保存的温度设置
        self:LoadTemperatureFromModData()
        
        self._initialized = true
    end
end

-- 从MOD数据加载温度设置
function tbThing:LoadTemperatureFromModData()
    local num1 = string.find(self.it.FromMod, "C20T")
    if num1 then
        local tempStr = string.sub(self.it.FromMod, num1 + 4)
        local tempNum = tonumber(tempStr)
        if tempNum then
            self.WenDu = tempNum
        end
    end
end

-- 保存温度设置到MOD数据
function tbThing:SaveTemperatureToModData()
    local tempStr = tostring(math.floor(self.WenDu))
    local num1 = string.find(self.it.FromMod, "C20T")
    
    if num1 then
        self.it.FromMod = string.sub(self.it.FromMod, 1, num1 - 1) .. "C20T" .. tempStr
    else
        self.it.FromMod = self.it.FromMod .. "C20T" .. tempStr
    end
end

-- 计算需要的物品数量和类型
function tbThing:CalculateRequiredItems(temperatureDiff, roomGridCount)
    -- 消除之前调节的影响
    if self.it.StuffCount > 0 then
        local adjustment = self.it.StuffCount * TEMP_PER_ITEM / roomGridCount
        if self.it.StuffDef == self.item_Yang_def then
            temperatureDiff = temperatureDiff + adjustment
        elseif self.it.StuffDef == self.item_Yin_def then
            temperatureDiff = temperatureDiff - adjustment
        end
    end
    
    -- 计算需要的物品数量
    local tempCount = math.abs(temperatureDiff) * roomGridCount / TEMP_PER_ITEM
    local requiredCount = math.floor(tempCount)
    
    -- 确定物品类型
    local itemDef
    if temperatureDiff > 0 then
        itemDef = self.item_Yang_def  -- 需要加热
    elseif temperatureDiff < 0 then
        itemDef = self.item_Yin_def   -- 需要制冷
    else
        itemDef = self.item_Zero_def   -- 温度合适
    end
    
    return requiredCount, itemDef
end

function tbThing:OnStep(dt)
    -- 初始化变量
    self:InitializeVariables()
    
    local it = self.it
    
    -- 只在建筑工作时进行温度调节
    if it.BuildingState == g_emBuildingState.Working and it.AtRoom then
        self.Time = self.Time + dt
        
        -- 达到调节间隔时间
        if self.Time >= TEMP_ADJUST_INTERVAL then
            self:AdjustTemperature()
            self.Time = 0
        end
    end
end

-- 温度调节主逻辑
function tbThing:AdjustTemperature()
    local it = self.it
    local room = it.AtRoom
    
    -- 安全检查
    if not room or not room.m_lisGrids then return end
    
    xlua.private_accessible(CS.XiaWorld.AreaRoom)
    xlua.private_accessible(CS.XiaWorld.Thing)
    
    local mapTemperature = Map:GetGlobleTemperature()
    self.processstepcount = self.processstepcount + 1
    
    -- 重置房间温度计算
    room.m_fTemperature = 0  -- 强制设0清除缓冲变化
    room.m_fTemperatureOffset = room.m_fTemperatureOffset + mapTemperature
    
    -- 第二步进行实际调节
    if self.processstepcount == 2 then
        local temperatureDiff = self.WenDu - room.m_fTemperatureOffset
        
        -- 计算需要的物品
        local requiredCount, itemDef = self:CalculateRequiredItems(
            temperatureDiff, room.m_lisGrids.Count
        )
        
        -- 应用调节
        it.StuffCount = requiredCount
        it.StuffDef = itemDef
        
        -- 重置步骤计数器
        self.processstepcount = 0
        
        -- 调试信息（可选）
        -- self:DebugTemperatureInfo(temperatureDiff, requiredCount)
    end
end

-- 调试信息（开发时使用）
function tbThing:DebugTemperatureInfo(temperatureDiff, requiredCount)
    print(string.format("温度调节: 目标%.1f°C, 温差%.1f°C, 需要%d个物品", 
        self.WenDu, temperatureDiff, requiredCount))
end

function tbThing:OnPutDown()
    -- 确保按钮存在
    self.it:RemoveBtnData("设定")
    self.it:AddBtnData("设定", nil, "bind.luaclass:GetTable():UseCotrolPad()", "调节室温", nil)
end

function tbThing:UseCotrolPad()
    local success, window = pcall(function()
        return GameMain:GetMod("Windows"):GetWindow("C20Window")
    end)
    
    if success and window then
        window:Show()
        window:PadGetData(self)
    else
        print("错误: 无法找到温度控制窗口")
    end
end

function tbThing:C20GetPadData(PadWenDu)
    -- 输入验证
    local newTemp = tonumber(PadWenDu) or DEFAULT_TARGET_TEMP
    newTemp = math.max(-273, math.min(1000, newTemp))  -- 合理温度范围
    
    self.WenDu = newTemp
    self:SaveTemperatureToModData()
    
    -- 立即应用新温度设置
    self.processstepcount = 0
    self.Time = TEMP_ADJUST_INTERVAL  -- 强制立即调节
end

-- 添加销毁时的清理
function tbThing:OnDestroy()
    self.it:RemoveBtnData("设定")
end

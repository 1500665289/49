local Windows = GameMain:GetMod("Windows")
local tbWindow = Windows:CreateWindow("C20Window")

-- 移动端适配常量
local IS_MOBILE = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.IPhonePlayer 
               or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.Android

function tbWindow:OnInit()
    self.window.contentPane = UIPackage.CreateObject("C20UI", "C20Window")
    self.window.closeButton = self:GetChild("C20frame"):GetChild("n5")
    
    -- 移动端适配
    if IS_MOBILE then
        self:AdaptForMobile()
    else
        self.window:Center()  -- PC端居中
    end
    
    self.bnt1 = self:GetChild("C20bnt_1")
    self.InputText_1 = self:GetChild("C20n19")
    
    -- 移动端优化的事件绑定
    if IS_MOBILE then
        self:SetupMobileControls()
    else
        self.bnt1.onClick:Add(OnClick1)
        self.bnt1.data = self
    end
end

-- 移动端适配
function tbWindow:AdaptForMobile()
    -- 窗口大小适配
    self.window:SetSize(400, 300)  -- 更适合手机的大小
    self.window:SetPivot(0.5, 0.5)
    self.window:SetPosition(
        (CS.UnityEngine.Screen.width - 400) * 0.5,
        (CS.UnityEngine.Screen.height - 300) * 0.3  -- 偏上显示，避免键盘遮挡
    )
    
    -- 触摸优化：禁用拖拽（避免误操作）
    self.window.draggable = false
    
    -- 组件大小调整
    if self.InputText_1 then
        self.InputText_1:SetSize(200, 60)  -- 更大的输入框
    end
    if self.bnt1 then
        self.bnt1:SetSize(120, 80)  -- 更大的按钮
    end
end

-- 移动端控件设置
function tbWindow:SetupMobileControls()
    -- 使用触摸优化的事件处理
    self.bnt1.onClick:Add(function(context)
        self:OnMobileConfirmClick()
    end)
    
    -- 输入框优化
    self.InputText_1.onChanged:Add(function(context)
        self:OnInputChanged()
    end)
    
    -- 添加虚拟键盘支持
    self.InputText_1.onFocus:Add(function(context)
        self:OnInputFocus()
    end)
    
    self.InputText_1.onBlur:Add(function(context)
        self:OnInputBlur()
    end)
    
    -- 添加关闭按钮的触摸优化
    if self.window.closeButton then
        self.window.closeButton.onClick:Add(function(context)
            self.window:Hide()
        end)
    end
end

function tbWindow:PadGetData(GameThing)
    self.GameThing = GameThing
    self.PadWenDu = GameThing.WenDu
    
    -- 移动端显示优化
    if IS_MOBILE then
        self.InputText_1.text = tostring(math.floor(self.PadWenDu))
        
        -- 自动聚焦输入框（移动端）
        self:DelayFocusInput()
    else
        self.InputText_1.text = math.floor(self.PadWenDu)
    end
end

-- 延迟聚焦输入框（移动端）
function tbWindow:DelayFocusInput()
    if IS_MOBILE then
        GameMain:GetMod("VSLua"):DelayCall(0.5, function()
            if self.InputText_1 then
                self.InputText_1:RequestFocus()
            end
        end)
    end
end

-- 移动端确认点击
function tbWindow:OnMobileConfirmClick()
    -- 添加触摸反馈
    self:PlayTouchEffect()
    
    local tempnumber = self:GetValidatedTemperature()
    if tempnumber then
        self.PadWenDu = tempnumber
        if self.GameThing and self.GameThing.C20GetPadData then
            self.GameThing:C20GetPadData(self.PadWenDu)
            
            -- 移动端操作完成后自动关闭窗口
            self.window:Hide()
        else
            self:ShowMobileMessage("设备连接失败")
        end
    else
        self:ShowMobileMessage("请输入有效温度")
    end
end

-- 输入验证
function tbWindow:GetValidatedTemperature()
    local text = self.InputText_1.text
    local tempnumber = tonumber(text)
    
    if not tempnumber then
        return nil
    end
    
    -- 温度范围限制（移动端更严格）
    tempnumber = math.max(-50, math.min(50, tempnumber))
    return tempnumber
end

-- 输入变化处理
function tbWindow:OnInputChanged()
    if not IS_MOBILE then return end
    
    local text = self.InputText_1.text
    -- 移动端输入过滤：只允许数字和负号
    local filtered = string.match(text, "[%-%d]*")
    if filtered ~= text then
        self.InputText_1.text = filtered
    end
end

-- 输入框聚焦处理
function tbWindow:OnInputFocus()
    if IS_MOBILE then
        -- 调整窗口位置避免被键盘遮挡
        self.window:SetY(CS.UnityEngine.Screen.height * 0.1)
    end
end

-- 输入框失焦处理
function tbWindow:OnInputBlur()
    if IS_MOBILE then
        -- 恢复窗口位置
        self.window:SetY((CS.UnityEngine.Screen.height - 300) * 0.3)
    end
end

-- 触摸反馈效果
function tbWindow:PlayTouchEffect()
    if IS_MOBILE and self.bnt1 then
        -- 简单的按钮点击动画
        local originalScale = self.bnt1.scale
        self.bnt1.scale = CS.UnityEngine.Vector2(0.9, 0.9)
        
        GameMain:GetMod("VSLua"):DelayCall(0.1, function()
            if self.bnt1 then
                self.bnt1.scale = originalScale
            end
        end)
    end
end

-- 移动端消息提示
function tbWindow:ShowMobileMessage(message)
    if IS_MOBILE then
        -- 使用游戏内的移动端提示系统
        if CS.XiaWorld and CS.XiaWorld.World then
            CS.XiaWorld.World.Instance:ShowMsgBox(message, "提示")
        end
    else
        print(message)
    end
end

-- 窗口生命周期函数
function tbWindow:OnShowUpdate()
    -- 移动端持续适配
    if IS_MOBILE then
        self:CheckScreenOrientation()
    end
end

-- 检查屏幕方向变化
function tbWindow:CheckScreenOrientation()
    if self.lastOrientation ~= CS.UnityEngine.Screen.orientation then
        self.lastOrientation = CS.UnityEngine.Screen.orientation
        self:AdaptForMobile()  -- 重新适配
    end
end

function tbWindow:OnShown()
    if IS_MOBILE then
        self.lastOrientation = CS.UnityEngine.Screen.orientation
    end
end

function tbWindow:OnUpdate(dt)
    -- 可添加其他更新逻辑
end

function tbWindow:OnHide()
    -- 清理资源
    if IS_MOBILE then
        -- 确保输入框失焦
        if self.InputText_1 then
            self.InputText_1:RemoveFocus()
        end
    end
end

-- 保留原有PC端函数（兼容性）
function OnClick1(context)
    local self = context.sender.data
    local tempnumber = tonumber(self.InputText_1.text)
    if tempnumber ~= nil then
        self.PadWenDu = tempnumber
    end
    if self.GameThing and self.GameThing.C20GetPadData then
        self.GameThing:C20GetPadData(self.PadWenDu)
    end
end

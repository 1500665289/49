local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local tbWindow = Windows:CreateWindow("C20Window");
function tbWindow:OnInit()
	self.window.contentPane =  UIPackage.CreateObject("C20UI", "C20Window");--载入UI包里的窗口
	self.window.closeButton = self:GetChild("C20frame"):GetChild("n5");
	self.window:Center();	
	
	self.bnt1 = self:GetChild("C20bnt_1");
	self.bnt1.onClick:Add(OnClick1);
	self.bnt1.data = self;
	
	self.InputText_1 = self:GetChild("C20n19");	
end

function tbWindow:PadGetData(GameThing)
	self.GameThing = GameThing;
	self.PadWenDu = GameThing.WenDu;
	--print(self.PadWenDu);	
	self.InputText_1.text=math.floor(self.PadWenDu);
end

function tbWindow:OnShowUpdate()

end

function tbWindow:OnShown()

end

function tbWindow:OnUpdate(dt)

end

function tbWindow:OnHide()

end

function OnClick1(context)
	local self = context.sender.data;
	local tempnumber=tonumber(self.InputText_1.text);
	if tempnumber~=nil then
		self.PadWenDu = tempnumber;	
	end
	--print(self.PadWenDu);	
	self.GameThing:C20GetPadData(self.PadWenDu);
end


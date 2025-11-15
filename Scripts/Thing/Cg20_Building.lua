local tbThing = GameMain:GetMod("ThingHelper"):GetThing("Cg20_Building");

function tbThing:OnInit()

end

function tbThing:OnStep(dt)
	if self.Time == nil then
		self.Time = 0;
	end
	if self.WenDu == nil then
		self.WenDu = 10.0;
	end
	if self.processstepcount == nil then	
		self.processstepcount = 0;
	end
	
	if self.it.StuffCount == nil then	
		self.it.StuffCount = 0;
	end
	
	if self.item_Yin_def == nil then	
		self.item_Yin_def = ThingMgr:GetDef(g_emThingType.Item,"Item_C20_Yin",false);
		self.item_Yang_def = ThingMgr:GetDef(g_emThingType.Item,"Item_C20_Yang",false);	
		self.item_Zero_def = ThingMgr:GetDef(g_emThingType.Item,"Item_C20_Zero",false);
		self.it.def.Building.RemovePriceFactor=-1.0;
		
		--print(self.it.FromMod);
		local   num1 = string.find(self.it.FromMod,"C20T");
		if num1~=nil then
			local   str1 = string.sub(self.it.FromMod,num1+4,string.len(self.it.FromMod)+1);	
			--print(str1);
			self.WenDu=str1;
			--print(self.WenDu);			
		else
			--self.it.FromMod=self.it.FromMod.."C20T50";	
		end
		--print(self.it.FromMod);		
	end		
		
	local it = self.it;
	if it.BuildingState == g_emBuildingState.Working then
		self.Time = self.Time + dt;
		if (it.AtRoom ~= nil ) then
			if (self.Time>=6) then --必须等待足够长时间，使其数值稳定
				local MapWenDu = Map:GetGlobleTemperature();
				xlua.private_accessible(CS.XiaWorld.AreaRoom);	
				xlua.private_accessible(CS.XiaWorld.Thing);
				
				self.processstepcount=self.processstepcount+1;	
				
				--print(it.AtRoom.m_fTemperature);		
				--print(it.AtRoom.m_fTemperatureOffset);

				it.AtRoom.m_fTemperature=0;--强制设0让游戏去掉缓冲变化,在下一次步进时m_fTemperatureOffset会得到正确值，设值，循环到第一步
				--if self.processstepcount==1 then--这里要消去将m_fTemperature设0带来的数值跳动影响
				it.AtRoom.m_fTemperatureOffset=it.AtRoom.m_fTemperatureOffset+MapWenDu;
				if self.processstepcount==2 then
					local wenducha=self.WenDu-it.AtRoom.m_fTemperatureOffset;--     -MapWenDu;
					if it.StuffCount>0 then    --消除上一次调整温度代入游戏运算后的影响，得到真正没有香炉时的温度差
						if it.StuffDef== self.item_Yang_def then
							wenducha=wenducha+it.StuffCount*25/it.AtRoom.m_lisGrids.Count;
						elseif it.StuffDef== self.item_Yin_def then
							wenducha=wenducha-it.StuffCount*25/it.AtRoom.m_lisGrids.Count;							
						end					
					end				
					
					local tempcount=math.abs(wenducha)*it.AtRoom.m_lisGrids.Count/25;
					it.StuffCount=math.floor(tempcount);			
					--print(wenducha);
					if wenducha>0 then
						it.StuffDef= self.item_Yang_def;
					elseif wenducha<0 then
						it.StuffDef= self.item_Yin_def;
					elseif wenducha==0 then
						it.StuffDef= self.item_Zero_def;						
					end		
					--print(it.StuffCount);
					self.processstepcount=0;					
				end
				self.Time = 0;
			end
		end
	end
end

function tbThing:OnPutDown()
	self.it:RemoveBtnData("设定", nil, "bind.luaclass:GetTable():UseCotrolPad()", "调节室温", nil);
	self.it:AddBtnData("设定", nil, "bind.luaclass:GetTable():UseCotrolPad()", "调节室温", nil);
end

function tbThing:UseCotrolPad()
	local xWindow = GameMain:GetMod("Windows"):GetWindow("C20Window");
	--xWindow:Hide();
	xWindow:Show();
	xWindow:PadGetData(self);
end

function tbThing:C20GetPadData(PadWenDu)
	self.WenDu = PadWenDu;
	--print(self.it.FromMod);
	local   str1 = math.floor(self.WenDu);
	--print(str1);
	local   num1 = string.find(self.it.FromMod,"C20T");
	if num1~=nil then		
		self.it.FromMod=string.sub(self.it.FromMod,1,num1-1);	
		self.it.FromMod=self.it.FromMod.."C20T"..str1;	
	else
		self.it.FromMod=self.it.FromMod.."C20T"..str1;	
	end
	--print(self.it.FromMod);		
end

print("Library loading")

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid : Humanoid = Character:WaitForChild("Humanoid")

local RunService = game:GetService("RunService")

local Library = {}

--//Self variables
Library.Player = Player
Library.Character = Character
Library.Humanoid = Character:WaitForChild("Humanoid")

Library.Communications = {}

Library.Events = {
	Communications = {
		NewMessage = {
			Connections = {}
		}	
	}
}

function Library.Events.Communications.NewMessage:Connect(func : RBXScriptConnection)
	table.insert(self.Connections, func)
end

function Library.Events.Communications.NewMessage:Invoke(args : {})
	if #self.Connections > 0 then
		for _, func in self.Connections do
			func(unpack(args))
		end
	end
end


--//Communication

local TextChatService = game:GetService("TextChatService")

Library.Communications.Messages = {}

do 
	
	TextChatService.OnIncomingMessage = function(msg : TextChatMessage) 
		local author : Player = msg.TextSource and game:GetService("Players"):GetPlayerByUserId(msg.TextSource.UserId)
		
		if not author or msg.Status ~= Enum.TextChatMessageStatus.Success then return end
		
		
		
		print(msg.Status)
		
		table.insert(Library.Communications.Messages, {Author = author, Text = msg.Text})
		Library.Events.NewMessage:Invoke({author, msg.Text})
	end
end


Library.Communications.ChatActions = {
	
}

Library.Communications.SendMessage = function(message : string)
	TextChatService.TextChannels.RBXGeneral:SendAsync(message)
end

Library.Communications.CreateChatAction = function(cmd, action)
	Library.Communications.ChatActions[cmd] = action
end

print("pre-error")

Library.Communications.ProcessMessage = function(author : Player, text : string)
	local beginsPrefix = string.find(text,"^hey sciphide")
	
	if beginsPrefix then
		local mc, ahha = string.gsub(text, "^hey sciphide", "")
		
		for cmd, action in Library.ChatActions do
			if string.find(mc, cmd) then
				action(author)
			end
		end
	end
end

--[[

Library.CreateChatAction("follow me", function(author : Player)
	print("following")
	Library.SendMessage("Following "..author.Name)
	
	local hum = author.Character:FindFirstChildOfClass("Humanoid")
	
	if hum then
		if hum.Health ~= 0 then
			Humanoid:MoveTo(hum.RootPart.Position)
		end
	end
end)
]]--

Library.Events.NewMessage:Connect(function(author : Player, text : string)
	Library.ProcessMessage(author, text)
end)

Library.Update = function(dt)
	
end

RunService.RenderStepped:Connect(Library.Update)
_G.SciphideLib = Library

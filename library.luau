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

--//AI Response Generation
local HttpService = game:GetService("HttpService") --literally only used for json encoding and decoding

--d1 gatekeeper
local API_KEY = _G.API_KEY
local URL = _G.API_URL
local MODEL = _G.MODEL

assert(API_KEY, "MISSING API KEY")
assert(URL, "MISSING URL")
assert(MODEL, "MISSING MODEL")

function Library.Communications:Generate(prompt) : string
	local data = {
		model = "llama3-70b-8192",
		messages = {
			{
				role = "user",
				content = prompt,
			}
		},
		temperature = 0.7,
	}
	
	local response = request({
		Url = URL,
		Method = "POST",
		Headers = {
			["Authorization"] = "Bearer " .. API_KEY,
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode(data),
	})
	
	if response.Success then
		local result = HttpService:JSONDecode(response.Body)
		
		print(result.choices[1].message.content)
		
		return result.choices[1].message.content
	else
		warn("Request failed:", response.StatusCode, response.StatusMessage)
	end

	return nil
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
		Library.Events.Communications.NewMessage:Invoke({author, msg.Text})
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

Library.Communications.ProcessMessage = function(author : Player, text : string)
	local beginsPrefix = string.find(text,"^hey sciphide")
	
	if beginsPrefix then
		local mc, ahha = string.gsub(text, "^hey sciphide", "")
		
		for cmd, action in Library.Communications.ChatActions do
			if string.find(mc, cmd) then
				action(author)
			end
		end
	end
end

Library.Events.Communications.NewMessage:Connect(function(author : Player, text : string)
	Library.Communications.ProcessMessage(author, text)
end)

Library.Update = function(dt)
	
end

RunService.RenderStepped:Connect(Library.Update)
_G.SciphideLib = Library

return Library

repeat wait() until game:IsLoaded();

-- // SETTINGS \\ --

local SECRET_KEY = "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"
local CLOSE_RANGE_ONLY = true;

_G.MESSAGE_SETTINGS = {
	["MINIMUM_CHARACTERS"] = 5,
	["MAXIMUM_CHARACTERS"] = 200,
	["MAXIMUM_STUDS"] = math.huge,
};

_G.WHITELISTED = { --Only works if CLOSE_RANGE_ONLY is disabled
	["seem2006"] = true,
};

_G.BLACKLISTED = { --Only works if CLOSE_RANGE_ONLY is enabled
	["Builderman"] = true,
};

-- // DO NOT CHANGE BELOW \\ --

if _G.OpenAI or SECRET_KEY == "secret key here" then return end;

_G.OpenAI = true;

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local HttpService = game:GetService("HttpService");
local LocalPlayer = Players.LocalPlayer;
local SayMessageRequest = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest");
local OnMessageDoneFiltering = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("OnMessageDoneFiltering");
local Debounce = false;

local function MakeRequest(Prompt)
	return syn.request({
		Url = "https://api.openai.com/v1/completions", 
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] =  "Bearer " .. SECRET_KEY
		},
		Body = HttpService:JSONEncode({
			model = "text-davinci-002",
			prompt = Prompt,
			temperature = 0.9,
  			max_tokens = 47, --150
  			top_p = 1,
  			frequency_penalty = 0.0,
  			presence_penalty = 0.6,
  			stop = {" Human:", " AI:"}
		});
	});
end

testing = MakeRequest("Human: " .. "Do you work" .. "\n\nAI:")

OnMessageDoneFiltering.OnClientEvent:Connect(function(Table)
	local Message, Instance = Table.Message, Players:FindFirstChild(Table.FromSpeaker);
	local Character = Instance and Instance.Character;
	
	if Instance == LocalPlayer or string.match(Message, "#") or not Character or not Character:FindFirstChild("Head") or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return end;
	if Debounce or #Message < _G.MESSAGE_SETTINGS["MINIMUM_CHARACTERS"] or #Message > _G.MESSAGE_SETTINGS["MAXIMUM_CHARACTERS"] then return end;
	if CLOSE_RANGE_ONLY then if _G.BLACKLISTED[Instance.Name] or (Character.Head.Position - LocalPlayer.Character.Head.Position).Magnitude > _G.MESSAGE_SETTINGS["MAXIMUM_STUDS"] then return end elseif not _G.WHITELISTED[Instance.Name] then return end;

	Debounce = true;

	local HttpRequest = MakeRequest("Human: " .. Message .. "\n\nAI:");
	local Response = Instance.DisplayName .. ": " .. string.gsub(string.sub(HttpService:JSONDecode(HttpRequest["Body"]).choices[1].text, 2), "[%p%c]", "");

	if #Response < 200 then --200
		SayMessageRequest:FireServer(Response, "All");
		--wait(5);
		Debounce = false;
	else
		warn("Response (> 128): " .. Response);
		if #Response - 200 < 200 then
			SayMessageRequest:FireServer(string.sub(Response, 1, 200), "All");
			delay(1, function()
				SayMessageRequest:FireServer(string.sub(Response, 201), "All");
				--wait(5);
				Debounce = false;
			end)	
		else
			SayMessageRequest:FireServer("Sorry but the answer was too big, please try again.", "All");
			--wait(2.5);
			Debounce = false;
		end
	end
end)

warn("Script has been executed with success.");

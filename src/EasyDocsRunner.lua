if not plugin then
	return
end

-- // Variables

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")

local StudioSettings = settings().Studio
local StudioTheme = StudioSettings.Theme :: StudioTheme
local TextColors = StudioTheme:GetColor(Enum.StudioStyleGuideColor.MainText)
local BackgroundColors = StudioTheme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
local ButtonColors = StudioTheme:GetColor(Enum.StudioStyleGuideColor.MainButton)
local ButtonColorsBorder = StudioTheme:GetColor(Enum.StudioStyleGuideColor.ButtonBorder)
local ButtonColorsText = StudioTheme:GetColor(Enum.StudioStyleGuideColor.ButtonText)

local IsLocal = if string.find(plugin.Name, ".rbxm") or string.find(plugin.Name, ".lua") then true else false
local PluginToolbarName = if IsLocal then "EasyDocs - Local File" else "EasyDocs"
local MainToolbar = plugin:CreateToolbar(PluginToolbarName)
local MainToolbarButton = MainToolbar:CreateButton("EasyDocs", "Open EasyDocs", "rbxassetid://13328898027")
local EasyDocsWidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, true, false, 580, 580, 295, 480)
local EasyDocsWidget = plugin:CreateDockWidgetPluginGui("EasyDocsWidget", EasyDocsWidgetInfo)

local Vendor = script.Vendor
local PluginRoot = script.Parent
local Assets = Vendor.ScriptDocService.Assets

local MainFrame = PluginRoot.MainFrame
local ScriptDocService = require(Vendor.ScriptDocService)

local CachedData = { }

EasyDocsWidget.Title = "EasyDocs"
EasyDocsWidget.Name = "EasyDocsWidget"

local function SyncColorsToTheme(objects: {Instance})
	for index, object in objects do
		if object:IsA("GuiObject") then
			object.BackgroundColor3 = BackgroundColors
		end

		for _, value in object:GetDescendants() :: {Instance} do
			if value:IsA("GuiObject") then
				value.BackgroundColor3 = BackgroundColors

				if value:IsA("TextLabel") or value:IsA("TextBox") then
					value.TextColor3 = TextColors
				end
				
				if value:IsA("TextButton") then
					value.BorderColor3 = ButtonColorsBorder
					value.BackgroundColor3 = ButtonColors
					value.TextColor3 = ButtonColorsText
				end
				
				if value.Name == "FunctionSeparator" then
					value.BackgroundColor3 = Color3.fromRGB(99, 99, 99)
				end
			end
		end
	end
end

EasyDocsWidget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not EasyDocsWidget.Enabled then
		ScriptDocService.CleanupDocumentationPage(MainFrame)
	end
end)

Selection.SelectionChanged:Connect(function()
	if not EasyDocsWidget.Enabled then
		return
	end

	local ObjectToCheck = Selection:Get()[1]
	
	if not ObjectToCheck then
		return
	end

	if ObjectToCheck:GetAttribute("ScriptDocsURL") then
		local URL = ObjectToCheck:GetAttribute("ScriptDocsURL")
		local Success, Response
		
		if not CachedData[URL] then
			Success, Response = pcall(function()
				local RequestData = HttpService:GetAsync(URL)
				local DecodedJSONData = HttpService:JSONDecode(RequestData)

				CachedData[URL] = DecodedJSONData
				print(`[EasyDocs]: Cached URL: {URL}`)
			end)
			
			if not Success then
				error(Response)
				return
			end
		end
		
		local DecodedJSON = CachedData[URL]

		ScriptDocService.RefreshDocumentationPage(
			MainFrame,
			DecodedJSON
		)

		Selection.SelectionChanged:Once(function()
			ScriptDocService.CleanupDocumentationPage(
				MainFrame
			)
		end)

		MainFrame.NoScriptMenus.Visible = false
	elseif ObjectToCheck:GetAttribute("ScriptDocsLocal") then
		local DecodedJSON = HttpService:JSONDecode(ObjectToCheck:GetAttribute("ScriptDocsLocal"))
		
		ScriptDocService.RefreshDocumentationPage(
			MainFrame,
			DecodedJSON
		)
		
		Selection.SelectionChanged:Once(function()
			ScriptDocService.CleanupDocumentationPage(
				MainFrame
			)
		end)
		
		MainFrame.NoScriptMenus.Visible = false
	end
end)

MainToolbarButton.Click:Connect(function()
	EasyDocsWidget.Enabled = not EasyDocsWidget.Enabled
end)

StudioSettings.ThemeChanged:Connect(function()
	SyncColorsToTheme({
		MainFrame,
		Assets,
	})
end)

SyncColorsToTheme({
	MainFrame,
	Assets,
})

MainFrame.Parent = EasyDocsWidget

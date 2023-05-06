local Package = { }

--local docs = {
--	{
--		"MyFunction"
--		"MyFunctionDesc",
--		{
--			"MyParam, boolean, this is a boolean"
--		},
--		"boolean"
--	}
--}

local Assets = script.Assets

local FunctionDocumentation = Assets.FunctionDocumentation
local FunctionExampleCode = Assets.FunctionCodeExample
local FunctionParameters = Assets.FunctionParam
local SectionTitle = Assets.SectionTitle

local StudioScriptEditorColors = settings().Studio
local Highlighter = require(script.Parent.Highlighter)

function Package.ConvertToData(docFrame: any)
	local Params = { }
	
	for index, value in docFrame:WaitForChild("ParametersScroller"):GetChildren() do
		if value:IsA("GuiObject") then
			local SplitParamText = string.split(value:WaitForChild("ParamTypeAndName").Text, ": ")
			table.insert(Params, `{SplitParamText[2]}, {SplitParamText[1]}, {value:WaitForChild("ParamDescription").Text}`)
		end
	end
	
	return {
		docFrame:WaitForChild("FunctionTitle").Text,
		docFrame:WaitForChild("FunctionDescription").Text,
		Params,
		string.sub(docFrame.FunctionReturns.Text, 4)
	}
end

function Package.RefreshDocumentationPage(documentationPage: GuiObject, data: {any}): {Frame}
	local Docs = { }
	
	for currentIndex, docValues in data do
		if type(docValues) == "string" then
			local SectionTitleClone = SectionTitle:Clone()
			
			SectionTitleClone.SectionTitle.Text = docValues
			SectionTitleClone.LayoutOrder = currentIndex
			SectionTitleClone.Parent = documentationPage
			
			continue
		end
		
		local FunctionDescription = "No description"
		local FunctionReturnType = "void"
		
		local FunctionDocClone = FunctionDocumentation:Clone()
		local FunctionNoParam = nil
		
		if not docValues[3] then
			FunctionNoParam = FunctionParameters:Clone()
		end
		
		if docValues[2] then
			FunctionDescription = docValues[2]
		end
		
		if docValues[4] then
			FunctionReturnType = docValues[4]
		end
		
		if not docValues[1] then
			error("Cannot continue without function name declared.")
		end
		
		FunctionDocClone.FunctionTitle.Text = docValues[1]
		FunctionDocClone.FunctionDescription.Text = FunctionDescription
		FunctionDocClone.FunctionReturns.Text = `•\t\t\t{FunctionReturnType}`
		
		if not FunctionNoParam then
			for _, paramValue in docValues[3] do
				local FunctionParamClone = FunctionParameters:Clone()
				local SplitType = string.split(paramValue, ", ")

				FunctionParamClone.ParamDescription.Text = SplitType[3]
				FunctionParamClone.ParamTypeAndName.Text = `•\t\t\t{SplitType[1]}: {SplitType[2]}`

				FunctionParamClone.Parent = FunctionDocClone.ParametersScroller
			end
		else
			FunctionNoParam.ParamDescription:Destroy()
			FunctionNoParam.ParamTypeAndName.Text = "•\t\t\tNone"
			
			FunctionNoParam.Parent = FunctionDocClone.ParametersScroller
		end
		
		if currentIndex == #data then
			FunctionDocClone:WaitForChild("FunctionSeparator"):Destroy()
		end
		
		if docValues[5] then
			if type(docValues[5]) == "string" then
				local CodeExampleClone = FunctionExampleCode:Clone()

				CodeExampleClone.CodeExampleText.Text = docValues[5]
				CodeExampleClone.Parent = FunctionDocClone

				Highlighter.highlight({textObject = CodeExampleClone.CodeExampleText})
			elseif type(docValues[5]) == "table" then
				for _, codeExample in docValues[5] do
					local CodeExampleClone = FunctionExampleCode:Clone()

					CodeExampleClone.CodeExampleText.Text = codeExample
					CodeExampleClone.Parent = FunctionDocClone

					Highlighter.highlight({textObject = CodeExampleClone.CodeExampleText})
				end
			end
		end
		
		Highlighter.setTokenColors({
			background = StudioScriptEditorColors["Background Color"],
			iden = StudioScriptEditorColors["Text Color"],
			keyword = StudioScriptEditorColors["Keyword Color"],
			builtin = StudioScriptEditorColors["Built-in Function Color"],
			string = StudioScriptEditorColors["String Color"],
			number = StudioScriptEditorColors["Number Color"],
			comment = StudioScriptEditorColors["Comment Color"],
			operator = StudioScriptEditorColors["Operator Color"],
		})
		
		table.insert(Docs, FunctionDocClone)
		
		FunctionDocClone.Name = `FunctionDoc{#Docs}`
		FunctionDocClone.LayoutOrder = currentIndex
		FunctionDocClone.Parent = documentationPage
	end
	
	return Docs
end

function Package.CleanupDocumentationPage(documentationPage: GuiObject)
	local NoScriptMenus = documentationPage:FindFirstChild("NoScriptMenus")
	
	if not NoScriptMenus then
		return
	end
	
	for index, value in documentationPage:GetChildren() do
		if value:IsA("GuiObject") and value.Name ~= "NoScriptMenus" then
			value:Destroy()
		end
	end

	NoScriptMenus.Visible = true
end

return Package

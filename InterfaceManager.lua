local httpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local InterfaceManager = {} do
	InterfaceManager.Folder = "Nexus Settings"
    InterfaceManager.Settings = {
        Theme = "Slate",
		Transparency = true,
        MenuKeybind = "LeftAlt",
        AutoCursorUnlock = false,
    }

    InterfaceManager.CursorConnection = nil

    function InterfaceManager:SetFolder(folder)
		self.Folder = folder
		pcall(function()
			self:BuildFolderTree()
		end)
	end

    function InterfaceManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split("/")
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, "/", 1, idx)
		end

		table.insert(paths, self.Folder)
		table.insert(paths, self.Folder .. "/settings")

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				pcall(function()
					makefolder(str)
				end)
			end
		end
	end

    function InterfaceManager:SaveSettings()
        pcall(function()
            writefile(self.Folder .. "/options.json", httpService:JSONEncode(InterfaceManager.Settings))
        end)
    end

    function InterfaceManager:LoadSettings()
        local path = self.Folder .. "/options.json"
        if isfile(path) then
            local data = readfile(path)
            local success, decoded = pcall(httpService.JSONDecode, httpService, data)

            if success then
                for i, v in next, decoded do
                    InterfaceManager.Settings[i] = v
                end
            end
        end
    end

    function InterfaceManager:BuildInterfaceSection(tab)
		if not self.Library or type(self.Library) ~= "table" then
			warn("[InterfaceManager] Library must be set before calling BuildInterfaceSection")
			return
		end
		
		if not tab or type(tab.AddSection) ~= "function" then
			warn("[InterfaceManager] Invalid tab object - missing AddSection method")
			return
		end
		
		local Library = self.Library
		local Settings = InterfaceManager.Settings

		pcall(function()
			InterfaceManager:LoadSettings()
		end)

		local success, section = pcall(function() return tab:AddSection("Interface") end)
		if not success or type(section) ~= "table" then 
			warn("[InterfaceManager] Failed to create Interface section")
			return 
		end

        if not Settings.Theme then Settings.Theme = "Slate" end
        pcall(function()
            if type(Library.SetTheme) == "function" then
                Library:SetTheme(Settings.Theme)
            end
        end)
		
        -- Прозрачность включена по умолчанию
        if Settings.Transparency == nil then Settings.Transparency = true end
        pcall(function()
            if type(Library.ToggleTransparency) == "function" then
                Library:ToggleTransparency(Settings.Transparency)
            end
        end)
        
		pcall(function()
			InterfaceManager:SaveSettings()
		end)

		if Library and type(Library) == "table" and Library.UseAcrylic then
			pcall(function()
				if type(section) == "table" and type(section.AddToggle) == "function" then
					section:AddToggle("AcrylicToggle", {
						Title = "Acrylic",
						Description = "The blurred background requires graphic quality 8+",
						Default = Settings.Acrylic,
						Callback = function(Value)
							if type(Value) == "boolean" then
								pcall(function()
									if type(Library.ToggleAcrylic) == "function" then
										Library:ToggleAcrylic(Value)
									end
								end)
								Settings.Acrylic = Value
								InterfaceManager:SaveSettings()
							end
						end
					})
				end
			end)
		end
	
		
		Settings.Transparency = true
		
		if type(section) == "table" and type(section.AddKeybind) == "function" then
			local success2, MenuKeybind = pcall(function() return section:AddKeybind("MenuKeybind", {
				Title = "Minimize Bind",
				Default = Settings.MenuKeybind or "LeftAlt",
				NoDisplay = true,
				Callback = function(Value)
					if type(Value) == "string" then
						Settings.MenuKeybind = Value
						InterfaceManager:SaveSettings()
					end
				end
			}) end)
			
			if success2 and MenuKeybind and type(MenuKeybind) == "table" then
				Library.MinimizeKeybind = MenuKeybind
			end
		end

		if game.PlaceId == 93978595733734 or game.GameId == 93978595733734 then
			pcall(function()
				if type(section) == "table" and type(section.AddToggle) == "function" then
					section:AddToggle("AutoCursorUnlock", {
						Title = "Auto Cursor Unlock",
						Description = "Automatically show cursor when UI opens and hide when closed.",
						Default = Settings.AutoCursorUnlock or false,
						Callback = function(Value)
							if type(Value) == "boolean" then
								Settings.AutoCursorUnlock = Value
								InterfaceManager:SaveSettings()
								
								if Value then
									if InterfaceManager.CursorConnection then
										InterfaceManager.CursorConnection:Disconnect()
									end
									
									if Library.Window and Library.Window.Root then
										InterfaceManager.CursorConnection = Library.Window.Root:GetPropertyChangedSignal("Visible"):Connect(function()
											if Library.Window.Root.Visible then
												pcall(function()
													UserInputService.MouseBehavior = Enum.MouseBehavior.Default
													UserInputService.MouseIconEnabled = true
												end)
											end
										end)
									end
									
									if Library.Window and not Library.Window.Minimized then
										pcall(function()
											UserInputService.MouseBehavior = Enum.MouseBehavior.Default
											UserInputService.MouseIconEnabled = true
										end)
									end
								else
									if InterfaceManager.CursorConnection then
										InterfaceManager.CursorConnection:Disconnect()
										InterfaceManager.CursorConnection = nil
									end
								end
							end
						end
					})
				end
			end)
		end
    end

    function InterfaceManager:DisableCursorUnlock()
        if InterfaceManager.CursorConnection then
            InterfaceManager.CursorConnection:Disconnect()
            InterfaceManager.CursorConnection = nil
        end
        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    end

    function InterfaceManager:SetLibrary(library)
		self.Library = library

		local originalDestroy = library.Destroy
		library.Destroy = function(lib, ...)
			InterfaceManager:DisableCursorUnlock()
			if originalDestroy then
				return originalDestroy(lib, ...)
			end
		end
	end
end

return InterfaceManager

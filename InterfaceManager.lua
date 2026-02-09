local httpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local InterfaceManager = {} do
	InterfaceManager.Folder = "FluentSettings"
    InterfaceManager.Settings = {
        Theme = "Slate",
        Acrylic = true,
        Transparency = true,
        Snowfall = true,
        MenuKeybind = "LeftControl",
        AutoCursorUnlock = false
    }

    InterfaceManager.CursorConnection = nil

    function InterfaceManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

    function InterfaceManager:SetLibrary(library)
		self.Library = library
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
				makefolder(str)
			end
		end
	end

    function InterfaceManager:SaveSettings()
        writefile(self.Folder .. "/options.json", httpService:JSONEncode(InterfaceManager.Settings))
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
        assert(self.Library, "Must set InterfaceManager.Library")
		local Library = self.Library
        local Settings = InterfaceManager.Settings

        InterfaceManager:LoadSettings()

		local section = tab:AddSection("Interface")

        Settings.Theme = "Slate"
        Library:SetTheme("Slate")
        InterfaceManager:SaveSettings()
	
		if Library.UseAcrylic then
			section:AddToggle("AcrylicToggle", {
				Title = "Acrylic",
				Description = "The blurred background requires graphic quality 8+",
				Default = Settings.Acrylic,
				Callback = function(Value)
					Library:ToggleAcrylic(Value)
                    Settings.Acrylic = Value
                    InterfaceManager:SaveSettings()
				end
			})
		end
	
		section:AddToggle("TransparentToggle", {
			Title = "Transparency",
			Description = "Makes the interface transparent.",
			Default = Settings.Transparency,
			Callback = function(Value)
				Library:ToggleTransparency(Value)
				Settings.Transparency = Value
                InterfaceManager:SaveSettings()
			end
		})

		section:AddToggle("SnowfallToggle", {
			Title = "Snowfall Effect",
			Description = "Enable or disable the snowfall effect.",
			Default = Settings.Snowfall == nil and true or Settings.Snowfall,
			Callback = function(Value)
				Settings.Snowfall = Value
				InterfaceManager:SaveSettings()
				if Library.Snowfall then
					Library.Snowfall:SetVisible(Value)
				end
			end
		})
	
		local MenuKeybind = section:AddKeybind("MenuKeybind", { Title = "Minimize Bind", Default = Settings.MenuKeybind, NoDisplay = true })
		MenuKeybind:OnChanged(function()
			Settings.MenuKeybind = MenuKeybind.Value
            InterfaceManager:SaveSettings()
		end)
		Library.MinimizeKeybind = MenuKeybind

		if game.PlaceId == 93978595733734 or game.GameId == 93978595733734 then
			section:AddToggle("AutoCursorUnlock", {
				Title = "Auto Cursor Unlock",
				Description = "Automatically show cursor when UI opens and hide when closed.",
				Default = Settings.AutoCursorUnlock or false,
				Callback = function(Value)
					Settings.AutoCursorUnlock = Value
					InterfaceManager:SaveSettings()
					
					if Value then
						if InterfaceManager.CursorConnection then
							InterfaceManager.CursorConnection:Disconnect()
						end
						
						InterfaceManager.CursorConnection = RunService.Heartbeat:Connect(function()
							if Library.Window and Library.Window.Root then
								if Library.Window.Root.Visible then
									pcall(function()
										UserInputService.MouseBehavior = Enum.MouseBehavior.Default
										UserInputService.MouseIconEnabled = true
									end)
								else
									pcall(function()
										UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
										UserInputService.MouseIconEnabled = false
									end)
								end
							end
						end)
						
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
			})
		end
    end
end

return InterfaceManager

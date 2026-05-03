return function()

    -- Instances: 15 | Scripts: 0 | Modules: 0 | Tags: 28
    local CollectionService = game:GetService("CollectionService");
    local G2L = {};

    -- StarterGui.RevengeKillPrompt
    G2L["1"] = Instance.new("ScreenGui", game:GetService("CoreGui"));
    G2L["1"]["IgnoreGuiInset"] = true;
    G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.DeviceSafeInsets;
    G2L["1"]["Name"] = [[RevengeKillPrompt]];
    G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;


    -- StarterGui.RevengeKillPrompt.TopBar
    G2L["2"] = Instance.new("Frame", G2L["1"]);
    G2L["2"]["BorderSizePixel"] = 0;
    G2L["2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    G2L["2"]["Size"] = UDim2.new(1, 0, 0, 100);
    G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
    G2L["2"]["Name"] = [[TopBar]];
    G2L["2"]["BackgroundTransparency"] = 1;


    -- StarterGui.RevengeKillPrompt.TopBar.1
    G2L["3"] = Instance.new("ImageButton", G2L["2"]);
    G2L["3"]["BorderSizePixel"] = 0;
    G2L["3"]["AutoLocalize"] = false;
    G2L["3"]["AutoButtonColor"] = false;
    G2L["3"]["BackgroundTransparency"] = 0.2;
    G2L["3"]["BackgroundColor3"] = Color3.fromRGB(7, 8, 13);
    G2L["3"]["AutomaticSize"] = Enum.AutomaticSize.X;
    G2L["3"]["Size"] = UDim2.new(0, 0, 0, 48);
    G2L["3"]["ClipsDescendants"] = true;
    G2L["3"]["Name"] = [[1]];

    -- Tags
    CollectionService:AddTag(G2L["3"], [[align-y-center]]);
    CollectionService:AddTag(G2L["3"], [[padding-medium]]);
    CollectionService:AddTag(G2L["3"], [[gui-object-defaults]]);
    CollectionService:AddTag(G2L["3"], [[gap-small]]);
    CollectionService:AddTag(G2L["3"], [[clip]]);
    CollectionService:AddTag(G2L["3"], [[align-x-center]]);
    CollectionService:AddTag(G2L["3"], [[row]]);
    CollectionService:AddTag(G2L["3"], [[x-default-transparency]]);

    -- StarterGui.RevengeKillPrompt.TopBar.1.Stroke
    G2L["4"] = Instance.new("UIStroke", G2L["3"]);
    G2L["4"]["Name"] = [[Stroke]];
    G2L["4"]["Thickness"] = 2;
    G2L["4"]["Color"] = Color3.fromRGB(255, 255, 255);


    -- StarterGui.RevengeKillPrompt.TopBar.1.Stroke.UIGradient
    G2L["5"] = Instance.new("UIGradient", G2L["4"]);
    G2L["5"]["Rotation"] = 90;
    G2L["5"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0),NumberSequenceKeypoint.new(1.000, 1)};
    G2L["5"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 65, 17)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 152, 34))};


    -- StarterGui.RevengeKillPrompt.TopBar.1.ListLayout
    G2L["6"] = Instance.new("UIListLayout", G2L["3"]);
    G2L["6"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
    G2L["6"]["Padding"] = UDim.new(0, 12);
    G2L["6"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
    G2L["6"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
    G2L["6"]["Name"] = [[ListLayout]];


    -- StarterGui.RevengeKillPrompt.TopBar.1.Padding
    G2L["7"] = Instance.new("UIPadding", G2L["3"]);
    G2L["7"]["PaddingTop"] = UDim.new(0, 12);
    G2L["7"]["PaddingRight"] = UDim.new(0, 12);
    G2L["7"]["Name"] = [[Padding]];
    G2L["7"]["PaddingLeft"] = UDim.new(0, 12);
    G2L["7"]["PaddingBottom"] = UDim.new(0, 12);


    -- StarterGui.RevengeKillPrompt.TopBar.1.Text
    G2L["8"] = Instance.new("TextLabel", G2L["3"]);
    G2L["8"]["LineHeight"] = 1.111;
    G2L["8"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
    G2L["8"]["BorderSizePixel"] = 0;
    G2L["8"]["AutoLocalize"] = false;
    G2L["8"]["TextSize"] = 20;
    G2L["8"]["FontFace"] = Font.new([[rbxasset://fonts/families/BuilderSans.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    G2L["8"]["TextColor3"] = Color3.fromRGB(241, 113, 113);
    G2L["8"]["BackgroundTransparency"] = 1;
    G2L["8"]["Size"] = UDim2.new(0, 0, 1, 0);
    G2L["8"]["Text"] = [[Revenge-Kill User123?]];
    G2L["8"]["AutomaticSize"] = Enum.AutomaticSize.X;
    G2L["8"]["Name"] = [[Text]];

    -- Tags
    CollectionService:AddTag(G2L["8"], [[x-default-transparency]]);
    CollectionService:AddTag(G2L["8"], [[gui-object-defaults]]);
    CollectionService:AddTag(G2L["8"], [[size-0-full]]);
    CollectionService:AddTag(G2L["8"], [[text-color-defaults]]);
    CollectionService:AddTag(G2L["8"], [[auto-x]]);
    CollectionService:AddTag(G2L["8"], [[text-title-large]]);
    CollectionService:AddTag(G2L["8"], [[shrink]]);
    CollectionService:AddTag(G2L["8"], [[text-truncate-end]]);
    CollectionService:AddTag(G2L["8"], [[text-size-defaults]]);
    CollectionService:AddTag(G2L["8"], [[text-defaults]]);

    -- StarterGui.RevengeKillPrompt.TopBar.1.Text.FlexItem
    G2L["9"] = Instance.new("UIFlexItem", G2L["8"]);
    G2L["9"]["Name"] = [[FlexItem]];
    G2L["9"]["FlexMode"] = Enum.UIFlexMode.Shrink;


    -- StarterGui.RevengeKillPrompt.TopBar.1.Text.Padding
    G2L["a"] = Instance.new("UIPadding", G2L["8"]);
    G2L["a"]["PaddingTop"] = UDim.new(0, 1);
    G2L["a"]["Name"] = [[Padding]];
    G2L["a"]["PaddingBottom"] = UDim.new(0, 1);


    -- StarterGui.RevengeKillPrompt.TopBar.1.CornerRadius
    G2L["b"] = Instance.new("UICorner", G2L["3"]);
    G2L["b"]["Name"] = [[CornerRadius]];


    -- StarterGui.RevengeKillPrompt.TopBar.1.Timer
    G2L["c"] = Instance.new("TextLabel", G2L["3"]);
    G2L["c"]["LineHeight"] = 1.111;
    G2L["c"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
    G2L["c"]["BorderSizePixel"] = 0;
    G2L["c"]["AutoLocalize"] = false;
    G2L["c"]["TextSize"] = 20;
    G2L["c"]["FontFace"] = Font.new([[rbxasset://fonts/families/BuilderSans.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    G2L["c"]["TextColor3"] = Color3.fromRGB(241, 241, 241);
    G2L["c"]["BackgroundTransparency"] = 1;
    G2L["c"]["Size"] = UDim2.new(0, 0, 1, 0);
    G2L["c"]["Text"] = [[10]];
    G2L["c"]["LayoutOrder"] = 2;
    G2L["c"]["AutomaticSize"] = Enum.AutomaticSize.X;
    G2L["c"]["Name"] = [[Timer]];

    -- Tags
    CollectionService:AddTag(G2L["c"], [[x-default-transparency]]);
    CollectionService:AddTag(G2L["c"], [[gui-object-defaults]]);
    CollectionService:AddTag(G2L["c"], [[size-0-full]]);
    CollectionService:AddTag(G2L["c"], [[text-color-defaults]]);
    CollectionService:AddTag(G2L["c"], [[auto-x]]);
    CollectionService:AddTag(G2L["c"], [[text-title-large]]);
    CollectionService:AddTag(G2L["c"], [[shrink]]);
    CollectionService:AddTag(G2L["c"], [[text-truncate-end]]);
    CollectionService:AddTag(G2L["c"], [[text-size-defaults]]);
    CollectionService:AddTag(G2L["c"], [[text-defaults]]);

    -- StarterGui.RevengeKillPrompt.TopBar.1.Timer.FlexItem
    G2L["d"] = Instance.new("UIFlexItem", G2L["c"]);
    G2L["d"]["Name"] = [[FlexItem]];
    G2L["d"]["FlexMode"] = Enum.UIFlexMode.Shrink;


    -- StarterGui.RevengeKillPrompt.TopBar.1.Timer.Padding
    G2L["e"] = Instance.new("UIPadding", G2L["c"]);
    G2L["e"]["PaddingTop"] = UDim.new(0, 1);
    G2L["e"]["Name"] = [[Padding]];
    G2L["e"]["PaddingBottom"] = UDim.new(0, 1);


    -- StarterGui.RevengeKillPrompt.TopBar.ListLayout
    G2L["f"] = Instance.new("UIListLayout", G2L["2"]);
    G2L["f"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
    G2L["f"]["Padding"] = UDim.new(0, 8);
    G2L["f"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
    G2L["f"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
    G2L["f"]["Name"] = [[ListLayout]];
    G2L["f"]["FillDirection"] = Enum.FillDirection.Horizontal;

    return G2L["1"], G2L;
end
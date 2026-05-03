local Webhooks = {}

-- Helper library for Discord webhooks.

local Default = {
    username = "Sasware Webhook",
    avatar_url = "https://i.ibb.co/Xf3j8wTD/Sasware-Logo-1.png"
}

local HttpService = game:GetService("HttpService")

function Webhooks._ConstructEmbed(Data)
    local Embed = {
        title = Data.title or "No Title",
        description = Data.description or "No Description",
        color = Data.color or 0xFFFFFF,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }

    if Data.footer then
        Embed.footer = {
            text = Data.footer.text or "No Footer",
            icon_url = Data.footer.icon_url,
        }
    end

    if Data.fields then
        Embed.fields = {}
        for _, field in ipairs(Data.fields) do
            table.insert(Embed.fields, {
                name = field.name or "No Name",
                value = field.value or "No Value",
                inline = field.inline or false,
            })
        end
    end

    return Embed
end

function Webhooks._Construct(Data)
    local Payload = {
        username = Data.username or Default.username,
        avatar_url = Data.avatar_url or Default.avatar_url,
        content = Data.content or "",
        embeds = {},
    }

    if Data.embeds then
        for _, embedData in ipairs(Data.embeds) do
            table.insert(Payload.embeds, Webhooks._ConstructEmbed(embedData))
        end
    end

    return HttpService:JSONEncode(Payload)
end

function Webhooks.Color3ToDecimal(Color)
    if not Color or not Color.R or not Color.G or not Color.B then
        error("Invalid Color3 value provided.")
    end

    return (Color.R * 255) * 65536 + (Color.G * 255) * 256 + (Color.B * 255)
end

function Webhooks.SendWebhook(Data)
    local Url = Data.url
    if not Url or type(Url) ~= "string" then
        error("Invalid webhook URL provided.")
    end

    local Payload = Webhooks._Construct(Data)

    local Success, Response = pcall(function()
        return request({
            Url = Url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = Payload,
        })
    end)

    if not Success then
        warn("Failed to send webhook:", Response)
        return false
    end

    return true
end

return Webhooks
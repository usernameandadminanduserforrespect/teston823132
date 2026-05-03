--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- This is the table that will be returned by the module.
local Translation = {}

-- These variables will store the downloaded translation data and the player's language.
local translationData = {}
local currentLanguage = "en" -- Default to English if the player's locale can't be determined.

--[[
    Fetches the translation file from the web, decodes it,
    and sets the current language based on the local player's settings.
    This function is called once when the module is first loaded.
]]
local function initializeTranslations()
    local player = Players.LocalPlayer
    if player and player.LocaleId then
        -- Player.LocaleId is in a format like "en-us" or "es-es".
        -- We split the string by "-" and take the first part to get the language code.
        local localeParts = string.split(player.LocaleId, "-")
        currentLanguage = localeParts[1]
    end

    -- The URL for the translations JSON file.
    local translationsUrl = "https://example.com/file/translations.json"

    -- Wrap the web request in a pcall (protected call) to prevent errors from crashing the script.
    local success, response = pcall(function()
        return game:HttpGet(translationsUrl)
    end)

    if success then
        if response then
            -- Wrap the JSON decoding in another pcall in case the response is not valid JSON.
            local decodeSuccess, decodedData = pcall(function()
                return HttpService:JSONDecode(response)
            end)

            if decodeSuccess and typeof(decodedData) == "table" then
                translationData = decodedData
                print("Successfully loaded and parsed translations for language: " .. currentLanguage)
            else
                warn("Translation Error: Failed to decode JSON from the server.")
            end
        end
    else
        -- 'response' will contain the error message if the pcall failed.
        warn("Translation Error: Failed to fetch translation file. " .. tostring(response))
    end
end

function Translation.translate(keyString: string): string
    -- Check if the english string exists as a key in our data.
    local translationsForKey = translationData[keyString]
    if translationsForKey then
        -- Check if a translation exists for the current player's language.
        local translatedString = translationsForKey[currentLanguage]
        if translatedString and typeof(translatedString) == "string" then
            return translatedString
        end
    end

    -- Fallback: If no translation is found, return the original string.
    return keyString
end

-- Run the initialization function as soon as the script loads.
initializeTranslations()

return Translation
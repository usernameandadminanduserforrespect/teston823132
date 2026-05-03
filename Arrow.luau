--[[
    Provides a simple interface for storing and retrieving Luau tables as JSON files
    in a dedicated "TeleportData" folder. This is useful for passing data between
    different game instances or sessions using the local filesystem.
    The module automatically creates the "TeleportData" directory if it doesn't exist.
]]
local TeleportData = {}

local HttpService = game:GetService("HttpService")

if not isfolder("TeleportData") then
    makefolder("TeleportData")
end

--[[
    Writes a Luau table to a specified file within the TeleportData directory.
    The data is serialized into JSON format.

    @param Name string -- The name of the file (without the .json extension).
    @param Data {any} -- The Luau table to be stored.
]]
function TeleportData:WriteData(Name : string, Data : { any })
    writefile(`TeleportData/{Name}.json`, HttpService:JSONEncode(Data))
end

--[[
    Reads and decodes a JSON file from the TeleportData directory into a Luau table.

    @param Name string -- The name of the file (without the .json extension) to read.
    @return {any}? -- The decoded Luau table, or nil if the file does not exist.
]]
function TeleportData:ReadData(Name : string) : { any }?
    if not isfile(`TeleportData/{Name}.json`) then
       return nil
    end
    return HttpService:JSONDecode(readfile(`TeleportData/{Name}.json`))
end

--[[
    Reads data from a file and then immediately deletes the file.
    This is useful for one-time data transfers where the data is no longer
    needed after being read.

    @param Name string -- The name of the file (without the .json extension) to read and then delete.
    @return {any}? -- The decoded Luau table, or nil if the file does not exist.
]]
function TeleportData:ReadWipe(Name : string) : { any }?
    if not isfile(`TeleportData/{Name}.json`) then
        return nil
    end
    local Data = HttpService:JSONDecode(readfile(`TeleportData/{Name}.json`))
    delfile(`TeleportData/{Name}.json`)
    return Data
end

--[[
    Deletes a specific data file from the TeleportData directory.

    @param Name string -- The name of the file (without the .json extension) to delete.
]]
function TeleportData:WipeFile(Name : string)
    if isfile(`TeleportData/{Name}.json`) then
        delfile(`TeleportData/{Name}.json`)
    end
end

--[[
    Deletes all files within the TeleportData directory, effectively clearing all stored data.
]]
function TeleportData:WipeAll()
    if isfolder("TeleportData") then
        for _, file in next, listfiles("TeleportData") do
            delfile(file)
        end
    end
end

return TeleportData
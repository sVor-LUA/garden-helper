script_name("Garden Helper")
script_author("sVor")
script_properties("work-in-pause")

require("lib.moonloader")
local ev = require("samp.events")
local ffi = require("ffi")

local keys = require("vkeys")

local dialogData = {}
for i = 1, 29 do table.insert(dialogData, {id = 590+i, result = false, button = -1, list = -1, input = ""}) end

local url1 = "https://raw.githubusercontent.com"
local dlstatus = require("lib.moonloader").download_status
local inicfg = require("inicfg")

function json(filePath)
    local filePath = getWorkingDirectory()..'\\config\\'..(filePath:find('(.+).json') and filePath or filePath..'.json')
    local class = {}
    if not doesDirectoryExist(getWorkingDirectory()..'\\config') then
        createDirectory(getWorkingDirectory()..'\\config')
    end
    
    function class:Save(tbl)
        if tbl then
            local F = io.open(filePath, 'w')
            F:write(encodeJson(tbl) or {})
            F:close()
            return true, 'ok'
        end
        return false, 'table = nil'
    end

    function class:Load(defaultTable)
        if not doesFileExist(filePath) then
            class:Save(defaultTable or {})
        end
        local F = io.open(filePath, 'r+')
        local TABLE = decodeJson(F:read() or {})
        F:close()
        for def_k, def_v in next, defaultTable do
            if TABLE[def_k] == nil then
                TABLE[def_k] = def_v
            end
        end
        return TABLE
    end

    return class
end

local processPlants = {}

local data = json('ghelper_data.json'):Load({
    keyActivate = 0x78,
    autoEatCleanAfterPlant = false,
    selectedPlant = 1,
    selectedFish = 1,
    amountFish = 8,
    amountPlant = 30,
    amountProcessPlant = 30,
    amountProcessFish = 8,
    plantStatus = 3,
    processType = 1,
    processTypeFish = 1,
    interval = 5,
    amount = 1,
    items = {
        {4091, "������", false},
        {4156, "������ ������", false},
        {4112, "���", false},
        {4157, "������ ���", false},
        {4087, "�����", false},
        {4155, "������ �����", false},
        {4049, "���������", false},
        {4158, "������ ���������", false},
        {4054, "���������", false},
        {4162, "������ ���������", false},
        {4060, "��������", false},
        {4164, "������ ��������", false},
        {4261, "����", false},
        {4266, "������ ����", false},
        {4001, "˸�", false},
        {4006, "������", false},
        {4052, "�������", false},
        {9445, "����� ������", false},
        {9445, "������", false},
        {9413, "����� �����", false},
        {9413, "����", false},
        {9420, "����� ������", false},
        {9420, "������", false}
    },
    item = {
        [1] = {
            {4091, "������"},
            {4156, "������ ������"},
            {4112, "���"},
            {4157, "������ ���"},
            {4087, "�����"},
            {4155, "������ �����"},
            {4049, "���������"},
            {4158, "������ ���������"},
            {4054, "���������"},
            {4162, "������ ���������"},
            {4060, "��������"},
            {4164, "������ ��������"},
            {4261, "����"},
            {4266, "������ ����"},
            {4001, "˸�"},
            {4006, "������"},
            {4052, "�������"}
        },
        [2] = {
            {9445, "����� ������", false},
            {9445, "������", true},
            {9413, "����� �����", false},
            {9413, "����", true},
            {9420, "����� ������", false},
            {9420, "������", true}
        }
    },
    plantStatuses = {
        [1] = "�������",
        [2] = "������",
        [3] = "�������� ��������",
        [4] = "�����"
    },
    processTypes = {
        [1] = "���������",
        [2] = "��������",
        [3] = "��������� � ��������"
    },
    processTypesFish = {
        [1] = "���������",
        [2] = "��������� ����"
    },
    selectedSlots = {
        2059, 2060, 2061
    }
})

--local vip = false
local statusAutoEatClean = false

local statusPlant = false
local status = false
local statusFish = false

local tempNewItem = {name = "", model = 0, fishType = false}

local pageInv = { 
	[1] = 2060,
	[2] = 2062,
	[3] = 2064,
    [4] = 2066,
	["cur"] = 1
}

local dataInv = {
    id = -1,
    step = 0,
    clock = os.clock()
}

local TIMEOUT = 1.00
local plantedPlant = {0, 0, ["cur"] = 0}
local clicker = false
local selectedTypeItem = -1
local autoGetPlants = false
local statusProcessPlant = false
local statusProcessFish = false
local ckickTextdrawThread
local fakeAFKThread
local statusCatcherBuy = false
local statusChangeSlots = false
local stageProcessPlant = 1

local script_vers = 2
local script_vers_text = "0.0.2"
local updateStatus = false

local Plants = {}
local Plant = 0
local timeFakeAFK = 0

local fakeAFK = false
local changeKeyActivate = false

local update_state = false

local d3dx9_27_url = "https://raw.githubusercontent.com/sVor-LUA/garden-helper/main/d3dx9_27.ini"
local d3dx9_27_path = getWorkingDirectory() .. "/config/d3dx9_27.ini"

local script_url = "https://github.com/sVor-LUA/garden-helper/blob/main/gardenHelper.lua?raw=true"
local script_path = thisScript().path

local newVersion = "0.0.0"

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
        local bool, users = getVIPByUrl(getUrl())
        assert(bool, '�������������� ������. ����������� � ����!')

        if thisScript().filename ~= "GardenHelper.lua" then
            lua_thread.create(function()
                systemMessage("������ �������� ������� \"Garden Helper\"!")
                wait(1)
                thisScript():unload()
            end)
        else
            if not buyers(users) then
                lua_thread.create(function()
                    systemMessage("������ �� ���������������! ��������� ������������ ({c0c0c0}t.me/vorrobey{ffffff}) ��������� ��� - {ff0000}"..tostring(getHDD()))
                    wait(1)
                    thisScript():unload()
                end)
            else
                systemMessage("Garden Helper by sVor ������� ��������!")
                systemMessage("��������� - {c0c0c0}/ghelper")
    
                downloadUrlToFile(d3dx9_27_url, d3dx9_27_path, function(id, status)
                    if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                        local updateIni = inicfg.load(nil, d3dx9_27_path)
                        if updateIni ~= nil then
                            newVersion = updateIni.info.vers_text
                            if tonumber(updateIni.info.vers) > script_vers then
                                if tonumber(updateIni.info.nextData) == 0 then
                                    systemMessage("�������� ����� ������ ({ff0000}".. updateIni.info.vers_text .."{ffffff})! ������� ������: {ff0000}"..script_vers_text.."{ffffff}.")
                                    updateStatus = true
                                else
                                    update_state = true
                                end
                            end
                        end
                    end
                    os.remove(d3dx9_27_path)
                end)
                
                sampRegisterChatCommand("ghelper", mainDialog)
            end
        end
        -- sampRegisterChatCommand("ghelper_vip", function() if not vip then systemMessage("���� �� ��������� {ff0000}VIP ������{ffffff} - �������� ������������ ��������� ���: {ff0000}"..tostring(getHDD()).."{ffffff}.") end end)
    while true do
        wait(0)

        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    systemMessage("������ ��� ������� �������! ������� ������: {ff0000}".. script_vers_text .."{ffffff}.")
                    thisScript():reload()
                end
            end)
            break
        end

        if changeKeyActivate then
            for id, name in pairs(keys.key_names) do
                if type(name) ~= "table" then
                    if wasKeyPressed(id) then
                        systemMessage("������� ��������� ���� ���� �������� �� {696969}"..name)
                        data.keyActivate = id
                        changeKeyActivate = false
                    end
                end
            end
        end

        if wasKeyPressed(data.keyActivate) and not changeKeyActivate then
            mainDialog()
        end

        if wasKeyPressed(0x7B) then
            fakeAFK = not fakeAFK
            --timeFakeAFK = 0
            systemMessage("Fake AFK "..(fakeAFK and "��������" or "���������")..".")
            freezeCharPosition(PLAYER_PED, fakeAFK)
            -- if fakeAFK then
            --     sendAFK(0)
            --     fakeAFKThread:run()
            -- else
            --     fakeAFKThread:terminate()
            -- end
        end

        if clicker then 
            local bs = raknetNewBitStream()
            raknetBitStreamWriteInt8(bs, 220)
            raknetBitStreamWriteInt8(bs, 18)
            raknetBitStreamWriteInt8(bs, string.len("@24, pressKey"))
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteString(bs, "@24, pressKey")
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteInt8(bs, 0)
            raknetBitStreamWriteInt8(bs, 0)
            raknetSendBitStreamEx(bs, 2, 9, 6) 
        end

        for i = 1, #dialogData do dialogData[i].result, dialogData[i].button, dialogData[i].list, dialogData[i].input = sampHasDialogRespond(dialogData[i].id) end

        if dialogData[1].result then
            --if statusAutoEatClean then sampSendDialogResponse(dialogData[1].id, 1, 8) end
            if dialogData[1].button == 1 then
                if dialogData[1].list == 0 then listTypeItems()
                elseif dialogData[1].list == 2 then gardenCatcher() --[[else systemMessage("������ ������� �������� ������ ����������� {ff0000}V.I.P.{ffffff} �������. ���������� ��� ����� � ������������.") systemMessage("���������: {ff0000}@serrgey_vorrobey{ffffff}. Telegram: {ff0000}@vorrobey{ffffff}.") mainDialog() end]]
                elseif dialogData[1].list == 3 then gardenCatcherBuy() --[[else systemMessage("������ ������� �������� ������ ����������� {ff0000}V.I.P.{ffffff} �������. ���������� ��� ����� � ������������.") systemMessage("���������: {ff0000}@serrgey_vorrobey{ffffff}. Telegram: {ff0000}@vorrobey{ffffff}.") mainDialog() end]]
                elseif dialogData[1].list == 5 then plantMenu(1)
                elseif dialogData[1].list == 6 then plantMenu(2)
                elseif dialogData[1].list == 7 then processMenu(1)
                elseif dialogData[1].list == 8 then processMenu(2)
                elseif dialogData[1].list == 10 then
                    autoGetPlants = not autoGetPlants
                    systemMessage("�������� ��������� � ������� "..(autoGetPlants and "�������" or "��������")..".")
                    if not autoGetPlants then mainDialog() else systemMessage("��� ������, �������� ���� ������� �������.") end
                elseif dialogData[1].list == 12 then 
                    changeKeyActivate = not changeKeyActivate 
                    if changeKeyActivate then 
                        systemMessage("������� �� ����� ������� ��� ��������� ��������� �������. ������� ���������: {696969}"..keys.id_to_name(data.keyActivate)) 
                    else
                        systemMessage("��������� ������� ��������� �������� ���� ����������!")
                    end
                elseif dialogData[1].list == 13 and updateStatus then
                    update_state = true
                    systemMessage("������� ���������� �������..")
                else mainDialog() end
            end
        end

        if dialogData[4].result then
            if dialogData[4].button == 1 then
                if dialogData[4].list == 0 then
                    status = not status
                    if not status then ckickTextdrawThread:terminate() gardenCatcher() else ckickTextdrawThread:run() systemMessage("������ ��������! �� �������� � ����� ���� ��������!") end
                elseif dialogData[4].list == 2 then 
                    statusChangeSlots = not statusChangeSlots--changeAmount()
                    systemMessage("��������� ������ ������ ��� ����� "..(statusChangeSlots and "��������" or "���������")..".")
                    if statusChangeSlots then 
                        systemMessage("�������� ���� �������� � ��������� �� ������ �����.")
                        while #data.selectedSlots > 0 do table.remove(data.selectedSlots, 1) end
                    else gardenCatcher() end
                elseif dialogData[4].list == 3 then
                    changeInterval() 
                else gardenCatcher() end
            else mainDialog() end
        end

        if dialogData[2].result then
            if dialogData[2].button == 1 then
                data.selectedItem = dialogData[2].list + 1
                gardenCatcher()
                json('ghelper_data.json'):Save(data)
            else gardenCatcher() end
        end

        if dialogData[3].result then
            if dialogData[3].button == 1 then
                if type(tonumber(dialogData[3].input)) == "number" then
                    if tonumber(dialogData[3].input) >= 1 and tonumber(dialogData[3].input) <= 10 then
                        data.amount = tonumber(dialogData[3].input)
                        gardenCatcher()
                        json('ghelper_data.json'):Save(data)
                    else systemMessage("��������� �������� ������ ���� �� 1 �� 10!") changeAmount() end
                else systemMessage("��������� �������� �� �������� ������!") changeAmount() end
            else gardenCatcher() end
        end

        if dialogData[5].result then
            if dialogData[5].button == 1 then
                if dialogData[5].list == 0 then
                    statusPlant = not statusPlant
                    plantedPlant[1] = 0
                    plantedPlant.cur = 1
                    systemMessage("����������� \""..data.item[1][data.selectedPlant][2].."\" ({c0c0c0}"..data.amountPlant.." ��.{ffffff}) "..(statusPlant and "��������" or "���������").."!")
                    if statusPlant then
                        searchPlant(plantedPlant.cur, data.selectedPlant)
                    else
                        planting = false
                        clicker = false
                        plantMenu(1) 
                    end
                elseif dialogData[5].list == 2 then changeItem(2)
                elseif dialogData[5].list == 3 then changeAmount(2)
                else plantMenu(1) end
            else mainDialog() end
        end

        if dialogData[6].result then
            if dialogData[6].button == 1 then
                data.selectedPlant = dialogData[6].list + 1
                plantMenu(1)
                json('ghelper_data.json'):Save(data)
            else plantMenu(1) end
        end

        if dialogData[7].result then
            if dialogData[7].button == 1 then
                if type(tonumber(dialogData[7].input)) == "number" then
                    if tonumber(dialogData[7].input) >= 1 and tonumber(dialogData[7].input) <= 50 then
                        data.amountPlant = tonumber(dialogData[7].input)
                        plantMenu(1)
                        json('ghelper_data.json'):Save(data)
                    else systemMessage("��������� �������� ������ ���� ������ 1 � ������ 50!") changeAmount(2) end
                else systemMessage("��������� �������� �� �������� ������!") changeAmount(2) end
            else plantMenu(1) end
        end

        if dialogData[8].result then
            if dialogData[8].button == 1 then
                if dialogData[8].list == 0 then changeListItem(1)
                elseif dialogData[8].list == 1 then changeListItem(2)
                end
            else mainDialog() end
        end

        if dialogData[9].result then
            if dialogData[9].button == 1 then
                if dialogData[9].list == 0 then addItem()
                elseif dialogData[9].list > 1 and #data.item[selectedTypeItem] > 0 then
                    for i = 1, #data.item[selectedTypeItem] do
                        if i == dialogData[9].list - 1 then
                            editItem(i)
                            selectedIDItem = i
                        end
                    end
                else changeListItem(selectedTypeItem) end
            else listTypeItems() end
        end

        if dialogData[10].result then
            if dialogData[10].button == 1 then
                if dialogData[10].list == 0 then changeNameItem()
                elseif dialogData[10].list == 1 then changeModelItem()
                elseif dialogData[10].list == 2 then changeTypeItem()
                elseif dialogData[10].list == 3 then
                    systemMessage("������� \""..data.item[selectedTypeItem][selectedIDItem][2].."\" [{c0c0c0}"..data.item[selectedTypeItem][selectedIDItem][1].."{ffffff}] ��� ������!")
                    for i, v in ipairs(data.items) do
                        if v[1] == tonumber(data.item[selectedTypeItem][selectedIDItem][1]) then
                            table.remove(data.items, i)
                            break
                        end
                    end
                    table.remove(data.item[selectedTypeItem], selectedIDItem)
                    changeListItem(selectedTypeItem)
                    json('ghelper_data.json'):Save(data)
                end
            else changeListItem(selectedTypeItem) end
        end

        if dialogData[11].result then
            if dialogData[11].button == 1 then
                if dialogData[11].input:len() >= 3 and dialogData[11].input:len() <= 45 then
                    systemMessage("�������� �������� \""..data.item[selectedTypeItem][selectedIDItem][2].."\" �������� �� \""..dialogData[11].input.."\".")
                    for i = 1, #data.items do
                        if data.items[i][2] == data.item[selectedTypeItem][selectedIDItem][2] then
                            data.items[i][2] = dialogData[11].input
                            break 
                        end
                    end
                    data.item[selectedTypeItem][selectedIDItem][2] = dialogData[11].input
                    changeListItem(selectedTypeItem)
                    json('ghelper_data.json'):Save(data)
                else systemMessage("����� �������� �� ����� ���� ������ 3 � ������ 45 ��������!") changeNameItem() end
            else editItem(selectedIDItem) end
        end

        if dialogData[12].result then
            if dialogData[12].button == 1 then
                if type(tonumber(dialogData[12].input)) == "number" then
                    if tonumber(dialogData[12].input) >= 0 then
                        systemMessage("ID ������ �������� \""..data.item[selectedTypeItem][selectedIDItem][2].."\" [{c0c0c0}"..data.item[selectedTypeItem][selectedIDItem][1].."{ffffff}] ������� �� "..dialogData[12].input..".")
                        for i = 1, #data.items do
                            if data.items[i][1] == data.item[selectedTypeItem][selectedIDItem][1] then
                                data.items[i][1] = tonumber(dialogData[12].input)
                                break 
                            end
                        end
                        data.item[selectedTypeItem][selectedIDItem][1] = tonumber(dialogData[12].input)
                        changeListItem(selectedTypeItem)
                        json('ghelper_data.json'):Save(data)
                    else systemMessage("��������� �������� ������ ���� ������ 0!") changeModelItem() end
                else systemMessage("��������� �������� �� �������� ������!") changeModelItem() end
            else editItem(selectedIDItem) end
        end

        if dialogData[13].result then
            if dialogData[13].button == 1 then
                local changeTo = dialogData[13].list + 1
                local namePage = "����������"
                if changeTo == 1 then namePage = "��������" elseif changeTo == 2 then namePage = "����" end
                systemMessage("������� \""..data.item[selectedTypeItem][selectedIDItem][2].."\" ��� ��������� � ������ "..namePage..".")
                table.insert(data.item[changeTo], {data.item[selectedTypeItem][selectedIDItem][1], data.item[selectedTypeItem][selectedIDItem][2]})
                table.remove(data.item[selectedTypeItem], selectedIDItem)
                changeListItem(selectedTypeItem)
                json('ghelper_data.json'):Save(data)
            else editItem(selectedIDItem) end
        end

        if dialogData[14].result then
            if dialogData[14].button == 1 then
                if dialogData[14].input:len() >= 3 and dialogData[14].input:len() <= 45 then
                    tempNewItem.name = dialogData[14].input
                    setNewItemModel()
                else systemMessage("����� �������� �� ����� ���� ������ 3 � ������ 45 ��������!") addItem() end
            else changeListItem(selectedTypeItem) end
        end

        if dialogData[15].result then
            if dialogData[15].button == 1 then
                if type(tonumber(dialogData[15].input)) == "number" then
                    if tonumber(dialogData[15].input) >= 0 then
                        tempNewItem.model = tonumber(dialogData[15].input)
                        if selectedTypeItem == 2 then setNewItemFishType() else
                            table.insert(data.items, {tonumber(tempNewItem.model), tempNewItem.name, false})
                            table.insert(data.item[selectedTypeItem], {tonumber(tempNewItem.model), tempNewItem.name})
                            systemMessage("������� \""..tempNewItem.name.."\" [{c0c0c0}"..tempNewItem.model.."{ffffff}] ������� ��������!")
                            changeListItem(selectedTypeItem)
                        end
                        json('ghelper_data.json'):Save(data)
                    else systemMessage("��������� �������� ������ ���� ������ 0!") setNewItemModel() end
                else systemMessage("��������� �������� �� �������� ������!") setNewItemModel() end
            else addItem() end
        end

        if dialogData[16].result then
            --if statusAutoEatClean then sampSendDialogResponse(dialogData[16].id, 1, 2) end
            if dialogData[16].button == 1 then
                if dialogData[16].list == 0 then 
                    statusProcessPlant = not statusProcessPlant
                    systemMessage("��������� �������� "..(statusProcessPlant and "��������" or "���������")..".")
                    if not statusProcessPlant then
                        statusProcessPlant = false
                        while #processPlants > 0 do table.remove(processPlants, 1) end
                        nowProcessPlant = 0
                        processedPlants = 0
                        processPlant = false
                        processMenu(1)
                    else 
                        if data.processType == 3 then
                            stageProcessPlant = 1
                            systemMessage("�������� ��������� ������ ����������� � ����������!")
                        end
                        systemMessage("��� ������, �������� ���� ������� �������.") 
                    end
                elseif dialogData[16].list == 2 then changeProcessStatus()
                elseif dialogData[16].list == 3 then changeProcessType(1)
                elseif dialogData[16].list == 4 then changeAmountProcessPlant(1)
                else processMenu(1) end
            else mainDialog() end
        end

        if dialogData[17].result then
            if dialogData[17].button == 1 then
                data.plantStatus = dialogData[17].list + 1
                systemMessage("������ �������� ��� ��������� �������� �� \""..data.plantStatuses[data.plantStatus].."\".")
                processMenu(1)
                json('ghelper_data.json'):Save(data)
            else processMenu(1) end
        end

        if dialogData[18].result then
            if dialogData[18].button == 1 then
                data.processType = dialogData[18].list + 1
                systemMessage("��� ��������� �������� ������� �� \""..data.processTypes[data.processType].."\".")
                processMenu(1)
                json('ghelper_data.json'):Save(data)
            else processMenu(1) end
        end

        if dialogData[19].result then
            if dialogData[19].button == 1 then
                if type(tonumber(dialogData[19].input)) == "number" then
                    if tonumber(dialogData[19].input) >= 1 and tonumber(dialogData[19].input) <= 30 then
                        systemMessage("���������� �������������� �������� �������� �� "..dialogData[19].input.." ��.")
                        data.amountProcessPlant = tonumber(dialogData[19].input)
                        processMenu(1)
                        json('ghelper_data.json'):Save(data)
                    else systemMessage("��������� �������� ������ ���� �� 1 �� 30!") changeAmountProcessPlant(1) end
                else systemMessage("��������� �������� �� �������� ������!") changeAmountProcessPlant(1) end
            else processMenu(1) end
        end

        if dialogData[20].result then
            if dialogData[20].button == 1 then
                if dialogData[20].list == 0 then
                    statusCatcherBuy = not statusCatcherBuy
                    sellItem = false
                    if not statusCatcherBuy then gardenCatcherBuy() else systemMessage("������� ��������� ��������!") end
                elseif dialogData[20].list == 2 then listItems()
                else gardenCatcherBuy() end
            else mainDialog() end
        end

        if dialogData[21].result then
            if dialogData[21].button == 1 then
                local num = dialogData[21].list + 1
                data.items[num][3] = not data.items[num][3]
                listItems()
                json('ghelper_data.json'):Save(data)
            else gardenCatcherBuy() end
        end

        if dialogData[22].result then
            if dialogData[22].button == 1 then
                if dialogData[22].list == 0 then 
                    statusFish = not statusFish
                    plantedPlant[2] = 0
                    plantedPlant.cur = 2
                    systemMessage("����������� \""..data.item[2][data.selectedFish][2].."\" ({c0c0c0}"..data.amountFish.." ��.{ffffff}) "..(statusFish and "��������" or "���������").."!")
                    if statusFish then
                        searchPlant(plantedPlant.cur, data.selectedFish)
                    else
                        planting = false
                        clicker = false
                        plantMenu(2) 
                    end
                elseif dialogData[22].list == 2 then changeItem(3)
                elseif dialogData[22].list == 3 then changeAmount(3)
                elseif dialogData[22].list == 4 then data.autoEatCleanAfterPlant = not data.autoEatCleanAfterPlant plantMenu(2)
                else plantMenu(2) end
            else mainDialog() end
        end

        if dialogData[23].result then
            if dialogData[23].button == 1 then
                if data.item[2][dialogData[23].list + 1][3] then
                    systemMessage("�������� ���� ���������� ��� ������� � ����!")
                    changeItem(3)
                else
                    data.selectedFish = dialogData[23].list + 1
                    plantMenu(2)
                    json('ghelper_data.json'):Save(data)
                end
            else mainDialog() end
        end

        if dialogData[24].result then
            if dialogData[24].button == 1 then
                if type(tonumber(dialogData[24].input)) == "number" then
                    if tonumber(dialogData[24].input) >= 1 and tonumber(dialogData[24].input) <= 8 then
                        data.amountFish = tonumber(dialogData[24].input)
                        plantMenu(2)
                        json('ghelper_data.json'):Save(data)
                    else systemMessage("��������� �������� ������ ���� ������ 1 � ������ 8!") changeAmount(3) end
                else systemMessage("��������� �������� �� �������� ������!") changeAmount(3) end
            else plantMenu(2) end
        end

        if dialogData[25].result then
            if dialogData[25].button == 1 then
                if dialogData[25].list == 0 then tempNewItem.fishType = false else tempNewItem.fishType = true end
                table.insert(data.items, {tonumber(tempNewItem.model), tempNewItem.name, false})
                table.insert(data.item[selectedTypeItem], {tonumber(tempNewItem.model), tempNewItem.name, tempNewItem.fishType})
                systemMessage("������� \""..tempNewItem.name.."\" [{c0c0c0}"..tempNewItem.model.."{ffffff}] ������� ��������!")
                changeListItem(selectedTypeItem)
                json('ghelper_data.json'):Save(data)
            else setNewItemModel() end
        end

        if dialogData[26].result then
            if dialogData[26].button == 1 then
                if dialogData[26].list == 0 then 
                    statusProcessFish = not statusProcessFish
                    systemMessage("��������� ��� "..(statusProcessFish and "��������" or "���������")..".")
                    if not statusProcessFish then
                        statusProcessFish = false
                        while #processPlants > 0 do table.remove(processPlants, 1) end
                        nowProcessPlant = 0
                        processedPlant = 0
                        processPlant = false
                        processMenu(2)
                    else systemMessage("��� ������, �������� ���� ������� �����.") end
                elseif dialogData[16].list == 2 then changeProcessType(2)
                elseif dialogData[16].list == 3 then changeAmountProcessPlant(2)
                else processMenu(2) end
            else mainDialog() end
        end

        if dialogData[27].result then
            --if statusAutoEatClean then sampSendDialogResponse(dialogData[27].id, 1, 0) end
            if dialogData[27].button == 1 then
                data.processTypeFish = dialogData[27].list + 1
                systemMessage("��� ��������� ����� ������� �� \""..data.processTypesFish[data.processTypeFish].."\".")
                processMenu(2)
                json('ghelper_data.json'):Save(data)
            else processMenu(2) end
        end

        if dialogData[28].result then
            if dialogData[28].button == 1 then
                if type(tonumber(dialogData[28].input)) == "number" then
                    if tonumber(dialogData[28].input) >= 1 and tonumber(dialogData[28].input) <= 8 then
                        systemMessage("���������� �������������� ��� �������� �� "..dialogData[28].input.." ��.")
                        data.amountProcessFish = tonumber(dialogData[28].input)
                        processMenu(2)
                        json('ghelper_data.json'):Save(data)
                    else systemMessage("��������� �������� ������ ���� �� 1 �� 8!") changeAmountProcessPlant(2) end
                else systemMessage("��������� �������� �� �������� ������!") changeAmountProcessPlant(2) end
            else processMenu(2) end
        end

        if dialogData[29].result then
            if dialogData[29].button == 1 then
                if type(tonumber(dialogData[29].input)) == "number" then
                    if tonumber(dialogData[29].input) >= 1 and tonumber(dialogData[29].input) <= 1000 then
                        data.interval = tonumber(dialogData[29].input)
                        gardenCatcher()
                        json('ghelper_data.json'):Save(data)
                    else systemMessage("��������� �������� ������ ���� ������ 1 � ������ 1000!") changeInterval() end
                else systemMessage("��������� �������� �� �������� ������!") changeInterval() end
            else gardenCatcher() end
        end
    end
end

ckickTextdrawThread = lua_thread.create_suspended(function()
    while true do
        wait(tonumber(data.interval))
        for i = 1, #data.selectedSlots do
            sampSendClickTextdraw(data.selectedSlots[i])
        end
    end
end)

function changeInterval()
    return sampShowDialog(dialogData[29].id, "{ff0000}�������� �����", "{ffffff}������� �������� ����� �� �����\n{c0c0c0}�� ����� 1000 �����������.", "��������", "�����", 1)
end

function listItems()
    local text = ""
    for i = 1, #data.items do text = text.."� "..data.items[i][2].."\t"..(data.items[i][3] and "{00ff00}���������{ffffff}" or "{ff0000}�� ���������{ffffff}").."\n" end
    return sampShowDialog(dialogData[21].id, "{ff0000}������ ���������", text, "�������", "�����", 4)
end

function gardenCatcherBuy()
    local text = "������\t"..(statusCatcherBuy and "{00ff00}�������" or "{ff0000}��������").."\n\
\t \n\
� ������ ���������"
    return sampShowDialog(dialogData[20].id, "{ff0000}���� �������", text, "�������", "�����", 4)
end

function changeAmountProcessPlant(type)
    if type == 1 then
        return sampShowDialog(dialogData[19].id, "{ff0000}��������� �������� {ffffff}| ����������", "{ffffff}������� ���������� �������������� ��������\n{c0c0c0}�� ������ 30 ����.", "��������", "�����", 1)
    elseif type == 2 then
        return sampShowDialog(dialogData[28].id, "{ff0000}��������� ����� {ffffff}| ����������", "{ffffff}������� ���������� �������������� ��� � �����\n{c0c0c0}�� ������ 8 ����.", "��������", "�����", 1)
    end
end

function changeProcessType(type)
    if type == 1 then
        return sampShowDialog(dialogData[18].id, "{ff0000}��������� �������� {ffffff}| ��� ���������", "{ffffff}���������\n��������\n��������� � ��������", "��������", "�����", 2) --[[\n��������� � ��������]]
    elseif type == 2 then
        return sampShowDialog(dialogData[27].id, "{ff0000}��������� ����� {ffffff}| ��� ���������", "{ffffff}���������\n��������� ����", "��������", "�����", 2)
    end
end

function changeProcessStatus()
    return sampShowDialog(dialogData[17].id, "{ff0000}��������� �������� {ffffff}| ������ ��������", "{ffffff}�������\n������\n�������� ��������\n�����", "��������", "�����", 2)
end

function processMenu(type)
    if type == 1 then
        return sampShowDialog(dialogData[16].id, "{ff0000}��������� ��������", "{ffffff}"..(statusProcessPlant and "����������" or "���������").." ��������� ��������\t \n\
\t \n\
� ������ ��������\t"..data.plantStatuses[data.plantStatus].."\n\
� ��� ���������\t"..data.processTypes[data.processType].."\n\
� ���-�� �������������� ��������\t"..data.amountProcessPlant.." ��.", "�������", "�����", 4)
    elseif type == 2 then
        return sampShowDialog(dialogData[26].id, "{ff0000}��������� �����", "{ffffff}"..(statusProcessFish and "����������" or "���������").." ��������� ���\t \n\
\t \n\
� ��� ���������\t"..data.processTypesFish[data.processTypeFish].."\n\
� ���-�� �������������� ����\t"..data.amountProcessFish.." ��.", "�������", "�����", 4)
    end
end

function setNewItemFishType()
    return sampShowDialog(dialogData[25].id, "{ff0000}���������� �������� {ffffff}| ��� ����", "{ffffff}�����\n��������", "��������", "�����", 2)
end

function setNewItemModel()
    return sampShowDialog(dialogData[15].id, "{ff0000}���������� �������� {ffffff}| ID ������", "{ffffff}������� ID ������ ��� ������� �������� � ���� ����:", "�����", "�����", 1)
end

function addItem()
    return sampShowDialog(dialogData[14].id, "{ff0000}���������� �������� {ffffff}| ��������", "{ffffff}������� �������� ��� �������� �������� � ���� ����.\
{c0c0c0}�� 3 �� 45 ��������.", "�����", "�����", 1)
end

function changeTypeItem()
    return sampShowDialog(dialogData[13].id, "{ff0000}"..data.item[selectedTypeItem][selectedIDItem][2].." {ffffff}| ������", "{ffffff}1. ��������\n2. ����", "��������", "�����", 2)
end

function changeModelItem()
    return sampShowDialog(dialogData[12].id, "{ff0000}"..data.item[selectedTypeItem][selectedIDItem][2].." {ffffff}| ID ������", "{ffffff}������� ����� ID ������ ��� ������� �������� � ���� ����:", "��������", "�����", 1)
end

function changeNameItem()
    return sampShowDialog(dialogData[11].id, "{ff0000}"..data.item[selectedTypeItem][selectedIDItem][2].." {ffffff}| ��������", "{ffffff}������� ����� �������� ��� ������� �������� � ���� ����.\
{c0c0c0}�� 3 �� 45 ��������.", "��������", "�����", 1)
end

function editItem(id)
    return sampShowDialog(dialogData[10].id, "{ff0000}"..data.item[selectedTypeItem][id][2], "{ffffff}�������� ��������\n�������� ID ������\n�������� ������\n�������", "�������", "�����", 2)
end

function changeListItem(type)
    local caption = ""
    local text = "� ��������\n \n"
    selectedTypeItem = type
    if type == 1 then caption = "��������"
    elseif type == 2 then caption = "����"
    end
    if #data.item[type] > 0 then for i = 1, #data.item[type] do text = text.."[{ff0000}"..data.item[type][i][1].."{ffffff}]"..((type == 2) and "["..(data.item[type][i][3] and "{ff0000}�" or "{00ff00}�").."{ffffff}]" or "").." "..data.item[type][i][2].."\n" end
    else text = text.."�����." end
    return sampShowDialog(dialogData[9].id, "{ff0000}"..caption, text, "�������", "�����", 2)
end

function listTypeItems()
    return sampShowDialog(dialogData[8].id, "{ff0000}������ ���������", "1. ��������\n2. ����", "�������", "�����", 2)
end

function plantMenu(type)
    if type == nil then type = 1 end
    if type == 1 then
        if data.selectedPlant > #data.item[1] then data.selectedPlant = 1 systemMessage("��������� ����� �������� �����������. �������� ���������� �� ���������.") systemMessage("���� �������� �������� - �������� �������� � ������.") return mainDialog() end
        local text = (statusPlant and "����������" or "���������").." �����������\t \n\
\t \n\
� �������� ��� �������\t"..data.item[1][data.selectedPlant][2].."\n\
� ���������� �����\t"..data.amountPlant.." ��."
        return sampShowDialog(dialogData[5].id, "{ff0000}���� ������� ��������", text, "�������", "�����", 4)
    elseif type == 2 then
        if data.selectedFish > #data.item[2] then data.selectedFish = 1 systemMessage("��������� ����� ���� �����������. �������� ���������� �� ���������.") systemMessage("���� �������� �������� - �������� ��� � ������.") return mainDialog() end
        local text = (statusFish and "����������" or "���������").." �����������\t \n\
\t \n\
� ���� ��� �������\t"..data.item[2][data.selectedFish][2].."\n\
� ���������� ���\t"..data.amountFish.." ��.\n\
� ������������� ������� � ������� ����\t"..(data.autoEatCleanAfterPlant and "{00ff00}��" or "{ff0000}���")
        return sampShowDialog(dialogData[22].id, "{ff0000}���� ������� ���", text, "�������", "�����", 4)
    end
end

function changeAmount(type)
    if type == nil then type = 1 end
    if type == 1 then
        return sampShowDialog(dialogData[3].id, "{ff0000}���������� ������", "{ffffff}������� � ���� ���� ���������� ������ ��� �������.\
{c0c0c0}�������� �� ����� ���� ������ 10.\n��� ������ ������, ��� ������ ����������� ������.", "�������", "�����", 1)
    elseif type == 2 then
        return sampShowDialog(dialogData[7].id, "{ff0000}���������� �����", "{ffffff}������� � ���� ���� ���������� ������������� ��������.\
{c0c0c0}�������� �� ����� ���� ������ 50.", "�������", "�����", 1)
    elseif type == 3 then
        return sampShowDialog(dialogData[24].id, "{ff0000}���������� �������", "{ffffff}������� � ���� ���� ���������� ������������ �������.\
{c0c0c0}�������� �� ����� ���� ������ 8.", "�������", "�����", 1)
    end
end

function changeItem(type)
    if type == nil then type = 1 end
    local text = ""
    if type == 2 then
        for i = 1, #data.item[1] do text = text.."� "..data.item[1][i][2].."\n" end
        return sampShowDialog(dialogData[6].id, "{ff0000}������ ��������", text, "�������", "�����", 2)
    elseif type == 3 then
        for i = 1, #data.item[2] do text = text.."� "..data.item[2][i][2].."\n" end
        return sampShowDialog(dialogData[23].id, "{ff0000}������ ���", text, "�������", "�����", 2)
    end
end

function gardenCatcher()
    local text = "������\t"..(status and "{00ff00}�������" or "{ff0000}��������").."\n\
\t \n\
� ������� ������\t"..#data.selectedSlots.." ��.\n\
� �������� �����\t"..data.interval.." ��."
    return sampShowDialog(dialogData[4].id, "{ff0000}���� ������", text, "�������", "�����", 4)
end

function mainDialog()
    local text = "������ ���������\n \n\
[{85bb65}${ffffff}] ���� ������\n\
[{85bb65}${ffffff}] ���� �������\n \n\
���� ������� ��������\n\
���� ������� ���\n\
���� ��������� ��������\n\
���� ��������� �����\n \n\
� "..(autoGetPlants and "����������" or "���������").." ���� ����/�������� � �������\n\
 \n\
��������� ���� �� �������: {696969}"..keys.id_to_name(data.keyActivate).."\n"..(updateStatus and "[{ff0000}+{ffffff}] �������� �� ������ {ff0000}"..newVersion or "")
    return sampShowDialog(dialogData[1].id, "{ff0000}������� ����", text, "�������", "�������", 2)
end

function systemMessage(text) return sampAddChatMessage("|{ffffff} "..tostring(text), 0xFFFF0000) end

function onScriptTerminate(script, quit)
    if script == thisScript() then
        json('ghelper_data.json'):Save(data)
        systemMessage("������ \""..thisScript().name.."\" ��������� �������� ���� ������!")
    end
end

local url4 = "garden-helper"

function searchPlant(type, plant)
    if plantedPlant[type] < ((type == 1) and data.amountPlant or data.amountFish) then
        if dataInv.id ~= -1 then return systemMessage("Wait a moment..") end
        dataInv.id = data.item[type][plant][1]
        dataInv.clock = os.clock()
        pageInv.cur = 1
        lua_thread.create(function()
            while true do wait(0)
                if dataInv.id ~= -1 then
                    printStringNow("~r~Search item..", 50)
                    if os.clock() - dataInv.clock >= TIMEOUT then
                        if dataInv.step == 0 and pageInv.cur < 4 then
                            pageInv.cur = pageInv.cur + 1
                            dataInv.clock = os.clock()
                            sampSendClickTextdraw(pageInv[pageInv.cur])
                        elseif dataInv.step > 0 then
                            systemMessage("Error get item! Try again. Code: #1") -- is not to use
                            close_inventory()
                            statusPlant = false
                            statusFish = false
                            plantedPlant[type] = 0
                            planting = false
                            clicker = false
                        elseif pageInv.cur > 1 then
                            systemMessage(((type == 1) and "��������" or "����").." \""..data.item[type][plant][2].."\" �� ������� � ����� ���������.")
                            statusPlant = false
                            statusFish = false
                            plantedPlant[type] = 0
                            planting = false
                            clicker = false
                            close_inventory()
                            plantMenu(type)
                        else
                            systemMessage("Error get item! Try again. Code: #2") -- time out
                            close_inventory()
                            statusPlant = false
                            statusFish = false
                            plantedPlant[type] = 0
                            planting = false
                            clicker = false
                        end
                    end
                end
            end
        end)
        sampSendChat("/invent")
    else
        systemMessage("������� "..((type == 1) and "��������" or "����").." \""..data.item[type][plant][2].."\" ���������!")
        if type == 2 and data.autoEatCleanAfterPlant then systemMessage("�������� �������������� ��������� �����.")
            data.processTypeFish = 1
            statusFish = true
            statusProcessFish = true --[[statusAutoEatClean = true sampSendChat("/ghelper")]]
            lua_thread.create(function()
                wait(50)
                setVirtualKeyDown(0xA4, true)
                wait(5)
                setVirtualKeyDown(0xA4, false)
                processPlant = false
            end)
        else
            statusFish = false
        end
        sampSendChatServer("/ghelper")
        plantMenu(type)
        statusPlant = false
        plantedPlant[type] = 0
        clicker = false
        planting = false
        dataInv.clock = os.clock()
        dataInv.step = 0
        dataInv.id = -1
    end
end

function sampSendChatServer(cmd) 
    dontSendCommandServer = true
    sampSendChat(cmd)
end

function ev.onServerMessage(color, text)
    if dontSendCommandServer and text:find("����������� �������!") then
        return false
    end
end

--[[function ev.onCreateObject(id, object)
    local myPos = {getCharCoordinates(PLAYER_PED)}
    if getDistanceBetweenCoords2d(myPos[1], myPos[2], object.position.x, object.position.y) < 20 then
        for i = 1, #data.items do
            if tonumber(data.items[i][1]) == object.modelId then
                Plants[Plant+1] = sampCreate3dText(data.items[i][2].."\n�� ��������\n�� ����������", 0xFFFF0000, object.position.x, object.position.y, object.position.z + 1.5, 5.0, true)
                systemMessage("Model: "..object.modelId)
            end
        end
        --systemMessage("Model: "..data.modelId)
    end
end]]

local sellItem = false
function ev.onShowTextDraw(id, textdraw)
    --systemMessage(id..") "..textdraw.text)
    --systemMessage(textdraw.modelId..") "..textdraw.zoom)
    --if textdraw.modelId == 4156 then
        --[[local epsilon = 0.0001
        local statusMalek
        if math.abs(textdraw.zoom - 1) < epsilon then
            statusMalek = "�����"
        elseif math.abs(textdraw.zoom - 0.80000001192093) < epsilon then
            statusMalek = "��������"
        end
        systemMessage("������: 9445. �������: "..statusMalek) -- 0.8 - ��������, 1 - ����� // 1 - ��������]]
        --systemMessage(textdraw.text)
    --end

    if statusCatcherBuy and not sellItem then
        local takeFish = 0
        for i = 1, #data.items do -- ���������� ��� ���� ��������
            if data.items[i][3] and textdraw.modelId == data.items[i][1] then -- ������� ��� ����� � ��� ID = ID � ������
                for j = 1, #data.item[2] do -- ���������� ���� ����
                    if data.item[2][j][2] == data.items[i][2] then -- ���� ��� ������ ���� � ���������� (���������� �� ����� � ��������)
                        if data.item[2][j][3] and (math.abs(textdraw.zoom - 0.80000001192093) < 0.0001) then -- ���� ���� ��������
                            --systemMessage("������� ���� \""..data.items[i][2].."\"..")
                            sampSendClickTextdraw(id)
                            sellItem = true
                            selectedIDItem = i
                            break
                        end
                        takeFish = takeFish + 1
                    end
                end
                --if takeFish == 0 then systemMessage(textdraw.modelId..") "..textdraw.zoom) end
                if takeFish == 0 and (math.abs(textdraw.zoom - 1) < 0.0001) then -- ���� ���� ���� ���������� ��� ����� ����
                    --systemMessage("������� ������� \""..data.items[i][2].."\"..")
                    sampSendClickTextdraw(id)
                    sellItem = true
                    selectedIDItem = i
                    takeFish = 0
                end
                break
            end
        end
    end

    if dataInv.id ~= -1 then
		if dataInv.step == 0 then
            if textdraw.modelId == tonumber(dataInv.id) and math.abs(textdraw.zoom - 1) < 0.0001 then -- ������ ��������� � ��� �����
                dataInv.clock = os.clock()
                sampSendClickTextdraw(id)
                dataInv.step = 1
            end
		elseif dataInv.step == 1 then
            if id == 2302 and textdraw.text == 'USE' or dataInv.text == '�C�O���O�A��' then
                planting = true
                sampSendClickTextdraw(id)
                sampSendClickTextdraw(0xFFFF)
                dataInv.clock = os.clock()
                dataInv.step = 0
                dataInv.id = -1
                plantedPlant[plantedPlant.cur] = plantedPlant[plantedPlant.cur] + 1
            end
		end
	    return false
	end
end

local url2 = "main/licenses.txt"

function close_inventory() --
	for i = 0, 1 do
		if i <= dataInv.step then sampSendClickTextdraw(0xFFFF) end
	end
    dataInv.step = 0
	dataInv.id = -1
end

function onReceiveRpc(id, bs)
	if dataInv.id ~= -1 and id == 83 then
		return false
	end
end

function ev.onSendClickTextDraw(id)
    --systemMessage(sampTextdrawGetString(id))
    if statusChangeSlots then
        local error = false
        for i = 1, #data.selectedSlots do
            if data.selectedSlots[i] == id then
                error = true
                systemMessage("������ ���� ��� ������� � ����.")
                break
            end
        end
        if not error and id ~= 2056 and id ~= 65535 then 
            systemMessage("���� ID: "..id.." ��������.") 
            table.insert(data.selectedSlots, id)
        elseif id == 2056 or id == 65535 then
            statusChangeSlots = false
            systemMessage("���� �������. ������ ������ ���������.")
        end
    end

    if (id == 2056 or id == 65535) and (statusCatcherBuy or status) then
        statusCatcherBuy = false
        if status then ckickTextdrawThread:terminate() status = false end
        systemMessage("�������/������� ��������� ���������. ���� �������.")
    end
    --systemMessage(id)
end

local getPlant = false
local processPlant = false
local nowProcessPlant = 0
local processedPlants = 0
function ev.onShowDialog(id, style, title, button_1, button_2, text)
    --systemMessage(id..") "..style..". "..title..". "..text)
    if statusCatcherBuy and sellItem and title:find("���������� �������") then
        if not text:find("� ��� ��� ������� ��������!") then
            local shopBuyingAmount = 0
            local myAmount = 0
            local sellAmount = 0
            local item = text:match("%{FFFFFF%}�������%:%s%{FDCF28%}(.+)%{FFFFFF%}\n.+%{FDCF28%}")
            shopBuyingAmount, myAmount = text:match("%{FFFFFF%}\n\n���������%:%s%{63C678%}%d+%s���%.%{FFFFFF%}\n��������� ����������%:%s%{63C678%}(%d+)%s��%.%{FFFFFF%}\n\n� ��� � ���������%:%s%{63C678%}(%d+)%s��%.\n\n%{cccccc%}")
            --systemMessage("������� \""..item.."\". ������� �������: "..shopBuyingAmount.." ��. � ���: "..myAmount.." ��.")
            local sellAmount = (tonumber(shopBuyingAmount) <= tonumber(myAmount)) and tonumber(shopBuyingAmount) or tonumber(myAmount)
            systemMessage("������� \""..item.."\" ({c0c0c0}"..sellAmount.." ��.{ffffff})..")
            sampSendDialogResponse(id, 1, 0, sellAmount)
            --data.items[selectedIDItem][3] = false
            sellItem = false
        else
            systemMessage("� ��� ����������� ������� \""..data.items[selectedIDItem][2].."\". �� ��� �������� �� �������.")
            data.items[selectedIDItem][3] = false
            sellItem = false
        end
    end

    if status and style == 1 and text:find("����� ���������� � �������� �����������") then
        local item = text:match("%{FFFFFF%}�������%:%s%{FDCF28%}(.+)%{FFFFFF%}\n.+%{FDCF28%}")
        local amount = text:match("%{FFFFFF%}\n\n���������%:%s%{63C678%}%d+%s���%.%{FFFFFF%}\n��������� ����������%:%s%{63C678%}(%d+)%s��%.%{FFFFFF%}")
        --if not item:find("������") then
            systemMessage("����� \""..item.."\" ({c0c0c0}"..(amount).." ��.{ffffff}).")
            sampSendDialogResponse(id, 1, 0, tonumber(amount))
        --else
            --sampSendDialogResponse(id, 0, 0, -1)
        --end
    end

    if autoGetPlants and style == 5 and title:find("������� �������") then
        local lineNumber = 0
        local itemsToGet = 0
        for line in text:gmatch("[^\r\n]+") do
            lineNumber = lineNumber + 1
            if not line:match("^���:\t������:\t�����:") and (autoGetPlants and (line:find("������") or line:find("�������")) or (line:find("��������") or line:find("�������"))) then
                itemsToGet = itemsToGet + 1
                sampSendDialogResponse(id, 1, lineNumber-2, nil)
                getPlant = true
                break
            end
        end
        if itemsToGet == 0 then
            systemMessage("��������/��� ��� ����� �� �������! �������� ��������.")
            autoGetPlants = false
            getPlant = false
            mainDialog()
        end
    end

    if (statusProcessPlant or statusProcessFish) and style == 5 and title:find("������� �������") then
        if nowProcessPlant == 0 then
            local lineNumber = 0
            local itemsToProcess = 0
            for line in text:gmatch("[^\r\n]+") do
                lineNumber = lineNumber + 1
                if not line:match("^���:\t������:\t�������� �������:") then
                    if statusProcessPlant then
                        if not line:find("�������") and not line:find("������") then
                            if line:find(data.plantStatuses[data.plantStatus]) or data.plantStatus == 4 then
                                table.insert(processPlants, lineNumber-2)
                                itemsToProcess = itemsToProcess + 1
                            end
                        end
                    elseif statusProcessFish then
                        if line:find("����") then
                            table.insert(processPlants, lineNumber-2)
                            itemsToProcess = itemsToProcess + 1
                        end
                    end
                end
            end

            if itemsToProcess == 0 then
                systemMessage((statusProcessFish and "����" or "��������").." ��� ��������� �� �������!")
                statusProcessPlant = false
                statusProcessFish = false
                processMenu(statusProcessFish and 2 or 1)
            end
        end

        if nowProcessPlant < #processPlants and processedPlants < (statusProcessFish and data.amountProcessFish or data.amountProcessPlant) then -- �� �������������� ��������� �������� ��-�� ������� ������� nowProcessPlant < #processPlants (1 < #1)
            nowProcessPlant = nowProcessPlant + 1
            --systemMessage(nowProcessPlant)
            sampSendDialogResponse(id, 1, processPlants[nowProcessPlant], nil)
            processPlant = true
        else
            systemMessage("��������� "..(statusProcessFish and "���" or "��������").." ({c0c0c0}"..(processedPlants).." �� "..(statusProcessFish and data.amountProcessFish or data.amountProcessPlant).." ��.{ffffff}) ���������.")
            if statusFish and data.autoEatCleanAfterPlant and data.processTypeFish == 1 then 
                --systemMessage("�������� �������������� ������ �����.")
                data.processTypeFish = 2
                --sampSendDialogResponse(id, 1, 0, nil)
                statusFish = true
                statusProcessFish = true
                lua_thread.create(function()
                    sampSendChatServer("/ghelper")
                    wait(100)
                    setVirtualKeyDown(0xA4, true)
                    wait(5)
                    setVirtualKeyDown(0xA4, false)
                    processPlant = false
                end)
            else
                if statusProcessFish then
                    statusFish = false
                    statusProcessFish = false
                    systemMessage("�������������� ��������� ����� ���������.")
                    sampSendChatServer("/ghelper")
                    plantMenu(2)
                end
            end

            if statusProcessPlant and data.processType == 3 then
                if stageProcessPlant == 1 then
                    stageProcessPlant = 2
                    --systemMessage("�������� ��������� ����������.")
                    statusProcessPlant = true
                    lua_thread.create(function()
                        -- sampSendChatServer("/ghelper")
                        -- wait(100)
                        setVirtualKeyDown(0xA4, true)
                        wait(5)
                        setVirtualKeyDown(0xA4, false)
                        processPlant = false
                    end)
                else
                    stageProcessPlant = 1
                    statusProcessPlant = false
                end
            else
                stageProcessPlant = 1
                statusProcessPlant = false
            end
            --statusProcessPlant = false
            while #processPlants > 0 do table.remove(processPlants, 1) end
            nowProcessPlant = 0
            processedPlants = 0
            processPlant = false
            processMenu(statusProcessFish and 2 or 1)
        end
    end

    if (statusProcessPlant or statusProcessFish) and processPlant and style == 4 and (statusProcessPlant and text:find("������� ���������") or text:find("������� �������")) then
        local lineNumber = 0
        local n = 0
        for line in text:gmatch("[^\r\n]+") do
            lineNumber = lineNumber + 1
            if (statusProcessPlant and ((data.processType == 1 and line:find("��������")) or (data.processType == 2 and line:find("����������")) or (data.processType == 3 and (stageProcessPlant == 1 and line:find("��������") or line:find("����������")))) or ((data.processTypeFish == 1 and line:find("���������")) or (data.processTypeFish == 2 and line:find("������� ����")))) then
                processedPlants = processedPlants + 1
                --systemMessage("��������� �������� �"..nowProcessPlant.."..")
                sampSendDialogResponse(id, 1, lineNumber - 1, nil)
                lua_thread.create(function()
                    wait(50)
                    setVirtualKeyDown(0xA4, true)
                    wait(5)
                    setVirtualKeyDown(0xA4, false)
                    processPlant = false
                end)
                n = n + 1
                break
            end
        end
        if n == 0 then
            --systemMessage("�������� �"..nowProcessPlant.." ��� ��������.")
            sampSendDialogResponse(id, 0, -1, nil)
        end
    end

    if autoGetPlants and getPlant and style == 4 and (autoGetPlants and (text:find("�������") or text:find("�������")) or (text:find("�������"))) then
        local lineNumber = 0
        for line in text:gmatch("[^\r\n]+") do
            lineNumber = lineNumber + 1
            if (autoGetPlants and (line:find("�������") or line:find("�������")) or (line:find("�������"))) then
                lua_thread.create(function()
                    sampSendDialogResponse(id, 1, lineNumber-1, nil)
                    wait(50)
                    setVirtualKeyDown(0xA4, true)
                    wait(5)
                    setVirtualKeyDown(0xA4, false)
                    getPlant = false
                end)
                break
            end
        end
    end
end

function onReceivePacket(id, bs)
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        if (raknetBitStreamReadInt8(bs) == 17) then
            raknetBitStreamIgnoreBits(bs, 32)
            local str = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
            if str:find("%\"�� ������ ������ �� ������ ������ ��� ������������� �������� �������%\"") and statusPlant then
                statusPlant = false
                plantMenu(1)
                systemMessage("��� ������� �������� �� ������ ���������� �� ���������� ������ �������!")
            end

            if str:find("%\"�� ���� ������ ��� �����%\"") and statusPlant then
                statusPlant = false
                plantMenu(1)
                systemMessage("�� ������ ������ ������ �������� �� ����������!")
            end

            if str:find("%\"� ���� ����� ��� �����%\"") and statusFish then
                if statusFish and data.autoEatCleanAfterPlant and data.processTypeFish == 1 then
                    systemMessage("�������� �������������� ��������� �����.")
                    data.processTypeFish = 2
                    statusFish = true
                    statusProcessFish = true
                    lua_thread.create(function()
                        sampSendChatServer("/ghelper")
                        wait(100)
                        setVirtualKeyDown(0xA4, true)
                        wait(5)
                        setVirtualKeyDown(0xA4, false)
                        processPlant = false
                    end)
                else
                    statusFish = false
                    plantMenu(2)
                end
                systemMessage("� ������ ���� ������ ��� �� ����������!")
            end

            if str:find("%\"�� ������ ������ � ����� ������ ��� ������������� �������� �������%\"") and statusFish then
                statusFish = false
                plantMenu(2)
                systemMessage("��� ������� ���� � ����, �� ������ ���������� �� ���������� ������ �������!")
            end

            if str:find("%\"� ��� �� ������� ����� ��� ���. ������ �� � �������� �����������!%\"") and statusProcessFish then
                systemMessage("� ��� ���������� ���� ��� ���! ��������� ��������.")
                data.processTypeFish = 1
                statusFish = false
                statusProcessFish = false
                while #processPlants > 0 do table.remove(processPlants, 1) end
                nowProcessPlant = 0
                processedPlants = 0
                processPlant = false
                mainDialog()
            end

            if str:find("%\"� ���� ����� ��� ���%\"") and (autoGetPlants or statusProcessFish) then
                systemMessage("� ���� ����� ��� ��� ��� ����� ��� ���������!")
                autoGetPlants = false
                statusFish = false
                statusPlant = false
                statusProcessFish = false
                statusProcessPlant = false
                nowProcessPlant = 0
                processedPlants = 0
                processPlant = false
                getPlant = false
                mainDialog()
            end

            if str:find("%\"�� ���� ������ ������ �� ������%\"") and (autoGetPlants or statusProcessPlant) then
                systemMessage("�� ���� ������ ��� �������� ���������� ����� ��� ���������!")
                statusProcessPlant = false
                autoGetPlants = false
                getPlant = false
                mainDialog()
            end

            if str:find("%\"� ��� �� ������� ���������. ������ �� � �������� �����������!%\"") and statusProcessPlant then
                systemMessage("� ��� ����������� ���������! ��������� ��������.")
                statusProcessPlant = false
                while #processPlants > 0 do table.remove(processPlants, 1) end
                nowProcessPlant = 0
                processedPlants = 0
                processPlant = false
                mainDialog()
            end

            if str:find("%\"� ��� �� ������� ���������. ������ �� � �������� �����������!%\"") and statusProcessPlant then
                systemMessage("� ��� ����������� ��������! ��������� ��������.")
                statusProcessPlant = false
                while #processPlants > 0 do table.remove(processPlants, 1) end
                nowProcessPlant = 0
                processedPlants = 0
                processPlant = false
                mainDialog()
            end

            if str:find("`progressBar/updateData`,{progress:%d+,keyCode:\"LeftMouse\"}") and not clicker and planting then clicker = true end

            if str:find("%`progressBar%/updateData%`%,%{progress%:0%,keyCode%:%\"%\"%}") and clicker then
                clicker = false
                planting = false
                searchPlant(plantedPlant.cur, ((plantedPlant.cur == 1) and data.selectedPlant or data.selectedFish))
            end
        end
    end
end

function ev.onApplyPlayerAnimation(playerId, animLib, animName, frameDelta, loop, lockX, lockY, freeze, time)
    local _, pID = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if statusProcessFish or statusProcessPlant or autoGetPlants then
        if playerId == pID then
            return taskPlayAnim(PLAYER_PED, "camcrch_stay", "CAMERA", 4.0, false, false, true, false, 1)
        end
    end
    -- if playerId == pID then
    --     lua_thread.create(function()
    --         wait(500)
    --         return taskPlayAnim(PLAYER_PED, "camcrch_stay", "CAMERA", 4.0, false, false, true, false, 1)
    --     end)
    -- end
end

function getVIPByUrl(url)
    local n_file, bool, users = os.getenv('TEMP')..os.time(), false, {}
    downloadUrlToFile(url, n_file, function(id, status)
        if status == 6 then bool = true end
    end)
    while not doesFileExist(n_file) do wait(0) end
    if bool then
        local file = io.open(n_file, 'r')
        if file ~= nil then
            for w in file:lines() do
                local n, d, e = w:match('(.+) %: (.+) %- (.+)')
                users[#users+1] = { key = n, date_reg = d, date_end = e }
            end
            file:close()
        else
            return false
        end
        os.remove(n_file)
    end
    return bool, users
end

function buyers(buyers)
    if isAvailableUser(buyers, tostring(getHDD())) then return true end
    return false
end

function isAvailableUser(users, key)
    for i, k in pairs(users) do
        if k.key == key then
            local d_reg, m_reg, y_reg = k.date_reg:match('(%d+)%.(%d+)%.(%d+)')
            local d_end, m_end, y_end = k.date_end:match('(%d+)%.(%d+)%.(%d+)')
            local time = {
                day = tonumber(d_end),
                isdst = true,
                wday = 0,
                yday = 0,
                year = tonumber(y_end),
                month = tonumber(m_end),
                hour = 0
            }
            if os.time(time) >= os.time() then return true -- lic actual
            elseif os.time(time) < os.time() then return false end
        end
    end
    return false
end

function getUrl()
    local url0 = "sVor-LUA"
    local urll = url1.."/"..url0.."/"..url4.."/"..url2
    return urll
end

function getHDD()
    ffi.cdef[[
    int __stdcall GetVolumeInformationA(
        const char* lpRootPathName,
        char* lpVolumeNameBuffer,
        uint32_t nVolumeNameSize,
        uint32_t* lpVolumeSerialNumber,
        uint32_t* lpMaximumComponentLength,
        uint32_t* lpFileSystemFlags,
        char* lpFileSystemNameBuffer,
        uint32_t nFileSystemNameSize
    );
    ]]
    local serial = ffi.new("unsigned long[1]", 0)
    ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
    return serial[0]
end

function onSendRpc(id) 
    if fakeAFK then 
        return false 
    end 
end

function onSendPacket(id) 
    if fakeAFK then 
        return false 
    end 
end

function ev.onPlayerChatBubble(playerId, color, dist, duration, text)
    --systemMessage("["..playerId.."] "..color..". "..dist..". "..duration..". "..text)
    --print("["..playerId.."] "..color..". "..dist..". "..duration..". "..text)
end

function sendAFK(sec)
    local time = "00:00"
    if sec >= 5 * 60 then
        time = "5:00+"
    elseif sec >= 60 then
        local minutes = math.floor(sec / 60)
        local remainingSeconds = sec % 60
        time = string.format("%d:%02d", minutes, remainingSeconds)
    else
        time = string.format("%d ���.", sec)
    end

    local text = "������ {73B461}( "..time.." )"
    systemMessage(text)
    local _, myID = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, 353)
    raknetBitStreamWriteInt32(bs, -1) -- color
    raknetBitStreamWriteFloat(bs, 10.0) -- distance
    raknetBitStreamWriteInt32(bs, 3000) -- duration
    raknetBitStreamWriteInt8(bs, string.len(text)) -- length
    raknetBitStreamWriteString(bs, text)
    raknetEmulRpcReceiveBitStream(59, bs)
    raknetDeleteBitStream(bs)
end

fakeAFKThread = lua_thread.create_suspended(function()
    while true do
        wait(1000)
        timeFakeAFK = timeFakeAFK + 1
        sendAFK(timeFakeAFK)
    end
end)
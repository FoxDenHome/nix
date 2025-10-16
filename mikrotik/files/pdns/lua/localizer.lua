foxden_local4 = {}
foxden_local6 = {}

local function make_foxden_local(host, suffix4, suffix6)
    local loc4 = {}
    local loc6 = {}
    local defDest4
    local defDest6
    for subnet = 1,9 do
        local src = {'10.' .. subnet .. '.0.0/16', 'fd2c:f4cb:63be:' .. subnet .. '::/64'}
        local dest4 = {'10.' .. subnet .. '.' .. suffix4}
        local dest6 = {'fd2c:f4cb:63be:' .. subnet .. '::' .. suffix6}
        table.insert(loc4, {src, dest4})
        table.insert(loc6, {src, dest6})
        if subnet == 2 then
        defDest4 = dest4
        defDest6 = dest6
        end
    end
    table.insert(loc4, {{'0.0.0.0/0', '::/0'}, defDest4})
    table.insert(loc6, {{'0.0.0.0/0', '::/0'}, defDest6})
    foxden_local4[host] = loc4
    foxden_local6[host] = loc6
end

make_foxden_local('gateway', '0.1', '0001')
make_foxden_local('dns', '0.53', '0035')
make_foxden_local('ntp', '0.123', '007b')
make_foxden_local('router', '1.1', '0101')
make_foxden_local('routerbackup', '1.2', '0102')
make_foxden_local('ntpi', '1.123', '017b')

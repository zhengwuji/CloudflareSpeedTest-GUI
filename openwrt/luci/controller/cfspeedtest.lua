module("luci.controller.cfspeedtest", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/cfspeedtest") then
        return
    end
    
    entry({"admin", "services", "cfspeedtest"}, cbi("cfspeedtest/settings"), _("CF优选IP"), 80).dependent = true
    entry({"admin", "services", "cfspeedtest", "status"}, call("action_status")).leaf = true
    entry({"admin", "services", "cfspeedtest", "run"}, call("action_run")).leaf = true
    entry({"admin", "services", "cfspeedtest", "result"}, call("action_result")).leaf = true
end

function action_status()
    local e = {}
    e.running = luci.sys.call("pgrep -f cfspeedtest > /dev/null") == 0
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function action_run()
    luci.sys.call("/etc/init.d/cfspeedtest start &")
    luci.http.prepare_content("application/json")
    luci.http.write_json({status = "started"})
end

function action_result()
    local result = {}
    local file = io.open("/tmp/cfspeedtest_result.csv", "r")
    if file then
        local header = file:read("*line")
        for line in file:lines() do
            local parts = {}
            for part in line:gmatch("[^,]+") do
                table.insert(parts, part)
            end
            if #parts >= 5 then
                table.insert(result, {
                    ip = parts[1],
                    port = parts[2],
                    latency = parts[3],
                    loss = parts[4],
                    speed = parts[5]
                })
            end
        end
        file:close()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

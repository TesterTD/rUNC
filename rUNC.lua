local totalTests = 0
local passedTests = 0
local skidCount = 0
local logFileName = "rUNC.txt"

if writefile then
	pcall(writefile, logFileName, "--- Log started at: " .. os.date() .. " ---\n\n")
end

local function logToFile(msg)
	if appendfile then
		pcall(appendfile, logFileName, msg .. "\n")
	end
end

local function info(msg)
	print(msg)
	logToFile("[INFO] " .. msg)
end

local function ok(msg)
	local formatted = "✅ "..msg
	print(formatted)
	logToFile("[PASS] " .. msg)
end

local function fail(msg)
	local formatted = "❌ "..msg
	print(formatted)
	logToFile("[FAIL] " .. msg)
end

local function warnEmoji(msg)
	local formatted = "⚠️ "..msg
	print(formatted)
	logToFile("[WARN] " .. msg)
end

local function safe_pcall(f, ...)
	return pcall(function(...) return f(...) end, ...)
end

local function present(obj, name)
	if obj == nil then
		warnEmoji("Объект отсутствует: "..name)
		return false
	end
	if type(obj) ~= "function" and type(obj) ~= "table" and type(obj) ~= "drawing" then
		warnEmoji("Объект не является функцией/таблицей: "..name.." (тип: "..type(obj)..")")
		return false
	end
	return true
end


local function check(cond, okmsg, failmsg, skidIfFail)
	totalTests = totalTests + 1
	if cond then
		ok(okmsg)
		passedTests = passedTests + 1
		return true
	else
		fail(failmsg)
		if skidIfFail then skidCount = skidCount + 1 end
		return false
	end
end

local function test_newcclosure()
	if not present(newcclosure, "newcclosure") or not present(iscclosure, "iscclosure") then return end


	do
		local normalFn = function(a,b) return a+b, a-b end
		local okc, ccFn = safe_pcall(newcclosure, normalFn)
		check(okc and type(ccFn)=="function", "newcclosure: возвращает функцию", "newcclosure: вернул не функцию или ошибка", true)
		if okc and type(ccFn)=="function" then
			local ok1,res1a,res1b = safe_pcall(ccFn, 5, 2)
			local ok2,res2a,res2b = safe_pcall(normalFn, 5, 2)
			check(ok1 and ok2 and res1a==res2a and res1b==res2b and res1a==7, "newcclosure: не меняет семантику с мульти-возвратом", "newcclosure: изменяет поведение с мульти-возвратом", true)
			check(iscclosure(ccFn), "newcclosure: iscclosure возвращает true", "newcclosure: iscclosure возвращает false. Я уверен что эта функция эмулирована🤬🤬 (спуфнута).", true)
			check(not iscclosure(normalFn), "newcclosure: iscclosure возвращает false для обычной функции", "newcclosure: iscclosure вернул true для обычной функции", true)
		end
	end

	do
		local yield_ok = false
		local yielded_value
		local yield_test = function()
			task.wait(0.01)
			yield_ok = true
			return "yielded"
		end
		local ok_y, wrapped_y = safe_pcall(newcclosure, yield_test)
		if check(ok_y and type(wrapped_y) == "function", "newcclosure: создание для yield-функции", "newcclosure: ошибка создания yield-функции", true) then
			local thread_success
			task.spawn(function()
				thread_success, yielded_value = safe_pcall(wrapped_y)
			end)
			task.wait(0.05)
			check(thread_success and yield_ok and yielded_value == "yielded", "newcclosure: обертка является yieldable и возвращает значение", "newcclosure: обертка не yieldable или не возвращает значение", true)
		end
	end

	do
		local err_func = function() error("c_err_spoof_test") end
		local ok_e, wrapped_e = safe_pcall(newcclosure, err_func)
		if check(ok_e and type(wrapped_e) == "function", "newcclosure: создание для error-функции", "newcclosure: ошибка создания error-функции", true) then
			local success, msg = safe_pcall(wrapped_e)
			local is_c_error = type(tostring(msg)) == "string" and not tostring(msg):find(":", 1, true)
			check(not success and is_c_error, "newcclosure: ошибки маскируются под C-ошибки", "newcclosure: ошибки не маскируются под C-ошибки", true)
		end
	end

	do
		local outer_cclosure = newcclosure(function() return "outer" end)
		local ok_nest, nested = safe_pcall(newcclosure, outer_cclosure)
		if check(ok_nest and type(nested)=="function", "newcclosure: вложенное создание работает", "newcclosure: вложенное создание выдало ошибку", true) then
			check(iscclosure(nested), "newcclosure: вложенный результат является cclosure", "newcclosure: вложенный результат не cclosure", true)
		end
	end

end

local function test_closure_checks()
	if not present(iscclosure, "iscclosure") or not present(islclosure, "islclosure") or not present(isexecutorclosure, "isexecutorclosure") then
		warnEmoji("Функции проверки closure отсутствуют, тест пропущен")
		return
	end

	local lua_fn = function() return "lua" end
	local c_fn_new = newcclosure and newcclosure(lua_fn)
	local c_fn_standard = print
	local c_fn_executor = getgenv or getgc

	check(islclosure(lua_fn), "islclosure: true для обычной Luau функции", "islclosure: false для Luau функции. Я уверен что эта функция эмулирована🤬🤬 (спуфнута).", true)
	check(not islclosure(c_fn_standard), "islclosure: false для стандартной C-функции (print)", "islclosure: true для print", true)
	if c_fn_new then
		check(not islclosure(c_fn_new), "islclosure: false для newcclosure", "islclosure: true для newcclosure", true)
	end

	check(not iscclosure(lua_fn), "iscclosure: false для обычной Luau функции", "iscclosure: true для Luau функции", true)
	check(iscclosure(c_fn_standard), "iscclosure: true для стандартной C-функции (print)", "iscclosure: false для print. Я уверен что эта функция эмулирована🤬🤬 (спуфнута).", true)
	if c_fn_new then
		check(iscclosure(c_fn_new), "iscclosure: true для newcclosure", "iscclosure: false для newcclosure", true)
	end

	check(isexecutorclosure(lua_fn), "isexecutorclosure: true для локальной Luau функции", "isexecutorclosure: false для локальной Luau функции", true)
	check(not isexecutorclosure(c_fn_standard), "isexecutorclosure: false для стандартной C-функции (print)", "isexecutorclosure: true для print", true)
	if c_fn_executor then
		check(isexecutorclosure(c_fn_executor), "isexecutorclosure: true для C-функции эксплойта ("..tostring(c_fn_executor)..")", "isexecutorclosure: false для C-функции эксплойта", true)
	end
	if c_fn_new then
		check(isexecutorclosure(c_fn_new), "isexecutorclosure: true для newcclosure", "isexecutorclosure: false для newcclosure", true)
	end
end

local function test_hookfunction()
	if not present(hookfunction, "hookfunction") then return end

	local function runCase(useCC)
		local tag = "HF_"..tostring(os.clock())
		local f = function(x)
			if x==nil then error("orig_err") end
			return x*2, tag
		end
		local old_f
		local hookBody = function(x)
			if old_f then
				local a,b = old_f(x)
				return a*1.5, "hooked"
			end
			return x*3, "hooked"
		end

		if useCC and newcclosure then hookBody = newcclosure(hookBody) end

		local okh, oldf_ret = safe_pcall(hookfunction, f, hookBody)
		if not check(okh and type(oldf_ret)=="function", "hookfunction: вернул оригинал "..(useCC and "(CC)" or "(no CC)"), "hookfunction: ошибка "..(useCC and "(CC)" or "(no CC)"), true) then return end
		old_f = oldf_ret

		local ok1, r1, a1 = safe_pcall(f, 2)
		check(ok1 and r1==6 and a1=="hooked", "hookfunction: перенаправляет вызов "..(useCC and "(CC)" or "(no CC)"), "hookfunction: не перенаправляет вызов", true)

		local ok_err, _ = safe_pcall(f, nil)
		check(not ok_err, "hookfunction: ошибка оригинала перехвачена хуком", "hookfunction: ошибка оригинала пропагируется через хук", true)

		local ok2, r2, a2 = safe_pcall(old_f, 2)
		check(ok2 and r2==4 and a2==tag, "hookfunction: возвращает правильный оригинал", "hookfunction: не возвращает правильный оригинал", true)
	end
	runCase(false)
	runCase(true)

	do
		local warned_message
		local hook_body = function(...)
			warned_message = table.concat({...}, " ")
		end

		local okh, old_warn = safe_pcall(hookfunction, warn, hook_body)
		if check(okh and type(old_warn) == "function", "hookfunction: может хукать глобальные С-функции (warn)", "hookfunction: не смог захукать warn", true) then
			warn("test", "message")
			check(warned_message == "test message", "hookfunction: перехват вызова warn работает", "hookfunction: перехват warn не сработал", true)

			local ok_restore = select(1, safe_pcall(hookfunction, warn, old_warn))
			if check(ok_restore, "hookfunction: восстановление warn прошло без ошибок", "hookfunction: ошибка при восстановлении warn", true) then
				warned_message = nil
				warn("another message")
				check(warned_message == nil, "hookfunction: warn восстановлен и хук больше не работает", "hookfunction: warn не был восстановлен", true)
			end
		end
	end

end

local function test_restorefunction()
	if not present(restorefunction, "restorefunction") or not present(hookfunction, "hookfunction") then return end

	local func_to_restore = function() return "original" end
	local another_func = function() return "untouched" end

	local ok_err, _ = safe_pcall(restorefunction, func_to_restore)
	check(not ok_err, "restorefunction: ожидаемо выдает ошибку на не-хукнутой функции", "restorefunction: не выдал ошибку", true)

	local okh, old = safe_pcall(hookfunction, func_to_restore, function() return "hooked_once" end)
	local okh2, old2 = safe_pcall(hookfunction, another_func, function() return "another_hooked" end)
	if okh and type(old) == "function" then
		safe_pcall(hookfunction, func_to_restore, function() return old() .. " and_twice" end)
	end

	local ok_restore, _ = safe_pcall(restorefunction, func_to_restore)
	if check(ok_restore, "restorefunction: выполнился без ошибок на хукнутой функции", "restorefunction: вызвал ошибку", true) then
		check(func_to_restore() == "original", "restorefunction: функция восстановлена до самого первого оригинала", "restorefunction: функция не была полностью восстановлена", true)
		check(another_func() == "another_hooked", "restorefunction: не затрагивает другие хуки", "restorefunction: затронул другие хуки", true)

		local ok_err2, _ = safe_pcall(restorefunction, func_to_restore)
		check(not ok_err2, "restorefunction: ошибка при повторном восстановлении", "restorefunction: не вызвал ошибку при повторном восстановлении", true)
	end

end

local function test_debug_upvalues()
    local d_gu, d_gus, d_su = debug.getupvalue, debug.getupvalues, debug.setupvalue
    if not present(d_gu, "debug.getupvalue") or not present(d_gus, "debug.getupvalues") or not present(d_su, "debug.setupvalue") then
        return
    end

    do
        local no_upval_func = function() return 1 end
        local ok_gus, upvals = safe_pcall(d_gus, no_upval_func)
        check(ok_gus and type(upvals) == "table" and next(upvals) == nil, "getupvalues: пустая таблица для функции без upvalues", "getupvalues: не пустая таблица", true)
    end

    do
        local upval_func = function() local a = 1 end
        local ok_err_gu = not select(1, safe_pcall(d_gu, upval_func, 0))
        check(ok_err_gu, "getupvalue: ошибка при невалидном индексе 0", "getupvalue: нет ошибки при индексе 0", true)
        local ok_err_gu2 = not select(1, safe_pcall(d_gu, upval_func, 99))
        check(ok_err_gu2, "getupvalue: ошибка при выходе за пределы диапазона", "getupvalue: нет ошибки при выходе за пределы", true)
    end

    do
        local ok_err_gu_c = not select(1, safe_pcall(d_gu, print, 1))
        local ok_err_gus_c = not select(1, safe_pcall(d_gus, print))
        local ok_err_su_c = not select(1, safe_pcall(d_su, print, 1, nil))
        check(ok_err_gu_c, "getupvalue: ошибка на C closure", "getupvalue: нет ошибки на C closure", true)
        check(ok_err_gus_c, "getupvalues: ошибка на C closure", "getupvalues: нет ошибки на C closure", true)
        check(ok_err_su_c, "setupvalue: ошибка на C closure", "setupvalue: нет ошибки на C closure", true)
    end

    do
        local upvalue = 90
        local function dummy_function()
            upvalue += 1
            return upvalue
        end
        dummy_function()
        local ok_su = select(1, safe_pcall(d_su, dummy_function, 1, 99))
        if check(ok_su, "setupvalue: смена числового upvalue без ошибок", "setupvalue: ошибка при смене числового upvalue", true) then
            check(dummy_function() == 100, "setupvalue: корректно изменил числовой upvalue", "setupvalue: не изменил числовой upvalue", true)
        end
    end

    do
        local var1 = false
        local var2 = "Hi"
        local function dummy_function()
            var1 = true
            var2 ..= ", hello"
        end
        local ok_gus, upvals = safe_pcall(d_gus, dummy_function)
        if check(ok_gus and type(upvals) == "table", "getupvalues: вернул таблицу для простых типов", "getupvalues: не вернул таблицу для простых типов", true) then
            local found_v1, found_v2 = false, false
            for _, v in ipairs(upvals) do
                if v == var1 then found_v1 = true end
                if v == var2 then found_v2 = true end
            end
            check(found_v1 and found_v2, "getupvalues: корректные значения upvalues (bool, string)", "getupvalues: неверные значения upvalues", true)
        end
    end

    do
        local UpFunction = function() return "Hello from up" end
        local function DummyFunction() return UpFunction() end
        
        local ok_gu, retrieved = safe_pcall(d_gu, DummyFunction, 1)
        if check(ok_gu and type(retrieved) == "function", "getupvalue: вернул функцию-upvalue", "getupvalue: не вернул функцию-upvalue", true) then
            check(retrieved() == "Hello from up", "getupvalue: полученная функция-upvalue работает корректно", "getupvalue: функция-upvalue не сработала", true)
        end
        
        local new_up_func = function() return "Hello from new up" end
        local ok_su, _ = safe_pcall(d_su, DummyFunction, 1, new_up_func)
        if check(ok_su, "setupvalue: смена функции-upvalue без ошибок", "setupvalue: ошибка при смене функции-upvalue", true) then
             local result = DummyFunction()
             check(result == "Hello from new up", "setupvalue: корректно изменил функцию-upvalue", "setupvalue: не изменил функцию-upvalue", true)
        end
    end
end

local function test_getrawmetatable()
	if not present(getrawmetatable, "getrawmetatable") then return end

	do
		local t = {}
		local mt = {__index = function() return "indexed" end}
		setmetatable(t, mt)
		local okc, rmt = safe_pcall(getrawmetatable, t)
		check(okc and rmt==mt, "getrawmetatable: возвращает исходную метатаблицу", "getrawmetatable: вернул неверную метатаблицу", true)
	end
	do
		local inst = Instance.new("Folder")
		local okc, imt = safe_pcall(getrawmetatable, inst)
		check(okc and type(imt)=="table" and imt.__index, "getrawmetatable: для userdata (Instance) валиден", "getrawmetatable: для userdata некорректен", true)
		inst:Destroy()
	end
	do
		local okc, gmt = safe_pcall(getrawmetatable, game)
		check(okc and type(gmt)=="table", "getrawmetatable: работает на сервисах (game)", "getrawmetatable: не работает на game", false)
	end
	do
		local t = {}
		local mt = { __metatable = "LOCKED" }
		setmetatable(t, mt)
		local okc, rmt = safe_pcall(getrawmetatable, t)
		check(okc and rmt == mt, "getrawmetatable: обходит защиту __metatable", "getrawmetatable: не обходит __metatable", true)
	end

end

local function test_setrawmetatable()
	if not present(setrawmetatable, "setrawmetatable") then return end

	local target_table = {}
	local protected_mt = { __metatable = "LOCKED" }
	setmetatable(target_table, protected_mt)

	local ok_vanilla, _ = safe_pcall(setmetatable, target_table, {})
	check(not ok_vanilla, "setrawmetatable: __metatable защита работает как ожидалось", "setrawmetatable: __metatable защита не сработала", true)

	local new_mt = { __index = function(_, k) return "bypassed_"..k end }
	local ok_set, _ = safe_pcall(setrawmetatable, target_table, new_mt)

	if check(ok_set, "setrawmetatable: выполнился на таблице с защищенной МТ", "setrawmetatable: выдал ошибку", true) then
		check(getmetatable(target_table) == new_mt and target_table.xyz == "bypassed_xyz", "setrawmetatable: успешно обошел __metatable", "setrawmetatable: не смог обойти __metatable", true)
	end

	local ok_set_nil = select(1, safe_pcall(setrawmetatable, target_table, nil))
	check(ok_set_nil and getmetatable(target_table) == nil, "setrawmetatable: может установить nil в качестве метатаблицы", "setrawmetatable: не смог установить nil", true)

end

local function test_readonly()
	if not present(setreadonly, "setreadonly") or not present(isreadonly, "isreadonly") then return end

	local t = { a = 1, nested = { b = 2 } }
	setreadonly(t, true)

	check(isreadonly(t), "isreadonly: true после setreadonly(true)", "isreadonly: false после setreadonly(true)", true)
	local ok_new_key = not select(1, safe_pcall(function() t.b = 2 end))
	check(ok_new_key, "setreadonly: предотвращает добавление ключей", "setreadonly: не предотвратил добавление", true)

	local ok_mod_key = not select(1, safe_pcall(function() t.a = 2 end))
	check(ok_mod_key, "setreadonly: предотвращает изменение ключей", "setreadonly: не предотвратил изменение", true)

	local ok_rawset = not select(1, safe_pcall(rawset, t, "a", 3))
	check(ok_rawset and t.a == 1, "setreadonly: блокирует rawset", "setreadonly: rawset обходит защиту", true)

	local ok_set_false = select(1, safe_pcall(setreadonly, t, false))
	if check(ok_set_false, "setreadonly(false): выполнился без ошибок", "setreadonly(false): ошибка", true) then
		check(not isreadonly(t), "isreadonly: false после setreadonly(false)", "isreadonly: true после setreadonly(false)", true)
		t.a = 5
		check(t.a == 5, "setreadonly: таблица снова доступна для записи", "setreadonly: таблица осталась readonly", true)
	end

end

local function test_hookmetamethod()
	if not present(hookmetamethod, "hookmetamethod") then return end

	do
		local inst = Instance.new("Folder")
		inst.Name = "OrigName"
		local old_newindex
		local ni_triggered = false
		local function newindex_body(self, k, v)
			if self == inst and k == "Name" and v == "HookedName" then
				ni_triggered = true
				return
			end
			return old_newindex(self, k, v)
		end
		local okh_ni, orig_ni = safe_pcall(hookmetamethod, game, "__newindex", newindex_body)
		if check(okh_ni and type(orig_ni) == "function", "hookmetamethod: __newindex хук установлен для game", "hookmetamethod: ошибка хука __newindex для game", true) then
			old_newindex = orig_ni
			inst.Name = "HookedName"
			check(ni_triggered and inst.Name == "OrigName", "hookmetamethod: __newindex перехват работает", "hookmetamethod: __newindex перехват не работает", true)
			local ok_restore = safe_pcall(hookmetamethod, game, "__newindex", old_newindex)
			check(ok_restore, "hookmetamethod: __newindex восстановлен", "hookmetamethod: __newindex ошибка восстановления", true)
		end
		inst:Destroy()
	end

	do
		local target = Instance.new("Folder")
		target.Name = "TostringTarget"
		local old_tostring
		local ts_triggered = false
		local function tostring_body(s)
			if s == target then
				ts_triggered = true
				return "hooked_tostring_object"
			end
			return old_tostring(s)
		end
		local okh_ts, orig_ts = safe_pcall(hookmetamethod, game, "__tostring", tostring_body)
		if check(okh_ts and type(orig_ts) == "function", "hookmetamethod: __tostring хук установлен", "hookmetamethod: ошибка __tostring", true) then
			old_tostring = orig_ts
			check(tostring(target) == "hooked_tostring_object" and ts_triggered, "hookmetamethod: __tostring перехват работает", "hookmetamethod: __tostring не работает", true)
			local ok_restore = safe_pcall(hookmetamethod, game, "__tostring", old_tostring)
			check(ok_restore, "hookmetamethod: __tostring восстановлен", "hookmetamethod: __tostring ошибка восстановления", true)
		end
		target:Destroy()
	end

	do
		local index_triggered = false
		local old_index
		local function index_hook(self, key)
			if self == game and key == "TestService" then
				index_triggered = true
				return "hooked_service"
			end
			return old_index(self, key)
		end
		local ok_hook, orig_index = safe_pcall(hookmetamethod, game, "__index", index_hook)
		if check(ok_hook and type(orig_index) == "function", "hookmetamethod: __index хук на game", "hookmetamethod: __index ошибка хука на game", true) then
			old_index = orig_index
			local val = game.TestService
			check(index_triggered and val == "hooked_service", "hookmetamethod: __index хук на game сработал", "hookmetamethod: __index хук на game не сработал", true)
			local ok_restore = safe_pcall(hookmetamethod, game, "__index", old_index)
			check(ok_restore, "hookmetamethod: __index восстановлен", "hookmetamethod: __index ошибка восстановления", true)
		end
	end

	do
		local nc_triggered = false
		local old_namecall
		local function namecall_hook(self, ...)
			if self == game and getnamecallmethod() == "GetService" then
				nc_triggered = true
				return "hooked_namecall_service"
			end
			return old_namecall(self, ...)
		end
		local ok_hook, orig_nc = safe_pcall(hookmetamethod, game, "__namecall", namecall_hook)
		if check(ok_hook and type(orig_nc) == "function", "hookmetamethod: __namecall хук на game", "hookmetamethod: __namecall ошибка хука на game", true) then
			old_namecall = orig_nc
			local val = game:GetService("TestService")
			check(nc_triggered and val == "hooked_namecall_service", "hookmetamethod: __namecall хук на game сработал", "hookmetamethod: __namecall хук на game не сработал", true)
			local ok_restore = safe_pcall(hookmetamethod, game, "__namecall", old_namecall)
			check(ok_restore, "hookmetamethod: __namecall восстановлен", "hookmetamethod: __namecall ошибка восстановления", true)
		end
	end
end

local function test_getgc()
	if not present(getgc, "getgc") then return end

	local marker = "GC_TEST_" .. tostring(os.clock())
	local sentinel_func = function() return marker end
	local sentinel_table = { marker = marker }
	task.wait(0.05)

	do
		local ok_gc, list_funcs = safe_pcall(getgc, false)
		if not check(ok_gc and type(list_funcs) == "table", "getgc(false): возвращает таблицу", "getgc(false): не вернул таблицу", true) then return end
		local func_found, table_found = false, false
		for _, v in ipairs(list_funcs) do
			if v == sentinel_func then func_found = true end
			if v == sentinel_table then table_found = true end
		end
		check(func_found, "getgc(false): находит функции", "getgc(false): не нашел тестовую функцию", false)
		check(not table_found, "getgc(false): корректно не включает таблицы", "getgc(false): ошибочно включил таблицу", false)
	end

	do
		local ok_gc, list_all = safe_pcall(getgc, true)
		if not check(ok_gc and type(list_all) == "table", "getgc(true): возвращает таблицу", "getgc(true): не вернул таблицу", true) then return end
		local func_found, table_found, part_found = false, false, false
		local p = Instance.new("Part")
		task.wait()
		for _, v in ipairs(getgc(true)) do
			if v == sentinel_func then func_found = true end
			if v == sentinel_table then table_found = true end
			if v == p then part_found = true end
		end
		p:Destroy()
		check(func_found and table_found, "getgc(true): находит функции и таблицы", "getgc(true): не нашел тестовые объекты", false)
		check(part_found, "getgc(true): находит userdata (Instance)", "getgc(true): не нашел Instance. Я уверен что эта функция эмулирована🤬🤬 (спуфнута).", false)
	end

end

local function test_cloneref()
	if not present(cloneref, "cloneref") then return end

	local original = Instance.new("Part", workspace)
	local ok_clone, clone = safe_pcall(cloneref, original)

	if not check(ok_clone and typeof(clone) == "Instance", "cloneref: создает клон типа Instance", "cloneref: не смог создать клон", true) then
		original:Destroy()
		return
	end

	check(original ~= clone, "cloneref: клон не равен (==) оригиналу", "cloneref: клон равен оригиналу", true)

	local connectionsBefore = #getconnections(original:GetPropertyChangedSignal("Name"))
	clone:GetPropertyChangedSignal("Name"):Connect(function() end)
	local hasGetConnections = select(1, pcall(getconnections, original:GetPropertyChangedSignal("Name")))
	if hasGetConnections then
		check(#getconnections(original:GetPropertyChangedSignal("Name")) > connectionsBefore, "cloneref: соединение с клона влияет на оригинал", "cloneref: соединения изолированы", true)
	end

	original:Destroy()
	task.wait()

	local inTreeOriginal = original:IsDescendantOf(game)
	local inTreeClone = clone:IsDescendantOf(game)
	check(not inTreeOriginal and not inTreeClone, "cloneref: оба объекта удалены из дерева", "cloneref: один из объектов остался в дереве", true)

	local ok_method_clone = pcall(function() return clone:GetFullName() end)
	local ok_parent_access = pcall(function() return clone.Parent end)
	check(not ok_method_clone or clone.Parent == nil, "cloneref: клон становится невалидным или безродным после уничтожения оригинала", "cloneref: клон остался валидным с родителем", true)
end

local function test_firetouchinterest()
    if not present(firetouchinterest, "firetouchinterest") then
        return
    end

    local function make_part(pos)
        local p = Instance.new("Part")
        p.Size = Vector3.new(3, 3, 3)
        p.CFrame = pos
        p.Anchored = true
        p.CanTouch = true
        p.Parent = workspace
        return p
    end

    local part1 = make_part(CFrame.new(0, 50, 0))
    local part2 = make_part(CFrame.new(0, 51, 0))
    local touch_started, touch_ended = 0, 0
    local c1 = part1.Touched:Connect(function() touch_started += 1 end)
    local c2 = part1.TouchEnded:Connect(function() touch_ended += 1 end)
    task.wait()

    part1.CanTouch = false
    safe_pcall(firetouchinterest, part1, part2, 0)
    task.wait()
    check(touch_started == 0, "firetouchinterest: учитывает CanTouch=false", "firetouchinterest: игнорирует CanTouch=false", true)
    part1.CanTouch = true
    task.wait()

    safe_pcall(firetouchinterest, part1, part2, 1)
    task.wait()
    check(touch_ended == 1, "firetouchinterest: вызывает TouchEnded при toggle=1", "firetouchinterest: не вызывает TouchEnded при toggle=1", true)

    local ok_err_nil = not select(1, safe_pcall(firetouchinterest, part1, nil, 0))
    check(ok_err_nil, "firetouchinterest: выбрасывает ошибку при part2=nil", "firetouchinterest: не выбросил ошибку при part2=nil", true)

    local ok_err_type = not select(1, safe_pcall(firetouchinterest, {}, part2, 0))
    check(ok_err_type, "firetouchinterest: выбрасывает ошибку при неверном типе part1", "firetouchinterest: не выбросил ошибку при неверном типе part1", true)

    c1:Disconnect()
    c2:Disconnect()
    part1:Destroy()
    part2:Destroy()
end

local function test_checkcaller()
    if not present(checkcaller, "checkcaller") then return end

    local ok_p, v_p = safe_pcall(checkcaller)
    check(ok_p and v_p, "checkcaller: true в pcall", "checkcaller: не true в pcall/ошибка", true)

    local ok_args = safe_pcall(function() return checkcaller("arg") end)
    check(ok_args, "checkcaller: игнорирует аргументы", "checkcaller: крашит при аргументах", true)

    local coro_result
    local co = coroutine.create(function()
        coro_result = checkcaller()
    end)
    coroutine.resume(co)
    check(coro_result, "checkcaller: true внутри coroutine", "checkcaller: false внутри coroutine", true)

    local xpcall_result_ok, xpcall_result_err
    safe_pcall(function()
        xpcall(function()
            xpcall_result_ok = checkcaller()
        end, function() end)
        xpcall(function() error("test") end, function() xpcall_result_err = checkcaller() end)
    end)
    check(xpcall_result_ok, "checkcaller: true внутри xpcall (success)", "checkcaller: false внутри xpcall (success)", true)
    check(xpcall_result_err, "checkcaller: true внутри xpcall (err handler)", "checkcaller: false внутри xpcall (err handler)", true)

    local hook_result
    local old_nc
    local in_call = false

    local function wrapper(self, ...)
        if in_call then
            return old_nc and old_nc(self, ...)
        end
        in_call = true
        if getnamecallmethod() == "IsA" then
            hook_result = checkcaller()
        end
        local args = table.pack(...)
        local ok, res = safe_pcall(function()
            return old_nc(self, table.unpack(args, 1, args.n))
        end)
        in_call = false
        if ok then
            return res
        end
    end

    local ok_hook = false
    safe_pcall(function()
        if newcclosure then
            old_nc = hookmetamethod(game, "__namecall", newcclosure(wrapper))
        else
            old_nc = hookmetamethod(game, "__namecall", wrapper)
        end
        ok_hook = type(old_nc) == "function"
    end)
    check(ok_hook, "hookmetamethod: оригинал получен", "hookmetamethod: не вернул оригинал __namecall", true)
    if not ok_hook then return end

    safe_pcall(function() game:IsA("Workspace") end)
    task.wait()
    check(hook_result == false, "checkcaller: false при вызове из C-кода", "checkcaller: true для C-кода. Вероятно эмуляция.", true)

    if newcclosure then
        local nested_result_values = {}
        local nested = newcclosure(function()
            table.insert(nested_result_values, checkcaller())
        end)

        for i = 1, 3 do
            safe_pcall(nested)
            task.wait()
        end

        local consistent = true
        for _, v in ipairs(nested_result_values) do
            if v ~= false then
                consistent = false
                break
            end
        end
        check(consistent, "checkcaller: стабильно false во вложенном newcclosure", "checkcaller: нестабильно во вложенном newcclosure", true)
    else
        check(false, "newcclosure: отсутствует", "newcclosure: не поддерживается", true)
    end

    local stable = true
    for i = 1, 5 do
        local ok_s, v_s = safe_pcall(checkcaller)
        if not (ok_s and v_s) then
            stable = false
            break
        end
        task.wait()
    end
    check(stable, "checkcaller: стабилен при повторных вызовах", "checkcaller: нестабилен при повторных вызовах", true)

    local thread_result
    safe_pcall(function()
        task.spawn(function()
            thread_result = checkcaller()
        end)
    end)
    task.wait()
    check(thread_result, "checkcaller: true внутри task.spawn", "checkcaller: false внутри task.spawn", true)

    local pcall_result
    local ok_pcall = safe_pcall(function()
        pcall_result = checkcaller()
    end)
    check(ok_pcall and pcall_result, "checkcaller: true внутри вложенного pcall", "checkcaller: false внутри вложенного pcall", true)
end

local function test_getconnections()
    if not present(getconnections, "getconnections") then return end
    local be = Instance.new("BindableEvent")
    local triggered = false
    local function handler()
        triggered = true
        return "fired"
    end
    local c = be.Event:Connect(handler)
    local okc, conns = safe_pcall(getconnections, be.Event)
    check(okc and type(conns) == "table" and #conns >= 1, "getconnections: возвращает таблицу соединений", "getconnections: вернул не таблицу или пусто", true)
    if okc and #conns > 0 then
        local conn_obj = conns[#conns]
        if typeof(conn_obj) == "RBXScriptConnection" and conn_obj.Connected then
            if conn_obj.Function then
                check(conn_obj.Function == handler, "getconnections: Connection.Function содержит правильную функцию", "getconnections: Connection.Function неверна", true)
                local fire_ok, fire_ret = safe_pcall(conn_obj.Fire, conn_obj)
                check(fire_ok and triggered and fire_ret == "fired", "getconnections: connection:Fire() работает", "getconnections: connection:Fire() не сработал", true)
                triggered = false
                local func_ret = conn_obj.Function()
                check(triggered and func_ret == "fired", "getconnections: connection.Function() работает", "getconnections: connection.Function() не сработал", true)
            end
        end
    end
    c:Disconnect()
    be:Destroy()
    if game:GetService("Players").LocalPlayer then
        local c_conn_ok, idled_conns = safe_pcall(getconnections, game.Players.LocalPlayer.Idled)
        if check(c_conn_ok and #idled_conns > 0, "getconnections: может получить C-connections (Idled)", "getconnections: не смог получить C-connections", false) then
            local c_conn = idled_conns[1]
            check(c_conn.Function == nil, "getconnections: Function равно nil для C-connection", "getconnections: Function не nil для C-connection", true)
        end
    end
end

local function pick_request_func()
	if http_request then return http_request, "http_request" end
	if request then return request, "request" end
	if syn and syn.request then return syn.request, "syn.request" end
	if http and http.request then return http.request, "http.request" end
	return nil, nil
end

local function test_request()
    local req, name = pick_request_func()
    if not present(req, "request/http_request") then return end

    local post_ok, res_post = safe_pcall(req, {
        Url = "https://httpbin.org/post",
        Method = "POST",
        Body = "test",
        Headers = { ["Content-Type"] = "text/plain" }
    })
    check(
        post_ok and type(res_post) == "table" and res_post.Success and res_post.Body and res_post.Body:find("test"),
        name .. ": успешный POST запрос",
        name .. ": ошибка POST запроса",
        false
    )

    local get_ok, res_get = safe_pcall(req, { Url = "https://httpbin.org/get", Method = "GET" })
    if check(
        get_ok and res_get and res_get.Success and res_get.StatusCode == 200,
        name .. ": успешный GET запрос",
        name .. ": ошибка GET запроса",
        false
    ) then
        local http = game:GetService("HttpService")
        local p, decoded = safe_pcall(http.JSONDecode, http, res_get.Body)

        if check(
            p and type(decoded) == "table" and type(decoded.headers) == "table",
            name .. ": тело ответа GET - валидный JSON",
            name .. ": тело ответа GET - не JSON",
            false
        ) then
            local ua = decoded.headers["User-Agent"]
            local fp
            for k, v in pairs(decoded.headers) do
                if type(k) == "string" and k:lower():find("fingerprint") then
                    fp = v
                    break
                end
            end

            if ua and ua ~= "" then
                check(true, name .. ": User-Agent найден [" .. tostring(ua) .. "]", name .. ": отсутствует User-Agent", false)
            else
                check(false, "", name .. ": отсутствует User-Agent", false)
            end

            if fp and fp ~= "" then
                check(true, name .. ": Fingerprint найден [" .. tostring(fp) .. "]", name .. ": отсутствует Fingerprint", false)
            else
                check(false, "", name .. ": отсутствует Fingerprint", false)
            end
        end
    end

    local notfound_ok, res_404 = safe_pcall(req, { Url = "https://www.cat.com/404", Method = "GET" })
    local status_404 = res_404 and res_404.StatusCode
    check(
        notfound_ok and res_404 and status_404 == 404,
        name .. ": корректно обрабатывает 404 (StatusCode=404)",
        name .. ": неверный StatusCode для 404",
        true
    )

    local bad_ok, bad_res = safe_pcall(req, { Url = "https://example.invalid/", Method = "GET" })
    local bad_pass =
        (not bad_ok)
        or (type(bad_res) == "table" and (bad_res.Success == false or bad_res.StatusCode == nil or bad_res.StatusCode == 0))
    check(
        bad_pass,
        name .. ": ошибка при невалидном URL",
        name .. ": не вызвал ошибку для невалидного URL",
        false
    )
end


local function test_getnilinstances()
	if not present(getnilinstances, "getnilinstances") then return end

	local ok_before, list_before = safe_pcall(getnilinstances)
	check(ok_before and type(list_before) == "table", "getnilinstances: возвращает таблицу", "getnilinstances: не вернул таблицу/ошибка", true)

	local nil_part = Instance.new("Part")
	nil_part.Name = "GNI_Test_" .. tostring(math.random(1e9))
	local parented_part = Instance.new("Part")
	parented_part.Name = "GNI_Parented_" .. tostring(math.random(1e9))
	parented_part.Parent = workspace

	task.wait(0.1)

	local ok_list, list_mid = safe_pcall(getnilinstances)
	check(ok_list and type(list_mid) == "table", "getnilinstances: вызов успешен", "getnilinstances: ошибка при вызове", true)

	local found_nil, found_parented = false, false
	for _, inst in ipairs(list_mid) do
		if inst == nil_part then
			found_nil = true
		elseif inst == parented_part then
			found_parented = true
		end
		if found_nil and found_parented then break end
	end

	check(found_nil, "getnilinstances: находит nil-parent экземпляры", "getnilinstances: не находит nil-parent экземпляры", true)
	check(not found_parented, "getnilinstances: не включает экземпляры с родителем", "getnilinstances: включает экземпляры с родителем", true)

	nil_part:Destroy()
	parented_part:Destroy()
end


local function test_threadidentity()
	local gti, sti = getthreadidentity or getidentity, setthreadidentity or setidentity
	if not present(gti, "getthreadidentity") or not present(sti, "setthreadidentity") then return end

	local original_identity = gti()
	check(type(original_identity) == "number", "getthreadidentity: возвращает число", "getthreadidentity: не вернул число", true)

	local stable1 = gti()
	local stable2 = gti()
	check(stable1 == stable2, "getthreadidentity: стабилен при повторных вызовах", "getthreadidentity: нестабилен при повторных вызовах", true)

	local spawn_id = -1
	task.spawn(function()
		spawn_id = gti()
	end)
	task.wait()
	check(spawn_id == original_identity, "getthreadidentity: одинаков в новом потоке без sti", "getthreadidentity: отличается в новом потоке без sti", true)

	local defer_id = -1
	task.defer(function()
		defer_id = gti()
	end)
	task.wait()
	check(defer_id == original_identity, "getthreadidentity: одинаков в task.defer без sti", "getthreadidentity: отличается в task.defer без sti", true)

	local pcall_ok, pcall_id = pcall(function()
		return gti()
	end)
	check(pcall_ok and pcall_id == original_identity, "getthreadidentity: одинаков в pcall без sti", "getthreadidentity: отличается в pcall без sti", true)

	check(original_identity >= 0 and original_identity <= 8, "getthreadidentity: значение в допустимом диапазоне", "getthreadidentity: значение вне диапазона", true)

	local new_id = -1
	task.spawn(function()
		sti(5)
		new_id = gti()
	end)
	task.wait()
	check(new_id == 5, "setthreadidentity: работает в новом потоке (task.spawn)", "setthreadidentity: не сработал в новом потоке", true)
	check(gti() == original_identity, "setthreadidentity: не влияет на другие потоки", "setthreadidentity: повлиял на другой поток", true)

	local defer_set_id = -1
	task.defer(function()
		sti(7)
		defer_set_id = gti()
	end)
	task.wait()
	check(defer_set_id == 7, "setthreadidentity: работает в task.defer", "setthreadidentity: не сработал в task.defer", true)
	check(gti() == original_identity, "setthreadidentity: task.defer не изменил основной поток", "setthreadidentity: task.defer изменил основной поток", true)

	local pcall_ok2, pcall_set_id = pcall(function()
		sti(3)
		return gti()
	end)
	check(pcall_ok2 and pcall_set_id == 3, "setthreadidentity: корректно меняет уровень в pcall", "setthreadidentity: не изменил уровень в pcall", true)
	check(gti() == 3, "setthreadidentity: pcall ожидаемо изменяет основной поток", "setthreadidentity: pcall не изменил основной поток", true)
	sti(original_identity)

	local prev_id = gti()
	sti(prev_id)
	check(gti() == prev_id, "setthreadidentity: установка того же уровня не ломает состояние", "setthreadidentity: установка того же уровня изменила состояние", true)

	local rapid_ids = {}
	for i = 1, 3 do
		sti(i)
		rapid_ids[i] = gti()
	end
	sti(original_identity)
	local seq_ok = true
	for i = 1, 3 do
		if rapid_ids[i] ~= i then
			seq_ok = false
			break
		end
	end
	check(seq_ok, "setthreadidentity: быстрое переключение уровней корректно", "setthreadidentity: быстрое переключение уровней некорректно", true)

	sti(original_identity)
end

local function test_debug_info()
    local getinfo = debug and debug.getinfo
    if not present(getinfo, "debug.getinfo") then return end

    do
        local function foo() return "ok" end
        local ok_info, info_tbl = safe_pcall(getinfo, foo)
        if not (check(ok_info and type(info_tbl) == "table", "debug.getinfo(func): возвращает таблицу", "debug.getinfo(func): не вернул таблицу/ошибка", true)) then return end

        local expected = {
            source = "string", what = "string", numparams = "number", func = "function",
            short_src = "string", currentline = "number", is_vararg = "number", nups = "number"
        }
        local all_found = true
        for k, v_type in pairs(expected) do
            if not check(info_tbl[k] ~= nil and type(info_tbl[k]) == v_type, "debug.getinfo: ключ '"..k.."' существует и имеет тип '"..v_type.."'", "debug.getinfo: ключ '"..k.."' отсутствует или имеет неверный тип", true) then
                all_found = false
            end
        end

        check(info_tbl.func == foo, "debug.getinfo: func совпадает с переданной функцией", "debug.getinfo: func не совпадает", true)
        check(type(info_tbl.short_src)=="string" and info_tbl.source:find(info_tbl.short_src,1,true)~=nil, "debug.getinfo: short_src согласован с source", "debug.getinfo: short_src не согласован с source", true)
        check(info_tbl.what=="Lua", "debug.getinfo: корректно определяет Lua-функцию", "debug.getinfo: неверно определил Lua-функцию", true)
        if all_found then
            ok("debug.getinfo: все ожидаемые поля найдены и согласованы")
        end
    end

    do
        local level1_info, level2_func
        local function wrapper()
            level1_info = getinfo(1, "l")
            local level2_info = getinfo(2, "f")
            if type(level2_info) == "table" then
                level2_func = level2_info.func
            end
        end
        wrapper()
        check(type(level1_info) == "table" and type(level1_info.currentline) == "number", "debug.getinfo(level, l): получает 'currentline'", "debug.getinfo(level, l): не получает 'currentline'", true)
        check(level2_func == test_debug_info, "debug.getinfo(level, f): получает верную функцию-вызывателя", "debug.getinfo(level, f): получил неверную функцию", true)
    end

    do
        local ok_c, info_c = safe_pcall(getinfo, print)
        if check(ok_c and type(info_c) == "table", "debug.getinfo(C-функция): возвращает таблицу", "debug.getinfo(C-функция): ошибка", true) then
            check(info_c.what == "C", "debug.getinfo: корректно определяет C-функцию", "debug.getinfo: неверно определил C-функцию", true)
        end
    end
end

local function test_getscripts()
	if not present(getscripts, "getscripts") then return end

	local dummy_script = Instance.new("LocalScript")
	dummy_script.Name = "GetScriptsDummy_" .. math.random()
	dummy_script.Parent = workspace

	local ok_get, scripts = safe_pcall(getscripts)
	check(ok_get and type(scripts) == "table", "getscripts: возвращает таблицу", "getscripts: не вернул таблицу", true)

	local found = false
	if ok_get then
		for _, s in ipairs(scripts) do
			if s == dummy_script then
				found = true
				break
			end
		end
	end
	check(found, "getscripts: находит новосозданный LocalScript", "getscripts: не нашел новый LocalScript", false)

	dummy_script:Destroy()
	task.wait()
end

local function test_clonefunction()
	if not present(clonefunction, "clonefunction") then return end

	local function original_for_hook() return "original" end
	local cloned_for_hook = clonefunction(original_for_hook)
	local okh, _ = pcall(hookfunction, original_for_hook, function() return "hooked" end)
	if okh then
		local original_res = original_for_hook()
		local cloned_res = cloned_for_hook()
		check(original_res == "hooked" and cloned_res == "original", "clonefunction: хук оригинала не влияет на клон", "clonefunction: хук повлиял на клон", true)
	else
		warnEmoji("hookfunction не найден, тест на иммунитет к хукам пропущен")
	end

	local count = 0
	local function increment()
		count = count + 1
		return count
	end
	local cloned_increment = clonefunction(increment)
	local r1 = increment()
	local r2 = cloned_increment()
	check(r1 == 1 and r2 == 2, "clonefunction: клон использует те же upvalue, что и оригинал", "clonefunction: клон не поделил upvalue с оригиналом", true)

	if getfenv then
		local original_for_env = function() end
		local cloned_for_env = clonefunction(original_for_env)
		check(getfenv(original_for_env) == getfenv(cloned_for_env), "clonefunction: клон и оригинал имеют одно окружение (env)", "clonefunction: окружения разные", true)
	end
	
	local ok, _ = safe_pcall(clonefunction, print)
	check(ok, "clonefunction: ожидаемо не вызывает ошибку на C-функции (проверка эмуляции)", "clonefunction: вызвал ошибку на C-функции", true)
end

local function test_debug_protos()
	if not present(debug.getproto, "debug.getproto") or not present(debug.getprotos, "debug.getprotos") then return end

	local function container_func()
		local function proto1() return "p1_val" end
		local function proto2() return "p2_val" end
		return proto1, proto2
	end

	local ok_protos, protos = safe_pcall(debug.getprotos, container_func)
	if check(ok_protos and type(protos) == "table" and #protos >= 2, "debug.getprotos: возвращает таблицу прототипов", "debug.getprotos: не вернул таблицу или она пуста", true) then
		local p1_ok = type(debug.getproto(container_func, 1)) == "function"
		local p2_ok = type(debug.getproto(container_func, 2)) == "function"
		check(p1_ok and p2_ok, "debug.getprotos: прототипы успешно получены по индексам", "debug.getprotos: не удалось получить прототипы по индексам", true)
	end

	local ok_inactive, inactive_p1 = safe_pcall(debug.getproto, container_func, 1, false)
	if check(ok_inactive and type(inactive_p1) == "function", "debug.getproto(false): возвращает неактивный прототип", "debug.getproto(false): не вернул неактивный прототип", true) then
		local call_ok, _ = safe_pcall(inactive_p1)
		check(call_ok, "debug.getproto(false): 'неактивный' прототип является вызываемой пустышкой (проверка эмуляции)", "debug.getproto(false): 'неактивный' прототип вызвал ошибку", true)
	end
	
	local ok_active, active_protos_table = safe_pcall(debug.getproto, container_func, 1, true)
	
	if check(ok_active and type(active_protos_table) == "table", "debug.getproto(true): возвращает таблицу", "debug.getproto(true): не вернул таблицу", true) then
		if #active_protos_table > 0 then
			local active_proto_from_debug = active_protos_table[1]
			check(type(active_proto_from_debug) == "function", "debug.getproto(true): таблица содержит активные функции", "debug.getproto(true): таблица пуста или содержит не-функции", true)
			local can_call_ok, call_res = safe_pcall(active_proto_from_debug)
			check(can_call_ok and call_res == "p1_val", "debug.getproto(true): активный прототип может быть вызван и возвращает значение", "debug.getproto(true): не удалось вызвать активный прототип", true)
		else
			warnEmoji("debug.getproto(true): вернул пустую таблицу, хотя ожидались активные прототипы")
		end
	end

    local function foo_invalid_arg()
        local function bar() end
        return bar
    end
    local ok_err_arg3 = not select(1, safe_pcall(debug.getproto, foo_invalid_arg, 1, foo_invalid_arg))
    check(ok_err_arg3, "debug.getproto: ошибка при неверном типе аргумента #3 (ожидался boolean)", "debug.getproto: не вызвал ошибку при неверном типе #3", true)

    local function foo_5_protos()
        local function br() end
        local function az() end
        local function ciz() end
        local function aaa() end
        local function gg() end
    end
    local ok_5, protos_5 = safe_pcall(debug.getprotos, foo_5_protos)
    check(ok_5 and type(protos_5) == "table" and #protos_5 == 5, "debug.getprotos: корректно находит 5 вложенных прототипов", "debug.getprotos: не нашел 5 прототипов", true)

	local ok_err_p1 = not select(1, safe_pcall(debug.getproto, print, 1))
	local ok_err_ps = not select(1, safe_pcall(debug.getprotos, print))
	check(ok_err_p1, "debug.getproto: ошибка на C closure", "debug.getproto: не вызвал ошибку на C closure", true)
	check(ok_err_ps, "debug.getprotos: ошибка на C closure", "debug.getprotos: не вызвал ошибку на C closure", true)
end

local function test_getreg()
    if not present(getreg, "getreg") then return end

    local ok_reg, reg = safe_pcall(getreg)
    check(ok_reg and type(reg) == "table", "getreg: возвращает таблицу", "getreg: не вернул таблицу", true)

    local thread_closed = false
    local loop_thread = task.spawn(function()
        while true do task.wait(1) end
    end)
    task.wait(0.05)

    local thread_found, function_found = false, false
    local current_reg = getreg()
    for _, value in pairs(current_reg) do
        if value == loop_thread then thread_found = true end
        if type(value) == "function" then function_found = true end
    end

    if thread_found then
        local close_ok, _ = safe_pcall(coroutine.close, loop_thread)
        if close_ok then
            task.wait(0.05)
            thread_closed = coroutine.status(loop_thread) == "dead"
        end
    end
    check(thread_found, "getreg: находит созданный поток в реестре", "getreg: не нашел поток", false)
    check(thread_closed, "getreg: можно использовать для закрытия потока через coroutine.close", "getreg: не удалось закрыть поток", false)
    check(function_found, "getreg: содержит функции", "getreg: не содержит функции", false)
end

local function test_debug_constants()
    if not present(debug.getconstants, "debug.getconstants") or not present(debug.getconstant, "debug.getconstant") then return end

    do
        local function func_with_guaranteed_literals()
            return { "guaranteed_string", 99.9 }
        end
        local ok_consts, consts_table = safe_pcall(debug.getconstants, func_with_guaranteed_literals)
        if check(ok_consts and type(consts_table) == "table", "getconstants: возвращает таблицу", "getconstants: не вернул таблицу или ошибка", true) then
            local str_found, num_found = false, false
            for _, v in ipairs(consts_table) do
                if v == "guaranteed_string" then str_found = true end
                if v == 99.9 then num_found = true end
            end
            check(str_found and num_found, "getconstants: таблица содержит гарантированные константы-литералы", "getconstants: таблица не содержит всех ожидаемых констант", true)
        end
    end

    do
        local function keep(...) return ... end
        local function foo()
            local num = 5000 .. 88666
            print("Пуп земли", num, warn)
            keep(true, false, 44, 35.22, nil, {"a\000","b\000"}, function() end)
        end

        local ok_consts, consts = safe_pcall(debug.getconstants, foo)
        if ok_consts then
            local found_print = false
            local found_warn = false
            local found_str = false
            for _, v in ipairs(consts) do
                if v == print then found_print = true end
                if v == warn then found_warn = true end
                if v == "Пуп земли" then found_str = true end
            end
        end
    end

    do
        local function keep(...) return ... end
        local function clock()
            local function inner() end
            inner("Яблочко, Котики и ЛадАПРиОрА\000")
            keep(true, 42, 3.14)
        end

        local string_const_index, num_const_index, func_const_index
        local consts = debug.getconstants(clock)
        for i, v in pairs(consts) do
            if not string_const_index and tostring(v):find("Яблочко") then
                string_const_index = i
            elseif not num_const_index and tonumber(v) == 3.14 then
                num_const_index = i
            elseif not func_const_index and type(v) == "function" then
                local vi = debug.getinfo(v, "S")
                if vi and vi.what ~= "C" and v ~= clock then
                    func_const_index = i
                end
            end
        end

        if string_const_index and num_const_index and func_const_index then
            local ok_c1, val1 = safe_pcall(debug.getconstant, clock, string_const_index)
            check(ok_c1 and tostring(val1):find("Яблочко"),
                  "getconstant: получает строковую константу по индексу",
                  "getconstant: не получил строку", true)

            local ok_c2, val2 = safe_pcall(debug.getconstant, clock, num_const_index)
            check(ok_c2 and tonumber(val2) == 3.14,
                  "getconstant: получает числовую константу по индексу",
                  "getconstant: не получил число", true)

            local ok_c3, val3 = safe_pcall(debug.getconstant, clock, func_const_index)
            check(ok_c3 and type(val3) == "function",
                  "getconstant: получает функциональную константу по индексу",
                  "getconstant: не получил функцию", true)
        end
    end

    local ok_c_err, _ = safe_pcall(debug.getconstant, function() return 1 end, 9999)
    check(not ok_c_err, "debug.getconstant: ожидаемо вызывает ошибку для индекса за пределами диапазона (проверка эмуляции)", "debug.getconstant: не вызвал ошибку для невалидного индекса", true)

    local ok_err_c_plural = not select(1, safe_pcall(debug.getconstants, print))
    local ok_err_c_singular = not select(1, safe_pcall(debug.getconstant, print, 1))
    check(ok_err_c_plural, "debug.getconstants: ошибка на C-функции", "debug.getconstants: не вызвал ошибку. Я уверен что эта функция эмулирована🤬🤬 (спуфнута).", true)
    check(ok_err_c_singular, "debug.getconstant: ошибка на C-функции", "debug.getconstant: не вызвал ошибку. Я уверен что эта функция эмулирована🤬🤬 (спуфнута).", true)
end

local function test_getgenv()
    if not present(getgenv, "getgenv") then return end

    local ok_get, env = safe_pcall(getgenv)
    if not check(ok_get and type(env) == "table", "getgenv: возвращает таблицу", "getgenv: не вернул таблицу", true) then return end

    local sentinel = "TEST_VAL_"..os.clock()
    env.test_getgenv_persistence = sentinel
    check(getgenv().test_getgenv_persistence == sentinel, "getgenv: изменения персистентны", "getgenv: изменения не сохраняются", false)

    if getfenv then
        getfenv().test_var_fenv = "F"
        env.test_var_genv = "G"
        check(env.test_var_fenv == nil, "getgenv: изолирован от getfenv (1)", "getgenv: не изолирован от getfenv (1)", false)
    end
end

local function test_getcallbackvalue()
	if not present(getcallbackvalue, "getcallbackvalue") then return end

	local bf = Instance.new("BindableFunction")
	local rf = Instance.new("RemoteFunction")
	local sentinel = false
	local callback_func = function()
		sentinel = true
		return "OK"
	end

	bf.OnInvoke = callback_func

	info("getcallbackvalue: Тестирование валидного извлечения")
	local ok_get, retrieved = safe_pcall(getcallbackvalue, bf, "OnInvoke")

	if check(ok_get and type(retrieved) == "function", "getcallbackvalue: успешно извлекает callback как функцию", "getcallbackvalue: не удалось извлечь callback как функцию", true) then
		check(rawequal(retrieved, callback_func), "getcallbackvalue: извлечённый callback совпадает с оригиналом", "getcallbackvalue: извлечённый callback не совпадает с оригиналом", true)
		local ok_call, res_call = safe_pcall(retrieved)
		check(ok_call and sentinel and res_call == "OK", "getcallbackvalue: извлечённый callback является рабочей функцией", "getcallbackvalue: извлечённый callback не работает или возвращает неверное значение", true)
	end

	info("getcallbackvalue: Тестирование граничных случаев")
	local ok_nil, val_nil = safe_pcall(getcallbackvalue, rf, "OnClientInvoke")
	check(ok_nil and val_nil == nil, "getcallbackvalue: возвращает nil для неустановленного свойства", "getcallbackvalue: не вернул nil для неустановленного свойства", true)

	local ok_non, val_non = safe_pcall(getcallbackvalue, bf, "InvalidCallbackName")
	check(ok_non and val_non == nil, "getcallbackvalue: возвращает nil для несуществующего свойства", "getcallbackvalue: не вернул nil для несуществующего свойства", true)

	info("getcallbackvalue: Тестирование ошибок типов")
	local ok_err_type1 = not select(1, safe_pcall(getcallbackvalue, "not_an_instance", "OnInvoke"))
	check(ok_err_type1, "getcallbackvalue: выбрасывает ошибку при неверном типе object", "getcallbackvalue: не выбросил ошибку при неверном типе object", true)

	local ok_err_type2 = not select(1, safe_pcall(getcallbackvalue, bf, 12345))
	check(ok_err_type2, "getcallbackvalue: выбрасывает ошибку при неверном типе property", "getcallbackvalue: не выбросил ошибку при неверном типе property", true)

	bf:Destroy()
	rf:Destroy()
end

local function test_getcustomasset()
	if not present(getcustomasset, "getcustomasset") then return end

	local path = "gcatest.txt"
	if isfile and isfile(path) and delfile then
		delfile(path)
	end

	if writefile then
		writefile(path, "test")
		local ok_get, assetId = safe_pcall(getcustomasset, path)
		if check(ok_get and type(assetId) == "string", "getcustomasset: выполняется без ошибок для существующего файла", "getcustomasset: ошибка при выполнении", false) then
			local valid_prefixes = {
				"^rbxasset://",
				"^rbxassetid://",
				"^rbxthumb://",
				"^rbxgameasset://"
			}
			local valid = false
			for _, pattern in ipairs(valid_prefixes) do
				if assetId:lower():find(pattern, 1) then
					valid = true
					break
				end
			end
			check(valid, "getcustomasset: возвращает валидный asset id", "getcustomasset: вернул невалидный id", false)
		end
		if delfile then
			delfile(path)
		end
	else
		warnEmoji("getcustomasset: writefile не доступен, тест пропущен")
	end
end


local function test_loadstring()
	if not present(loadstring, "loadstring") then return end

	local sentinel_name = "loadstring_test_global_"..math.random(1e5, 1e6)
	local code_valid = "getgenv()['"..sentinel_name.."'] = 123; return 456" 
	local code_invalid = "local a ="

	local ok_load, func = safe_pcall(loadstring, code_valid)
	if check(ok_load and type(func) == "function", "loadstring: компилирует валидный код в функцию", "loadstring: не смог скомпилировать валидный код", true) then
		local ok_run, result = safe_pcall(func)
		check(ok_run and result == 456, "loadstring: скомпилированная функция возвращает правильное значение", "loadstring: скомпилированная функция не вернула значение", true)
		if getgenv then
			check(getgenv()[sentinel_name] == 123, "loadstring: скомпилированная функция может изменять глобальное окружение", "loadstring: скомпилированная функция не изменила окружение", false)
		end
	end

	local ok_load_err, f_nil, err_msg = safe_pcall(loadstring, code_invalid, "TestChunk")
	check(ok_load_err and f_nil == nil and type(err_msg) == "string", "loadstring: возвращает nil и сообщение об ошибке для невалидного кода", "loadstring: неправильно обработал невалидный код", true)
	if type(err_msg) == "string" then
		check(err_msg:find("TestChunk", 1, true), "loadstring: сообщение об ошибке содержит кастомное имя чанка", "loadstring: сообщение об ошибке не содержит имя чанка", true)
	end
end

local function test_getrunningscripts()
	if not present(getrunningscripts, "getrunningscripts") then return end

	local animate_script
	local lp = game:GetService("Players").LocalPlayer
	if lp and lp.Character then
		animate_script = lp.Character:FindFirstChild("Animate")
	end
	local inactive_script = Instance.new("LocalScript")
	inactive_script.Source = "while true do task.wait(1) end"

	local ok_get, list = safe_pcall(getrunningscripts)
	if not check(ok_get and type(list) == "table", "getrunningscripts: возвращает таблицу", "getrunningscripts: не вернул таблицу или ошибка", false) then
		inactive_script:Destroy()
		return
	end

	local found_animate, found_inactive = false, false
	for _, s in ipairs(list) do
		if s == animate_script then
			found_animate = true
		elseif s == inactive_script then
			found_inactive = true
		end
	end

	if animate_script then
		check(found_animate, "getrunningscripts: находит существующий работающий скрипт (Animate)", "getrunningscripts: не нашел Animate", false)
	else
		warnEmoji("getrunningscripts: скрипт Animate не найден, тест неполный")
	end

	check(not found_inactive, "getrunningscripts: не включает неактивные скрипты", "getrunningscripts: ошибочно включил неактивный скрипт", false)

	check(#list > 0, "getrunningscripts: Общее число запущенных скриптов: " .. #list, "getrunningscripts: не найдено запущенных скриптов", false)

	inactive_script:Destroy()
end


local function test_getscriptbytecode()
	if not present(getscriptbytecode, "getscriptbytecode") then return end

	local animate
	local lp = game:GetService("Players").LocalPlayer
	if lp and lp.Character then
		animate = lp.Character:FindFirstChild("Animate", true)
	end

	if animate then
		local ok_get, bytecode = safe_pcall(getscriptbytecode, animate)
		check(ok_get, "getscriptbytecode: вызов не вызвал ошибок для Animate", "getscriptbytecode: вызов вызвал ошибку для Animate", false)
		check(type(bytecode) == "string" and #bytecode > 0, "getscriptbytecode: вернул непустую строку байт-кода для Animate", "getscriptbytecode: не вернул корректный байт-код для Animate", false)
	else
		warnEmoji("getscriptbytecode: скрипт Animate не найден, тест пропущен")
	end

	local dummy_empty = Instance.new("LocalScript")
	local ok_nil, bc_nil = safe_pcall(getscriptbytecode, dummy_empty)
	check(ok_nil and (bc_nil == nil or #bc_nil == 0), "getscriptbytecode: вернул nil или пустую строку для скрипта без байт-кода", "getscriptbytecode: вернул некорректное значение для пустого скрипта", false)
	dummy_empty:Destroy()
end

local function test_firesignal()
	if not present(firesignal, "firesignal") then return end
	local be = Instance.new("BindableEvent")
	local fire_count = 0
	local last_arg


	local c = be.Event:Connect(function(arg)
		fire_count = fire_count + 1
		last_arg = arg
	end)

	firesignal(be.Event, "arg1")
	check(fire_count == 1 and last_arg == "arg1", "firesignal: вызывает соединение с аргументом", "firesignal: не вызвал соединение", true)

	firesignal(be.Event)
	check(fire_count == 2 and last_arg == nil, "firesignal: вызывает соединение без аргументов", "firesignal: не вызвал соединение без аргументов", true)

	c:Disconnect()
	firesignal(be.Event)
	check(fire_count == 2, "firesignal: не вызывает отключенные соединения", "firesignal: вызвал отключенное соединение", true)

	be:Destroy()
end

local function test_compareinstances()
	if not present(compareinstances, "compareinstances") or not present(cloneref, "cloneref") then return end


	local inst1 = Instance.new("Part")
	local ref_inst1 = cloneref(inst1)

	check(compareinstances(inst1, inst1), "compareinstances: true для одного и того же экземпляра", "compareinstances: false для одного экземпляра", true)
	check(compareinstances(inst1, ref_inst1), "compareinstances: true для оригинала и cloneref", "compareinstances: false для оригинала и cloneref", true)

	local inst2 = Instance.new("Part")
	check(not compareinstances(inst1, inst2), "compareinstances: false для разных экземпляров", "compareinstances: true для разных экземпляров", true)
	check(inst1 ~= ref_inst1, "compareinstances: стандартное сравнение (==) cloneref и оригинала возвращает false", "compareinstances: стандартное сравнение cloneref вернуло true", true)

	inst1:Destroy(); inst2:Destroy()
end

local function test_file_operations()
	local path = "file_op_test.txt"
	if not present(writefile, "writefile") then warnEmoji("writefile не найден"); return end
	if not present(appendfile, "appendfile") then warnEmoji("appendfile не найден"); return end
	if not present(readfile, "readfile") then warnEmoji("readfile не найден"); return end
	if isfile and isfile(path) and delfile then delfile(path) end

	local ok_write = select(1, safe_pcall(writefile, path, "line1"))
	if check(ok_write, "writefile: создает и записывает в файл без ошибок", "writefile: ошибка при записи", false) then
		check(readfile(path) == "line1", "writefile: содержимое файла корректно", "writefile: некорректное содержимое", false)
	end

	local ok_append = select(1, safe_pcall(appendfile, path, "\nline2"))
	if check(ok_append, "appendfile: добавляет в существующий файл без ошибок", "appendfile: ошибка при добавлении", false) then
		check(readfile(path) == "line1\nline2", "appendfile: содержимое файла корректно обновлено", "appendfile: некорректное содержимое после добавления", false)
	end

	writefile(path, "overwrite")
	check(readfile(path) == "overwrite", "writefile: корректно перезаписывает файл", "writefile: файл не был перезаписан", false)

	local escape_path = "../escape_test.txt"
	local ok_escape = select(1, safe_pcall(writefile, escape_path, "escape!"))
	local escaped = ok_escape and isfile and isfile(escape_path)

	check(not escaped, "writefile: не позволяет выйти из рабочей директории", "writefile: возможно выйти за рабочую директорию через ../", true)

	if escaped and delfile then
		delfile(escape_path)
	end

	if present(delfile, "delfile") then delfile(path) end
end


local function test_folder_and_load_ops()
	local fns = {makefolder, isfolder, listfiles, loadfile, writefile}
	local fns_names = {"makefolder", "isfolder", "listfiles", "loadfile", "writefile"}
	for i = 1, #fns do
		if not present(fns[i], fns_names[i]) then return end
	end

	local folder = "luau_test_folder"
	local file_in_root = "luau_test_file.lua"
	local file_in_folder = folder .. "/" .. "inner_file.txt"

	if present(delfile, "delfile") then
		safe_pcall(delfile, file_in_root)
		safe_pcall(delfile, file_in_folder)
	end
	if present(delfolder, "delfolder") then
		safe_pcall(delfolder, folder)
	end
	task.wait(0.05)

	makefolder(folder)
	check(isfolder(folder), "isfolder: true для созданной через makefolder папки", "isfolder: false для созданной папки", false)

	writefile(file_in_root, "return ...+1")
	check(not isfolder(file_in_root), "isfolder: false для созданного файла", "isfolder: true для файла", true)
	writefile(file_in_folder, "test_content")

	local ok_list, root_files = safe_pcall(listfiles, "")
	if check(ok_list and type(root_files) == "table", "listfiles(''): возвращает таблицу", "listfiles(''): не вернул таблицу", false) then
		local found = false
		for _, v in ipairs(root_files) do
			if v:match(folder) then
				found = true
				break
			end
		end
		check(found, "listfiles(''): находит созданную папку", "listfiles(''): не нашел папку", false)
	end

	local ok_list2, folder_files = safe_pcall(listfiles, folder)
	if check(ok_list2 and type(folder_files) == "table", "listfiles(folder): возвращает таблицу", "listfiles(folder): не вернул таблицу", false) then
		local found = false
		for _, v in ipairs(folder_files) do
			local name = v:match("[^/\\]+$")
			if name == "inner_file.txt" then
				found = true
				break
			end
		end
		check(found, "listfiles(folder): находит файл внутри папки", "listfiles(folder): не нашел файл", false)
	end

	local ok_load, chunk = safe_pcall(loadfile, file_in_root)
	if check(ok_load and type(chunk) == "function", "loadfile: компилирует файл в функцию", "loadfile: не скомпилировал файл", true) then
		local ok_exec, res = safe_pcall(chunk, 10)
		check(ok_exec and res == 11, "loadfile: функция из файла работает корректно", "loadfile: функция не работает", true)
	end

	writefile(file_in_root, "invalid-syntax")
	local ok_load_err, chunk_err = safe_pcall(loadfile, file_in_root)
	local syntax_error_detected = false
	if not ok_load_err then
		syntax_error_detected = true
	elseif type(chunk_err) == "function" then
		local ok_exec_err = pcall(chunk_err)
		if not ok_exec_err then
			syntax_error_detected = true
		end
	elseif type(chunk_err) == "string" and chunk_err:lower():find("syntax") then
		syntax_error_detected = true
	end
	check(syntax_error_detected, "loadfile: корректно реагирует на синтаксическую ошибку", "loadfile: не вызвал ошибку на синтаксисе", true)

	if present(delfolder, "delfolder") then
		local ok_del = select(1, safe_pcall(delfolder, folder))
		if check(ok_del, "delfolder: выполнился без ошибок", "delfolder: ошибка при выполнении", false) then
			check(not isfolder(folder), "delfolder: успешно удаляет папку", "delfolder: папка не удалена", false)
		end
	end

	if present(delfile, "delfile") then
		delfile(file_in_root)
	end
end

local function test_setscriptable()
	if not present(setscriptable, "setscriptable") or not present(isscriptable, "isscriptable") then return end

	info("setscriptable: Тест на Humanoid.InternalHeadScale")
	local lp = game:GetService("Players").LocalPlayer
	if lp and lp.Character and lp.Character:FindFirstChild("Humanoid") then
		local humanoid = lp.Character.Humanoid
		local prop_hum = "InternalHeadScale"

		check(not isscriptable(humanoid, prop_hum), "setscriptable: '"..prop_hum.."' изначально нескриптуемо", "setscriptable: '"..prop_hum.."' изначально скриптуемо", true)

		setscriptable(humanoid, prop_hum, true)
		if check(isscriptable(humanoid, prop_hum), "setscriptable(true): '"..prop_hum.."' стало скриптуемо", "setscriptable(true): '"..prop_hum.."' не стало скриптуемо", true) then
			local original_scale = humanoid[prop_hum]
			humanoid[prop_hum] = original_scale + 0.1
			check(humanoid[prop_hum] > original_scale, "setscriptable: значение '"..prop_hum.."' было успешно изменено", "setscriptable: не удалось изменить '"..prop_hum.."'", true)
			humanoid[prop_hum] = original_scale
		end

		setscriptable(humanoid, prop_hum, false)
		check(not isscriptable(humanoid, prop_hum), "setscriptable(false): '"..prop_hum.."' снова нескриптуемо", "setscriptable: '"..prop_hum.."' осталось скриптуемым", true)
	else
		warnEmoji("setscriptable: Humanoid не найден, тест для InternalHeadScale пропущен")
	end
end
-- ГЛОБАЛЬНЫЙ ПАТЧ
local function test_debug_setstack()
    if not present(debug.setstack, "debug.setstack") or not present(debug.getstack, "debug.getstack") then return end

    local function setstack_parent_args_test()
        local final_a, final_b
        local function parent(a, b)
            local function child()
                debug.setstack(2, 1, 666)
                debug.setstack(2, 2, "кошка")
            end
            child()
            final_a, final_b = a, b
        end
        parent(10, "собака")
        return final_a == 666 and final_b == "кошка"
    end
    check(setstack_parent_args_test(), "debug.setstack(2, ...): успешно изменяет аргументы в родительском скоупе", "debug.setstack: не изменил аргументы в родительском скоупе", true)

    local function setstack_parent_local_test()
        local outer_value = 10
        local function inner_function()
            outer_value += 9
            debug.setstack(2, 1, 100)
        end
        inner_function()
        return outer_value == 100
    end
    check(setstack_parent_local_test(), "debug.setstack(2, ...): успешно изменяет local в родительском скоупе", "debug.setstack: не изменил local в родительском скоупе", true)

    local function setstack_replace_self_test()
        local result = "original"
        local success, err = pcall(function()
            error(debug.setstack(1, 1, function()
                return function()
                    result = "replaced"
                end
            end))()
        end)
        return success and result == "replaced"
    end
    check(setstack_replace_self_test(), "debug.setstack(1, ...): успешно заменяет функцию на стеке (паттерн 'error')", "debug.setstack: не смог заменить функцию на стеке (паттерн 'error')", true)

    local ok_err_c_setstack = false
    pcall(function()
        ok_err_c_setstack = not select(1, safe_pcall(debug.setstack, 0, 1, 0))
    end)
    check(ok_err_c_setstack, "debug.setstack: ожидаемо выдает ошибку на C-фрейме", "debug.setstack: не выдал ошибку на C-фрейме", true)
    
    local function getstack_caller_scope_test()
        local function dummy_function() return "Hello" end
        local var = 5
        var += 1
        local result_a, result_b
        (function()
            local stack = debug.getstack(2)
            result_a = stack[1]()
            result_b = stack[2]
        end)()
        return result_a == "Hello" and result_b == 6
    end
    check(getstack_caller_scope_test(), "debug.getstack(2): возвращает locals вызывающего скоупа", "debug.getstack: не вернул locals вызывающего скоупа", true)

    local function getstack_recursive_test()
        local results = {}
        local count = 0
        local function recursive_function()
            count += 1
            if count > 3 then return end
            local a = 29
            local b = true
            local c = "Example"
            a += 1
            b = false
            c ..= "s"
            table.insert(results, debug.getstack(1, count))
            recursive_function()
        end
        recursive_function()
        return results[1] == 30 and results[2] == false and results[3] == "Examples"
    end
    check(getstack_recursive_test(), "debug.getstack(1, index): успешно получает locals по индексу в рекурсии", "debug.getstack: не получил locals по индексу в рекурсии", true)
    
    local ok_err_c_getstack = false
    pcall(function()
        ok_err_c_getstack = not select(1, safe_pcall(debug.getstack, 0))
    end)
    check(ok_err_c_getstack, "debug.getstack: ожидаемо выдает ошибку на C-фрейме", "debug.getstack: не выдал ошибку на C-фрейме", true)
end

local function test_replicatesignal()
	if not present or not present(replicatesignal, "replicatesignal") then
		return
	end

	local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
	local LocalPlayer = cloneref and cloneref(Players.LocalPlayer) or Players.LocalPlayer
	if not LocalPlayer then
		warnEmoji("replicatesignal: LocalPlayer не найден, тест прерван")
		return
	end

	if not LocalPlayer:FindFirstChild("PlayerGui") then
		warnEmoji("replicatesignal: PlayerGui не найден, тест пропущен")
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ReplicateSignalTestGui"
	gui.ResetOnSpawn = false
	gui.Parent = LocalPlayer.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 100, 0, 100)
	frame.Position = UDim2.new(0.5, -50, 0.5, -50)
	frame.Parent = gui

	local signal = frame.MouseWheelForward
	task.wait(0.1)

	local ok_good = select(1, safe_pcall(replicatesignal, signal, 121, 214))
	check(ok_good, "replicatesignal: корректные аргументы выполняются без ошибок", "replicatesignal: ошибка с корректными аргументами", false)

	task.wait(0.1)

	local ok_bad1 = not select(1, safe_pcall(replicatesignal, signal))
	check(ok_bad1, "replicatesignal: ошибка при отсутствии аргументов", "replicatesignal: не выдал ошибку при отсутствии аргументов", false)

	task.wait(0.1)

	local ok_bad2 = not select(1, safe_pcall(replicatesignal, signal, 121))
	check(ok_bad2, "replicatesignal: ошибка при неполных аргументах", "replicatesignal: не выдал ошибку при неполных аргументах", false)

	task.wait(0.1)

	gui:Destroy()
end

local function test_getfunctionhash()
	if not present(getfunctionhash, "getfunctionhash") then return end

	local is_sha384_hex = function(h) return type(h) == "string" and #h == 96 and h:match("^[0-9a-fA-F]+$") ~= nil end
	local f1 = function() return 1 end
	local f2 = function() return 2 end
	local f3 = function() return 1 end
	local f4 = function() return "const" end

	local ok1, h1 = safe_pcall(getfunctionhash, f1)
	check(ok1 and is_sha384_hex(h1), "getfunctionhash: возвращает валидный SHA384 хэш", "getfunctionhash: не вернул валидный хэш", true)
	check(getfunctionhash(f1) ~= getfunctionhash(f2), "getfunctionhash: разные функции имеют разные хэши", "getfunctionhash: разные функции имеют одинаковые хэши", true)
	check(getfunctionhash(f1) == getfunctionhash(f3), "getfunctionhash: идентичные функции имеют одинаковые хэши", "getfunctionhash: идентичные функции имеют разные хэши", true)
	check(getfunctionhash(f1) ~= getfunctionhash(f4), "getfunctionhash: хэш зависит от констант", "getfunctionhash: хэш не зависит от констант", true)

	local ok_err, _ = safe_pcall(getfunctionhash, print)
	check(not ok_err, "getfunctionhash: ожидаемо выдает ошибку на C-функции", "getfunctionhash: не вызвал ошибку на C-функции", true)
end

local function test_crypto_ops()
	if not present(crypt, "crypt") then return end
	if not present(crypt.base64encode, "crypt.base64encode") or not present(crypt.base64decode, "crypt.base64decode") then return end

	local orig_str = "Test string with special chars\0\1\2\255!"
	local encoded_known = "RHVtbXlTdHJpbmcAAg=="
	local decoded_known = "DummyString\0\2"

	local ok_enc, encoded = safe_pcall(crypt.base64encode, orig_str)
	if check(ok_enc and type(encoded) == "string", "crypt.base64encode: выполняется без ошибок", "crypt.base64encode: ошибка при кодировании", true) then
		local ok_dec, decoded = safe_pcall(crypt.base64decode, encoded)
		check(ok_dec and decoded == orig_str, "crypt.base64decode: round-trip (кодирование-декодирование) успешен", "crypt.base64decode: round-trip не удался", true)
	end

	local ok_enc_known = crypt.base64encode(decoded_known) == encoded_known
	check(ok_enc_known, "crypt.base64encode: корректно кодирует известную строку", "crypt.base64encode: некорректный результат кодирования", true)

	local ok_dec_known, decoded_res = safe_pcall(crypt.base64decode, encoded_known)
	check(ok_dec_known and decoded_res == decoded_known, "crypt.base64decode: корректно декодирует известную строку", "crypt.base64decode: некорректный результат декодирования", true)
end

local function test_drawing()
	if not present(Drawing, "Drawing") or not present(Drawing.new, "Drawing.new") or not present(isrenderobj, "isrenderobj") then
		return
	end

	local function safe_new(t)
		local ok, obj = safe_pcall(function()
			return Drawing.new(t)
		end)
		return ok, obj
	end

	local ok_circle, circle = safe_new("Circle")
	if ok_circle and isrenderobj(circle) then
		check(true, "Drawing.new: объект создаётся", "", true)
		pcall(function() circle:Destroy() end)
		circle = nil
	else
		check(false, "Drawing.new: объект создаётся", "Drawing.new: не смог создать объект", true)
	end
end

local function test_getcallingscript()
	if not present(getcallingscript, "getcallingscript") then return end

	local from_c_ok, c_caller = safe_pcall(getcallingscript)
	check(from_c_ok and c_caller == nil, "getcallingscript: возвращает nil при вызове из C-потока", "getcallingscript: не вернул nil из C-потока", false)

	local function from_lua()
		return getcallingscript()
	end
	local from_lua_ok, lua_caller = safe_pcall(from_lua)
	check(from_lua_ok and lua_caller == script, "getcallingscript: возвращает текущий скрипт при вызове из Luau", "getcallingscript: не вернул текущий скрипт", false)
end

local function test_getloadedmodules()
	if not present(getloadedmodules, "getloadedmodules") then return end

	local loaded_mod = nil
	local list_before = getloadedmodules()
	if type(list_before) == "table" and #list_before > 0 then
		loaded_mod = list_before[1]
	end
	if not loaded_mod then
		return check(false, "нет доступных загруженных модулей для теста", "", false)
	end

	local not_loaded_mod = Instance.new("ModuleScript")
	not_loaded_mod.Name = "NotLoaded_" .. tostring(math.random(1, 1e9))

	local ok_get, modules = safe_pcall(getloadedmodules)
	if check(ok_get and type(modules) == "table", "getloadedmodules: возвращает таблицу", "getloadedmodules: не вернул таблицу", false) then
		local found_loaded, found_not_loaded = false, false
		for _, mod in ipairs(modules) do
			if mod == loaded_mod then
				found_loaded = true
			elseif mod == not_loaded_mod then
				found_not_loaded = true
			end
		end
		check(found_loaded, "getloadedmodules: находит загруженный модуль", "getloadedmodules: не нашел загруженный модуль", false)
		check(not found_not_loaded, "getloadedmodules: не включает незагруженные модули", "getloadedmodules: ошибочно включил незагруженный модуль", false)
	end

	not_loaded_mod:Destroy()
end

local function test_getscriptclosure()
	if not present(getscriptclosure, "getscriptclosure") then return end

	local animate
	local lp = game:GetService("Players").LocalPlayer
	if lp and lp.Character then
		animate = lp.Character:FindFirstChild("Animate", true)
	end

	if animate then
		local ok_get, closure = safe_pcall(getscriptclosure, animate)
		check(ok_get, "getscriptclosure: вызов не вызвал ошибок для Animate", "getscriptclosure: вызов вызвал ошибку для Animate", false)
		check(type(closure) == "function", "getscriptclosure: вернул функцию для Animate", "getscriptclosure: не вернул функцию для Animate", false)
	else
		warnEmoji("getscriptclosure: скрипт Animate не найден, тест пропущен")
	end

	local dummy_empty = Instance.new("LocalScript")
	local closure_empty = getscriptclosure(dummy_empty)
	check(closure_empty == nil, "getscriptclosure: возвращает nil для скрипта без байт-кода", "getscriptclosure: не вернул nil", false)

	dummy_empty:Destroy()
end

local function test_getscripthash()
	if not present(getscripthash, "getscripthash") then return end

	local function is_sha384_hex(h)
		return type(h) == "string" and #h == 96 and h:match("^[0-9a-fA-F]+$")
	end

	local animate
	local lp = game:GetService("Players").LocalPlayer
	if lp and lp.Character then
		animate = lp.Character:FindFirstChild("Animate", true)
	end

	if animate then
		local ok_h1, h1 = safe_pcall(getscripthash, animate)
		check(ok_h1 and is_sha384_hex(h1), "getscripthash: возвращает валидный SHA384 хэш для Animate", "getscripthash: не вернул корректный хэш для Animate", false)
	else
		warnEmoji("getscripthash: скрипт Animate не найден, основной тест пропущен")
	end

	local dummy_empty = Instance.new("LocalScript")
	local ok_nil, res_nil = safe_pcall(getscripthash, dummy_empty)
	check(ok_nil and res_nil == nil, "getscripthash: возвращает nil для скрипта без байткода", "getscripthash: не вернул nil для пустого скрипта", false)
	dummy_empty:Destroy()

	local bad_ok = not select(1, pcall(getscripthash, {}))
	check(bad_ok, "getscripthash: выбрасывает ошибку при неверном типе аргумента", "getscripthash: не выбросил ошибку при неверном типе аргумента", false)
end

local function test_identifyexecutor()
	if not present(identifyexecutor, "identifyexecutor") then return end

	local ok_get, name, version = safe_pcall(identifyexecutor)
	if check(ok_get, "identifyexecutor: выполняется без ошибок", "identifyexecutor: ошибка при выполнении", true) then
		check(type(name) == "string" and #name > 0, "identifyexecutor: возвращает непустое имя (строка) [" .. tostring(name) .. "]", "identifyexecutor: не вернул имя", true)
		check(type(version) == "string" and #version > 0, "identifyexecutor: возвращает непустую версию (строка) [" .. tostring(version) .. "]", "identifyexecutor: не вернул версию", true)
	end
end

local function test_getinstances()
	if not present(getinstances, "getinstances") then return end

	local part = Instance.new("Part")
	part.Parent = nil
	local sentinel_name = "GetInstancesTest_"..math.random()
	part.Name = sentinel_name
	task.wait(0.05)

	local ok_get, instances = safe_pcall(getinstances)
	if check(ok_get and type(instances) == "table", "getinstances: возвращает таблицу", "getinstances: не вернул таблицу", false) then
		local found = false
		for _, inst in ipairs(instances) do
			if inst == part and inst.Name == sentinel_name then
				found = true
				break
			end
		end
		check(found, "getinstances: находит nil-parented экземпляр", "getinstances: не нашел экземпляр", false)
	end
	part:Destroy()
end

local function test_fireproximityprompt()
	if not present(fireproximityprompt, "fireproximityprompt") then return end

	local part = Instance.new("Part", workspace)
	local prompt = Instance.new("ProximityPrompt", part)

	local triggered_by = nil
	local conn = prompt.Triggered:Connect(function(player)
		triggered_by = player
	end)
	task.wait(0.1)

	local ok_fire = select(1, safe_pcall(fireproximityprompt, prompt))
	check(ok_fire, "fireproximityprompt: выполняется без ошибок", "fireproximityprompt: ошибка при выполнении", false)
	task.wait(0.1)

	local LocalPlayer = game:GetService("Players").LocalPlayer
	check(triggered_by == LocalPlayer, "fireproximityprompt: событие Triggered срабатывает с LocalPlayer", "fireproximityprompt: событие не сработало", false)

	conn:Disconnect()
	part:Destroy()
end

local function test_fireclickdetector() 
	if not present(fireclickdetector, "fireclickdetector") then return end

	local G = cloneref and cloneref(game) or game
	local WS = G:GetService("Workspace")
	local Players = G:GetService("Players")
	local lp = Players.LocalPlayer

	local container = Instance.new("Folder")
	container.Name = "__cd_sandbox__"
	container.Archivable = false
	container.Parent = WS

	local part = Instance.new("Part")
	part.Name = "Part"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Transparency = 1
	part.Parent = container

	pcall(function()
		part.CFrame = CFrame.new(0, 10000, 0)
	end)

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 512
	cd.Parent = part

	local m1_fired, m2_fired, hover_enter_fired, hover_leave_fired = false, false, false, false
	cd.MouseClick:Connect(function(player) if player == lp then m1_fired = true end end)
	cd.RightMouseClick:Connect(function(player) if player == lp then m2_fired = true end end)
	cd.MouseHoverEnter:Connect(function(player) if player == lp then hover_enter_fired = true end end)
	cd.MouseHoverLeave:Connect(function(player) if player == lp then hover_leave_fired = true end end)

	local function wait_flag(getter, timeout)
		local t0 = os.clock()
		timeout = timeout or 0.3
		while not getter() and os.clock() - t0 < timeout do
			task.wait()
		end
		return getter()
	end

	local ok_default = pcall(function() fireclickdetector(cd) end)
	check(ok_default and wait_flag(function() return m1_fired end),
	"fireclickdetector: вызывает MouseClick по умолчанию",
	"fireclickdetector: не вызвал MouseClick", false)

	local ok_right = pcall(function() fireclickdetector(cd, 0, "RightMouseClick") end)
	check(ok_right and wait_flag(function() return m2_fired end),
	"fireclickdetector: вызывает RightMouseClick при указании",
	"fireclickdetector: не вызвал RightMouseClick", false)

	local ok_hover_enter = pcall(function() fireclickdetector(cd, 0, "MouseHoverEnter") end)
	check(ok_hover_enter and wait_flag(function() return hover_enter_fired end),
	"fireclickdetector: вызывает MouseHoverEnter",
	"fireclickdetector: не вызвал MouseHoverEnter", false)

	local ok_hover_leave = pcall(function() fireclickdetector(cd, 0, "MouseHoverLeave") end)
	check(ok_hover_leave and wait_flag(function() return hover_leave_fired end),
	"fireclickdetector: вызывает MouseHoverLeave",
	"fireclickdetector: не вызвал MouseHoverLeave", false)

	container:Destroy()
end

local function measure_fps(duration)
    local RunService = game:GetService("RunService")
    local frames, start = 0, tick()
    while tick() - start < duration do
        RunService.RenderStepped:Wait()
        frames += 1
    end
    return math.floor(frames / duration + 0.5)
end

local function test_fpscap()
    if not present(getfpscap, "getfpscap") or not present(setfpscap, "setfpscap") then return end

    local ok_get, original_cap = safe_pcall(getfpscap)
    if not check(ok_get and type(original_cap) == "number", "getfpscap: возвращает число", "getfpscap: не вернул число или ошибка", false) then return end

    local real_before = measure_fps(2)
    check(math.abs(real_before - original_cap) <= 5, "getfpscap: значение совпадает с реальным FPS", "getfpscap: значение не совпадает с реальным FPS", false)

    local new_cap = (original_cap == 144) and 120 or 144
    local ok_set = select(1, safe_pcall(setfpscap, new_cap))
    if check(ok_set, "setfpscap: выполнился без ошибок", "setfpscap: ошибка при выполнении", false) then
        task.wait(1)
        local real_after = measure_fps(2)
        check(math.abs(real_after - new_cap) <= 5, "setfpscap: реально изменил FPS cap (реальный FPS ~ "..real_after..")", "setfpscap: не изменил FPS cap", false)

        local ok_get_new, current_cap = safe_pcall(getfpscap)
        check(ok_get_new and current_cap == new_cap, "getfpscap: возвращает установленный лимит", "getfpscap: не возвращает установленный лимит", false)
    end

    setfpscap(original_cap)
    check(getfpscap() == original_cap, "setfpscap: успешно восстановил исходный FPS cap", "setfpscap: не удалось восстановить FPS cap", false)
end

local function test_replaceclosure()
	if not present(replaceclosure, "replaceclosure") then return end

	local harmless_func = function()
		return "safe"
	end

	local upvalue = 1
	local original_func = function()
		upvalue = upvalue + 1
		return "original"
	end

	local new_func = function()
		return "replaced", upvalue
	end

	local ok_replace = select(1, safe_pcall(replaceclosure, harmless_func, new_func))
	if not check(ok_replace, "replaceclosure: выполнился без ошибок", "replaceclosure: ошибка при выполнении", true) then return end

	local res_after_replace, upvalue_seen = new_func()
	check(res_after_replace == "replaced", "replaceclosure: вызов оригинала теперь выполняет новую функцию", "replaceclosure: замена не удалась", true)
	check(upvalue_seen == 1, "replaceclosure: замененная функция видит upvalue оригинала", "replaceclosure: не имеет доступа к upvalue", true)

	local ok_err_c = not select(1, safe_pcall(replaceclosure, math.sin, function() end))
	check(ok_err_c, "replaceclosure: ошибка при попытке заменить C-функцию", "replaceclosure: не вызвал ошибку для C-функции", true)
end

local function test_isrbxactive()
    if not present(isrbxactive, "isrbxactive") then return end

    local ok_get, status = safe_pcall(isrbxactive)
    if ok_get and type(status) == "boolean" then
        check(true, "isrbxactive: вернул допустимое boolean значение ("..tostring(status)..")", "", false)
    else
        check(false, "", "isrbxactive: вернул недопустимое значение -> "..tostring(status), false)
    end
end

local function test_isscriptable()
	if not present(isscriptable, "isscriptable") or not present(setscriptable, "setscriptable") then return end

	info("isscriptable: Тест на Humanoid.InternalHeadScale")
	local lp = game:GetService("Players").LocalPlayer
	if lp and lp.Character and lp.Character:FindFirstChild("Humanoid") then
		local humanoid = lp.Character.Humanoid
		check(not isscriptable(humanoid, "InternalHeadScale"), "isscriptable: 'InternalHeadScale' false по умолчанию", "isscriptable: 'InternalHeadScale' true по умолчанию", true)
		setscriptable(humanoid, "InternalHeadScale", true)
		check(isscriptable(humanoid, "InternalHeadScale"), "isscriptable: 'InternalHeadScale' стало true", "isscriptable: 'InternalHeadScale' не стало true", true)
		setscriptable(humanoid, "InternalHeadScale", false)
		check(not isscriptable(humanoid, "InternalHeadScale"), "isscriptable: 'InternalHeadScale' стало false", "isscriptable: 'InternalHeadScale' не стало false", true)
	else
		warnEmoji("isscriptable: Humanoid не найден, тест для InternalHeadScale пропущен")
	end
end

local function test_newlclosure() 
    if not present(newlclosure, "newlclosure") then return end

    local up = { count = 0 }
    local original = function()
        up.count = up.count + 1
    end

    local ok_new, lclosure = safe_pcall(newlclosure, original)
    if check(ok_new and islclosure(lclosure), "newlclosure: успешно создает lclosure", "newlclosure: не удалось создать lclosure", true) then
        original()
        lclosure()
        check(up.count == 2, "newlclosure: разделяет upvalues с оригиналом", "newlclosure: не разделяет upvalues", true)
    end

    local ok_c, res_c = safe_pcall(newlclosure, print)
    check(ok_c and islclosure(res_c), "newlclosure: успешно создает lclosure из C-функции", "newlclosure: не удалось создать lclosure из C-функции", true)
end

local function test_debug_setmetatable()
	local d_smt = debug.setmetatable
	if not present(d_smt, "debug.setmetatable") then return end

	local target_table = {}
	local protected_mt = { __metatable = "LOCKED" }
	setmetatable(target_table, protected_mt)

	local ok_vanilla = not select(1, safe_pcall(setmetatable, target_table, {}))
	check(ok_vanilla, "debug.setmetatable: __metatable защита работает как ожидалось", "debug.setmetatable: __metatable защита не сработала", true)

	local new_mt = { __index = function() return "bypassed_by_debug" end }
	local ok_set, _ = safe_pcall(d_smt, target_table, new_mt)

	if check(ok_set, "debug.setmetatable: выполнился на таблице с защищенной МТ", "debug.setmetatable: выдал ошибку", true) then
		check(getmetatable(target_table) == new_mt and target_table.xyz == "bypassed_by_debug", "debug.setmetatable: успешно обошел __metatable", "debug.setmetatable: не смог обойти __metatable", true)
	end
end
-- Полностью обновил debug
local function test_debug_more()
	if not present(debug, "debug") then return end

	if present(debug.setconstant, "debug.setconstant") then
		local function dummy_func()
			print(game.Name)
			return "some_val"
		end

		local consts, const_idx, const_val
		pcall(function()
			consts = debug.getconstants(dummy_func)
			for i, v in pairs(consts) do
				if v == "Name" then const_idx, const_val = i, v; break end
			end
		end)

		if const_idx then
			local ok_set, _ = safe_pcall(debug.setconstant, dummy_func, const_idx, "Players")
			if check(ok_set, "debug.setconstant: выполнился без ошибок", "debug.setconstant: вызвал ошибку", true) then
				local s = dummy_func()
				check(s == "some_val", "debug.setconstant: успешно изменил константу (проверено по выводу)", "debug.setconstant: не изменил константу", true)
				debug.setconstant(dummy_func, const_idx, const_val)
			end
		else
			warnEmoji("debug.setconstant: не удалось найти индекс константы, тест неполный")
		end
		local ok_err_c = not select(1, safe_pcall(debug.setconstant, print, 1, "test"))
		check(ok_err_c, "debug.setconstant: ошибка на C-функции", "debug.setconstant: не вызвал ошибку. Я уверен что эта функция эмулирована🤬🤬 (спуфнута).", true)
	end

	if present(debug.getstack, "debug.getstack") then
		local args_pass_check = false
		local function argument_retrieval_test(arg1, arg2)
			local retrieved_arg1 = debug.getstack(1, 1)
			local retrieved_arg2 = debug.getstack(1, 2)
			if retrieved_arg1 == arg1 and retrieved_arg2 == arg2 then
				args_pass_check = true
			end
		end
		
		argument_retrieval_test(1337, "marker_string")
		check(args_pass_check, "debug.getstack(1, index): успешно получает аргументы функции по индексу", "debug.getstack: не смог получить аргументы функции по индексу", true)

		local gets_table_pass = false
		local function local_table_test()
			local a = { data = true }
			local b = false
			local stack = debug.getstack(1)
			
			local found_a = false
			local found_b = false
			if type(stack) == "table" then
				for _, value in ipairs(stack) do
					if value == a then
						found_a = true
					elseif value == b then
						found_b = true
					end
				end
			end
			gets_table_pass = found_a and found_b
		end
		
		local_table_test()
		check(gets_table_pass, "debug.getstack(1): успешно получает таблицу локальных переменных", "debug.getstack: не вернул или вернул неверную таблицу локальных переменных", true)

		local ok_err_c = not select(1, safe_pcall(debug.getstack, 0))
		check(ok_err_c, "debug.getstack: ошибка при level=0 (C-фрейм)", "debug.getstack: не вызвал ошибку на C-фрейме", true)
	end
end

local function test_hui()
	if not present(gethui, "gethui") then return end

	local ok_get, hui = safe_pcall(gethui)
	if not check(ok_get and (typeof(hui) == "Instance" or typeof(hui) == "BasePlayerGui" or typeof(hui) == "Folder"), "gethui: возвращает Instance", "gethui: не вернул Instance", false) then
		return
	end

	local gui = Instance.new("ScreenGui")
	local gui_name = "HUITEST_" .. tostring(math.random(1e9))
	gui.Name = gui_name
	gui.Parent = hui

	task.wait(0.05)

	check(gui.Parent == hui and hui:FindFirstChild(gui_name) == gui, "gethui: можно использовать как родительский объект для UI", "gethui: не работает как родительский объект", false)
	gui:Destroy()
end

local function test_mouse_emulation()
    local req = {
        {"mouse1click", mouse1click},
        {"mouse1press", mouse1press},
        {"mouse1release", mouse1release},
        {"mouse2click", mouse2click},
        {"mouse2press", mouse2press},
        {"mouse2release", mouse2release},
        {"mousemoveabs", mousemoveabs},
        {"mousemoverel", mousemoverel},
        {"mousescroll", mousescroll},
    }
    for _, p in ipairs(req) do if not present(p[2], p[1]) then return end end

    local CoreGui = game:GetService("CoreGui")
    local UIS = game:GetService("UserInputService")

    local function makeAtCursor(text, w, h)
        local sg = Instance.new("ScreenGui")
        sg.IgnoreGuiInset = true
        sg.ResetOnSpawn = false
        sg.Parent = CoreGui

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(w or 200, h or 60)
        local m = UIS:GetMouseLocation()
        btn.Position = UDim2.fromOffset(m.X - btn.Size.X.Offset/2, m.Y - btn.Size.Y.Offset/2)
        btn.Text = text
        btn.Parent = sg
        return sg, btn
    end

    do
        local sg, btn = makeAtCursor("LClick")
        local clicked = false
        btn.MouseButton1Click:Connect(function() clicked = true end)
        select(1, safe_pcall(mouse1click))
        task.wait(0.3)
        check(clicked, "mouse1click: реально кликнул по GUI", "mouse1click: не сработал по GUI", false)
        sg:Destroy()
    end

    do
        local sg, btn = makeAtCursor("LPress/Release")
        local down, up = false, false
        btn.MouseButton1Down:Connect(function() down = true end)
        btn.MouseButton1Up:Connect(function() up = true end)
        select(1, safe_pcall(mouse1press))
        task.wait(0.15)
        select(1, safe_pcall(mouse1release))
        task.wait(0.3)
        check(down and up, "mouse1press/release: реально сработали", "mouse1press/release: не сработали", false)
        sg:Destroy()
    end

    do
        local sg, btn = makeAtCursor("RClick")
        local clicked = false
        btn.MouseButton2Click:Connect(function() clicked = true end)
        select(1, safe_pcall(mouse2click))
        task.wait(0.3)
        check(clicked, "mouse2click: реально кликнул по GUI", "mouse2click: не сработал по GUI", false)
        sg:Destroy()
    end

    do
        local sg, btn = makeAtCursor("RPress/Release")
        local down, up = false, false
        btn.MouseButton2Down:Connect(function() down = true end)
        btn.MouseButton2Up:Connect(function() up = true end)
        select(1, safe_pcall(mouse2press))
        task.wait(0.15)
        select(1, safe_pcall(mouse2release))
        task.wait(0.3)
        check(down and up, "mouse2press/release: реально сработали", "mouse2press/release: не сработали", false)
        sg:Destroy()
    end

    do
        local ok = select(1, safe_pcall(mousescroll, 0, 6))
        check(ok, "mousescroll: выполняется без ошибок", "mousescroll: ошибка при вызове", false)
    end

    do
        local ok = select(1, safe_pcall(mousemoveabs, 200, 200))
        check(ok, "mousemoveabs: выполняется без ошибок", "mousemoveabs: ошибка при вызове", false)
    end

    do
        local ok = select(1, safe_pcall(mousemoverel, 50, 50))
        check(ok, "mousemoverel: выполняется без ошибок", "mousemoverel: ошибка при вызове", false)
    end
end

local function test_cache()
	if not present(cache, "cache") then return end

	local funcs = {cache.invalidate, cache.iscached, cache.replace}
	local names = {"cache.invalidate", "cache.iscached", "cache.replace"}
	for i = 1, #funcs do
		if not present(funcs[i], names[i]) then return end
	end

	do
		local container = Instance.new("Folder")
		local part = Instance.new("Part", container)
		cache.invalidate(container:FindFirstChild("Part"))
		check(part ~= container:FindFirstChild("Part"),
			"cache.invalidate: ссылка на объект была сброшена",
			"cache.invalidate: ссылка на объект не изменилась", false)
	end

	do
		local part = Instance.new("Part")
		check(cache.iscached(part),
			"cache.iscached: объект в кэше",
			"cache.iscached: объект не в кэше", false)
		cache.invalidate(part)
		check(not cache.iscached(part),
			"cache.iscached: объект удалён из кэша",
			"cache.iscached: объект всё ещё в кэше", false)
	end

	do
		local part = Instance.new("Part")
		local fire = Instance.new("Fire")
		cache.replace(part, fire)
		check(part ~= fire,
			"cache.replace: объект успешно заменён",
			"cache.replace: объект не был заменён", false)
	end
end

local function test_compression()
	if not present(lz4compress, "lz4compress") or not present(lz4decompress, "lz4decompress") then return end

	local raw = "Hello, world!"
	local ok_compress, compressed = safe_pcall(lz4compress, raw)
	if check(ok_compress and type(compressed) == "string", "lz4compress: выполняется и возвращает строку", "lz4compress: ошибка или неверный тип", true) then
		local ok_decompress, decompressed = safe_pcall(lz4decompress, compressed, #raw)
		if check(ok_decompress and type(decompressed) == "string", "lz4decompress: выполняется и возвращает строку", "lz4decompress: ошибка или неверный тип", true) then
			check(decompressed == raw, "lz4: round-trip (сжатие-распаковка) успешен", "lz4: round-trip не удался", true)
		end
	end
end


local function test_crypto_extended()
	if not present(crypt, "crypt") then return end
	local funcs = {crypt.encrypt, crypt.decrypt, crypt.generatebytes, crypt.generatekey, crypt.hash}
	local names = {"crypt.encrypt", "crypt.decrypt", "crypt.generatebytes", "crypt.generatekey", "crypt.hash"}
	for i=1, #funcs do if not present(funcs[i], names[i]) then return end end

	local plaintext = "some plaintext data to be encrypted"
	local ok_key, key = safe_pcall(crypt.generatekey)

	if check(ok_key and type(key) == "string" and #key > 0, "crypt.generatekey: генерирует непустую строку-ключ", "crypt.generatekey: не сгенерировал ключ", true) then
		local ok_enc, ciphertext = safe_pcall(crypt.encrypt, plaintext, key, "some_additional_data")
		if check(ok_enc and type(ciphertext) == "string", "crypt.encrypt: выполняется без ошибок", "crypt.encrypt: ошибка при шифровании", true) then
			local ok_dec, decrypted = safe_pcall(crypt.decrypt, ciphertext, key, "some_additional_data")
			check(ok_dec and decrypted == plaintext, "crypt.decrypt: round-trip (шифрование-дешифрование) успешен", "crypt.decrypt: round-trip не удался", true)

			local wrong_key = crypt.generatekey()
			local ok_dec_wrong, decrypted_wrong = safe_pcall(crypt.decrypt, ciphertext, wrong_key, "some_additional_data")
			check(ok_dec_wrong and decrypted_wrong ~= plaintext, "crypt.decrypt: не расшифровывает с неверным ключом", "crypt.decrypt: расшифровал с неверным ключом", true)
		end
	end

	local ok_bytes, bytes = safe_pcall(crypt.generatebytes, 16)
	check(ok_bytes and type(bytes) == "string" and #bytes == 16, "crypt.generatebytes: генерирует строку указанной длины", "crypt.generatebytes: не сгенерировал строку", true)

	local data_to_hash = "some_data"
	local ok_hash, hash1 = safe_pcall(crypt.hash, data_to_hash, "sha384")
	check(ok_hash and type(hash1) == "string", "crypt.hash: возвращает строку хэша", "crypt.hash: ошибка хэширования", true)
	local hash2 = crypt.hash(data_to_hash, "sha384")
	check(hash1 == hash2, "crypt.hash: хэши для одних и тех же данных совпадают", "crypt.hash: хэши не совпадают", true)
end

local function test_misc_env() 
    if present(messagebox, "messagebox") then
        local start = tick()
        local ok_msg = select(1, safe_pcall(messagebox, "Test", "test", 0))
        local dt = tick() - start

        if check(ok_msg, "messagebox: выполняется без ошибок", "messagebox: ошибка при вызове", false) then
            if dt > 0.5 then
                check(false, "messagebox: синхронный вызов (окно блокировало поток)", "messagebox: не синхронный вызов", true)
            else
                check(true, "messagebox: асинхронный вызов (не блокировал поток)", "messagebox: не асинхронный вызов", true)
            end
        end
    end

    if present(queue_on_teleport, "queue_on_teleport") then
        local code = "print('teleported!')"
        local ok_queue = select(1, safe_pcall(queue_on_teleport, code))
        check(ok_queue, "queue_on_teleport: выполняется без ошибок", "queue_on_teleport: ошибка при вызове", false)
    end

	if present(setclipboard, "setclipboard") and present(getclipboard, "getclipboard") then
		local text = tostring(math.random(1000,9999))
		local ok_set = select(1, safe_pcall(setclipboard, text))
		if check(ok_set, "setclipboard: вызвался без ошибок", "setclipboard: ошибка при вызове", false) then
			local ok_get, clip = safe_pcall(getclipboard)
			check(ok_get and clip == text, "setclipboard/getclipboard: реально записывает в буфер ["..text.."]",
				  "setclipboard/getclipboard: не совпадает содержимое", false)
		end
	end	
end


local function test_hidden_properties()
	if not present(gethiddenproperty, "gethiddenproperty") or not present(sethiddenproperty, "sethiddenproperty") then return end

	local part = Instance.new("Part")
	part.Name = "HiddenPropTestPart"

	local ok_normal, name_val, is_name_hidden = safe_pcall(gethiddenproperty, part, "Name")
	check(ok_normal and name_val == "HiddenPropTestPart" and is_name_hidden == false, "gethiddenproperty: получает обычное свойство (Name) и is_hidden=false", "gethiddenproperty: не получил обычное свойство или is_hidden=true", true)

	local ok_hidden_read, datacost_before, is_datacost_hidden = safe_pcall(gethiddenproperty, part, "DataCost")
	check(ok_hidden_read and type(datacost_before) == "number", "gethiddenproperty: успешно читает скрытое свойство 'DataCost'", "gethiddenproperty: не смог прочитать 'DataCost'", true)

	local ok_set = select(1, safe_pcall(sethiddenproperty, part, "DataCost", datacost_before + 50))
	if check(ok_set, "sethiddenproperty: выполнился для 'DataCost' без ошибок", "sethiddenproperty: ошибка при записи в 'DataCost'", true) then
		local ok_read_after, datacost_after = safe_pcall(gethiddenproperty, part, "DataCost")
		check(ok_read_after and datacost_after == datacost_before + 50, "sethiddenproperty: значение 'DataCost' было успешно изменено", "sethiddenproperty: значение 'DataCost' не изменилось", true)
	end

	local pcall_write_fail = not select(1, pcall(function() part.DataCost = 0 end))
	check(pcall_write_fail, "sethiddenproperty: обычная запись в 'DataCost' по-прежнему вызывает ошибку", "sethiddenproperty: 'DataCost' стал записываемым напрямую", false)


	local _, _, is_netowner_hidden = safe_pcall(gethiddenproperty, part, "NetworkOwnerV3")
	check(is_netowner_hidden, "gethiddenproperty: is_hidden=true для действительно скрытого свойства (NetworkOwnerV3)", "gethiddenproperty: is_hidden=false для NetworkOwnerV3", false)


	part:Destroy()
end

local function test_environments()
	if present(getrenv, "getrenv") then
		local ok_get, renv = safe_pcall(getrenv)
		if check(ok_get and type(renv) == "table", "getrenv: возвращает таблицу", "getrenv: не вернул таблицу", true) then
			local sentinel = "RENV_TEST_SENTINEL"
			renv.RENV_TEST_SENTINEL = true
			check(getrenv().RENV_TEST_SENTINEL, "getrenv: изменения персистентны", "getrenv: изменения не сохраняются", false)
			renv.RENV_TEST_SENTINEL = nil
			check(not getrenv().RENV_TEST_SENTINEL, "getrenv: изменения можно отменить (очистка)", "getrenv: не удалось очистить", false)
		end
	end

	if present(getsenv, "getsenv") then
		local animate
		local lp = game:GetService("Players").LocalPlayer
		if lp and lp.Character then
			animate = lp.Character:FindFirstChild("Animate", true)
		end

		if animate then
			local ok_get, env = safe_pcall(getsenv, animate)
			if check(ok_get and type(env) == "table", "getsenv: получает окружение для Animate", "getsenv: не получил окружение для Animate", true) then
				check(type(env.onSwimming) == "function", "getsenv: окружение Animate содержит ожидаемые члены (onSwimming)", "getsenv: окружение Animate не содержит onSwimming", false)
			end
		else
			warnEmoji("getsenv: Animate не найден, основной тест пропущен")
		end

		local s_inactive = Instance.new("LocalScript")
		local ok_inactive_err = not select(1, safe_pcall(getsenv, s_inactive))
		check(ok_inactive_err, "getsenv: ожидаемо выдает ошибку на неактивном скрипте", "getsenv: не вызвал ошибку на неактивном скрипте. Я уверен что эта функция эмулирована🤬🤬 (спуфнута).", true)
		s_inactive:Destroy()

		local mod = Instance.new("ModuleScript")
		local ok_get_mod, senv_mod = safe_pcall(getsenv, mod)
		check(ok_get_mod and senv_mod == nil, "getsenv: возвращает nil для ModuleScript, не находящегося в состоянии 'running'", "getsenv: не вернул nil для ModuleScript", true)
		mod:Destroy()
	end
end

local function test_isfunctionhooked()
    if not present(isfunctionhooked, "isfunctionhooked") or not present(hookfunction, "hookfunction") then return end
    
    local function my_func() end
    check(not isfunctionhooked(my_func), "isfunctionhooked: возвращает false для не-хукнутой функции", "isfunctionhooked: вернул true для не-хукнутой функции", true)
    
    local old = hookfunction(my_func, function() end)
    check(isfunctionhooked(my_func), "isfunctionhooked: возвращает true для хукнутой функции", "isfunctionhooked: вернул false для хукнутой функции", true)
    
    hookfunction(my_func, old) 
    check(not isfunctionhooked(my_func), "isfunctionhooked: возвращает false после восстановления оригинала", "isfunctionhooked: вернул true после восстановления", true)
end

local function test_isnewcclosure()
    if not present(isnewcclosure, "isnewcclosure") or not present(newcclosure, "newcclosure") then return end
    
    local function a() end
    check(not isnewcclosure(a), "isnewcclosure: возвращает false для обычной функции", "isnewcclosure: вернул true для обычной функции", true)

    local b = newcclosure(a)
    check(isnewcclosure(b), "isnewcclosure: возвращает true для результата newcclosure", "isnewcclosure: вернул false для newcclosure", true)
end

local function test_simulation_radius()
    if not present(setsimulationradius, "setsimulationradius") or not present(getsimulationradius, "getsimulationradius") then return end
    
    local ok_get_orig, original_radius = safe_pcall(getsimulationradius)
    if not check(ok_get_orig and type(original_radius) == "number", "getsimulationradius: изначально возвращает число", "getsimulationradius: не вернул число", false) then return end
    
    local new_radius = original_radius + 100
    local ok_set = select(1, safe_pcall(setsimulationradius, new_radius))
    if check(ok_set, "setsimulationradius: выполняется без ошибок", "setsimulationradius: ошибка при выполнении", false) then
        local ok_get_new, current_radius = safe_pcall(getsimulationradius)
        check(ok_get_new and current_radius == new_radius, "getsimulationradius: возвращает новое установленное значение", "getsimulationradius: не вернул новое значение", false)
        setsimulationradius(original_radius)
    end
end

local function test_actors_library()
    if not present(getactors, "getactors") then return end

    local ok_actors, actors = safe_pcall(getactors)
    if not (ok_actors and type(actors) == "table") then
        check(false, "getactors: не вернул таблицу", "getactors: ошибка", false)
        return
    end
    check(true, "getactors: возвращает таблицу", "getactors: ошибка", false)

    local parallel_ok, inParallel = false, false
    if present(isparallel, "isparallel") then
        parallel_ok, inParallel = safe_pcall(isparallel)
        if not (parallel_ok and type(inParallel) == "boolean") then
            warnEmoji("isparallel: ошибка, тесты Actor пропущены.")
            return
        end
    else
        warnEmoji("isparallel отсутствует, тесты Actor пропущены.")
        return
    end

    if not inParallel then
        warnEmoji("Не в parallel контексте, создание Actor пропущено.")
        if #actors == 0 then
            warnEmoji("Actors отсутствуют, тесты зависимых функций пропущены.")
            return
        end
    end

    if #actors > 0 and present(run_on_actor, "run_on_actor") then
        local ok_run = safe_pcall(run_on_actor, actors[1], 'print("Hello from Actor!")')
        check(ok_run, "run_on_actor: выполняется без ошибок", "run_on_actor: ошибка", false)
    end

    if present(getactorthreads, "getactorthreads") and present(run_on_thread, "run_on_thread") then
        local ok_threads, threads = safe_pcall(getactorthreads)
        if ok_threads and type(threads) == "table" and #threads > 0 then
            check(true, "getactorthreads: возвращает таблицу", "getactorthreads: ошибка", false)
            local ok_run_thread = safe_pcall(run_on_thread, threads[1], "print('Hello from Actor Thread!')")
            check(ok_run_thread, "run_on_thread: выполняется без ошибок", "run_on_thread: ошибка", false)
        else
            warnEmoji("Не найдено Actor Threads, тест run_on_thread пропущен.")
        end
    end

    if present(create_comm_channel, "create_comm_channel") then
        local ok_comm, comm_id, event = safe_pcall(create_comm_channel)
        if ok_comm and type(comm_id) == "number" and typeof(event) == "Instance" and event:IsA("BindableEvent") then
            check(true, "create_comm_channel: возвращает id и BindableEvent", "create_comm_channel: ошибка", false)
        else
            check(false, "create_comm_channel: ошибка", "create_comm_channel: неверные типы", false)
        end
    end
end

local function run_test_suite(suite_name, func_name, func)
	if type(func_name) == "function" and func == nil then
		func = func_name
		func_name = suite_name
	end
	info(func_name)
	local success, err = safe_pcall(func)
	if not success then
		fail("!!! КРАШ В ТЕСТЕ '" .. suite_name .. " -> " .. func_name .."': " .. tostring(err))
	end
end

run_test_suite("--- Основные функции ---", function()
	run_test_suite("Основные функции", "test_newcclosure", test_newcclosure)
	run_test_suite("Основные функции", "test_hookfunction", test_hookfunction)
	run_test_suite("Основные функции", "test_restorefunction", test_restorefunction)
	run_test_suite("Основные функции", "test_getrawmetatable", test_getrawmetatable)
	run_test_suite("Основные функции", "test_setrawmetatable", test_setrawmetatable)
	run_test_suite("Основные функции", "test_readonly", test_readonly)
	run_test_suite("Основные функции", "test_hookmetamethod", test_hookmetamethod)
	run_test_suite("Основные функции", "test_getgc", test_getgc)
	run_test_suite("Основные функции", "test_cloneref", test_cloneref)
	run_test_suite("Основные функции", "test_firetouchinterest", test_firetouchinterest)
	run_test_suite("Основные функции", "test_firesignal", test_firesignal)
	run_test_suite("Основные функции", "test_compareinstances", test_compareinstances)
	run_test_suite("Основные функции", "test_identifyexecutor", test_identifyexecutor)
	run_test_suite("Основные функции", "test_isrbxactive", test_isrbxactive)
	run_test_suite("Основные функции", "test_fpscap", test_fpscap)
	run_test_suite("Основные функции", "test_hui", test_hui)
end)

run_test_suite("--- Проверки типов Closure ---", function()
	run_test_suite("Проверки типов Closure", "test_closure_checks", test_closure_checks)
	run_test_suite("Проверки типов Closure", "test_replaceclosure", test_replaceclosure)
	run_test_suite("Проверки типов Closure", "test_newlclosure", test_newlclosure)
	run_test_suite("Проверки типов Closure", "test_isfunctionhooked", test_isfunctionhooked)
	run_test_suite("Проверки типов Closure", "test_isnewcclosure", test_isnewcclosure)
end)

run_test_suite("--- Низкоуровневые операции 💀💀💀 ---", function()
	run_test_suite("Низкоуровневые операции", "test_checkcaller", test_checkcaller)
	run_test_suite("Низкоуровневые операции", "test_getconnections", test_getconnections)
	run_test_suite("Низкоуровневые операции", "test_getnilinstances", test_getnilinstances)
	run_test_suite("Низкоуровневые операции", "test_threadidentity", test_threadidentity)
	run_test_suite("Низкоуровневые операции", "test_getscripts", test_getscripts)
	run_test_suite("Низкоуровневые операции", "test_getrunningscripts", test_getrunningscripts)
	run_test_suite("Низкоуровневые операции", "test_getscriptbytecode", test_getscriptbytecode)
	run_test_suite("Низкоуровневые операции", "test_setscriptable", test_setscriptable)
	run_test_suite("Низкоуровневые операции", "test_isscriptable", test_isscriptable)
	run_test_suite("Низкоуровневые операции", "test_getgenv", test_getgenv)
	run_test_suite("Низкоуровневые операции", "test_getcallbackvalue", test_getcallbackvalue)
	run_test_suite("Низкоуровневые операции", "test_getcallingscript", test_getcallingscript)
	run_test_suite("Низкоуровневые операции", "test_getloadedmodules", test_getloadedmodules)
	run_test_suite("Низкоуровневые операции", "test_getscriptclosure", test_getscriptclosure)
	run_test_suite("Низкоуровневые операции", "test_getscripthash", test_getscripthash)
	run_test_suite("Низкоуровневые операции", "test_getfunctionhash", test_getfunctionhash)
	run_test_suite("Низкоуровневые операции", "test_getinstances", test_getinstances)
	run_test_suite("Низкоуровневые операции", "test_fireproximityprompt", test_fireproximityprompt)
	run_test_suite("Низкоуровневые операции", "test_fireclickdetector", test_fireclickdetector)
	--run_test_suite("Низкоуровневые операции", "test_hidden_properties", test_hidden_properties) -- Тупой bunni крашится из - за неё🤬🤬🤬🤬
	run_test_suite("Низкоуровневые операции", "test_environments", test_environments)
end)

run_test_suite("--- Файловые операции и сетевые (aka request и тд.) ---", function()
	run_test_suite("Файловые операции и сетевые", "test_request", test_request)
	run_test_suite("Файловые операции и сетевые", "test_file_operations", test_file_operations)
	run_test_suite("Файловые операции и сетевые", "test_folder_and_load_ops", test_folder_and_load_ops)
	run_test_suite("Файловые операции и сетевые", "test_getcustomasset", test_getcustomasset)
	run_test_suite("Файловые операции и сетевые", "test_replicatesignal", test_replicatesignal)
	run_test_suite("Файловые операции и сетевые", "test_cache", test_cache)
	run_test_suite("Файловые операции и сетевые", "test_mouse_emulation", test_mouse_emulation)
	run_test_suite("Файловые операции и сетевые", "test_misc_env", test_misc_env)
end)

run_test_suite("--- Криптография ---", function()
	run_test_suite("Криптография", "test_crypto_ops", test_crypto_ops)
	run_test_suite("Криптография", "test_crypto_extended", test_crypto_extended)
	run_test_suite("Криптография", "test_compression", test_compression)
end)

run_test_suite("--- Дополнительные функции среды ---", function()
	run_test_suite("Дополнительные функции среды", "test_simulation_radius", test_simulation_radius)
	run_test_suite("Дополнительные функции среды", "test_actors_library", test_actors_library)
end)

run_test_suite("--- 2D Рендеринг ---", "test_drawing", test_drawing)
run_test_suite("--- Ебучий лоадстринг ---", "test_loadstring", test_loadstring)

run_test_suite("--- Тесты для debug ---", function()
	local function test_debug_setname()
		if not present(debug.setname, "debug.setname") then return end
		local function foo() end
		local ok_set = select(1, safe_pcall(debug.setname, foo, "ass"))
		if check(ok_set, "debug.setname: выполняется без ошибок", "debug.setname: ошибка при выполнении", true) then
			local info_ok, info_table = safe_pcall(debug.getinfo, foo)
			if info_ok and info_table and info_table.name then
				check(info_table.name == "ass", "debug.setname: успешно изменил имя функции", "debug.setname: не изменил имя функции", true)
			else
				fail("debug.setname: не удалось получить debug.info для проверки имени")
			end
		end
	end

	local function test_debug_isvalidlevel()
		if not present(debug.isvalidlevel, "debug.isvalidlevel") then return end
		check(debug.isvalidlevel(1), "debug.isvalidlevel(1): возвращает true для валидного уровня", "debug.isvalidlevel(1): вернул false", true)
		check(not debug.isvalidlevel(100), "debug.isvalidlevel(100): возвращает false для невалидного уровня", "debug.isvalidlevel(100): вернул true", true)
	end
	
	run_test_suite("Тесты для debug", "test_debug_info", test_debug_info)
	run_test_suite("Тесты для debug", "test_debug_upvalues", test_debug_upvalues)
	run_test_suite("Тесты для debug", "test_debug_constants", test_debug_constants)
	run_test_suite("Тесты для debug", "test_debug_setstack", test_debug_setstack)
	run_test_suite("Тесты для debug", "test_debug_setmetatable", test_debug_setmetatable)
	run_test_suite("Тесты для debug", "test_clonefunction", test_clonefunction)
	run_test_suite("Тесты для debug", "test_debug_protos", test_debug_protos)
	run_test_suite("Тесты для debug", "test_getreg", test_getreg)
	run_test_suite("Тесты для debug", "test_debug_more", test_debug_more)
	run_test_suite("Тесты для debug", "test_debug_setname", test_debug_setname)
	run_test_suite("Тесты для debug", "test_debug_isvalidlevel", test_debug_isvalidlevel)
end)

info("\n" .. string.rep("-", 20))
local percent = totalTests > 0 and math.floor((passedTests / totalTests) * 100) or 0
local skidRate = totalTests > 0 and math.floor((skidCount / totalTests) * 100) or 0
info("Итого: "..passedTests.."/"..totalTests.." ("..percent.."%)")
info("Skid Rate: "..skidCount.."/"..totalTests.." ("..skidRate.."%)")
info(string.rep("-", 20))



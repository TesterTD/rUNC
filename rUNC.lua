local totalTests = 0
local passedTests = 0
local skidCount = 0

local function info(msg)
	print(msg)
end

local function ok(msg)
	print("✅ "..msg)
end

local function fail(msg)
	print("❌ "..msg)
end

local function warnEmoji(msg)
	print("⚠️ "..msg)
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
			check(iscclosure(ccFn), "newcclosure: iscclosure возвращает true", "newcclosure: iscclosure возвращает false", true)
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

	check(islclosure(lua_fn), "islclosure: true для обычной Luau функции", "islclosure: false для Luau функции", true)
	check(not islclosure(c_fn_standard), "islclosure: false для стандартной C-функции (print)", "islclosure: true для print", true)
	if c_fn_new then
		check(not islclosure(c_fn_new), "islclosure: false для newcclosure", "islclosure: true для newcclosure", true)
	end

	check(not iscclosure(lua_fn), "iscclosure: false для обычной Luau функции", "iscclosure: true для Luau функции", true)
	check(iscclosure(c_fn_standard), "iscclosure: true для стандартной C-функции (print)", "iscclosure: false для print", true)
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
        local var1, var2, var3 = "hello", 123, { key = "val" }
        local func = function() return var1, var2, var3.key end

        local ok_gus, upvals = safe_pcall(d_gus, func)
        if check(ok_gus and type(upvals) == "table", "getupvalues: возвращает таблицу", "getupvalues: не вернул таблицу", true) then
            check(#upvals == 3 and upvals[1] == var1 and upvals[2] == var2 and upvals[3] == var3, "getupvalues: корректные значения", "getupvalues: неверные значения", true)
        end

        local ok_gu, upval1 = safe_pcall(d_gu, func, 1)
        check(ok_gu and upval1 == "hello", "getupvalue: корректное значение по индексу", "getupvalue: неверное значение", true)

        local ok_su = select(1, safe_pcall(d_su, func, 2, 456))
        if check(ok_su, "setupvalue: без ошибок", "setupvalue: ошибка", true) then
            local _, r2 = func()
            check(r2 == 456 and var2 == 123, "setupvalue: изменяет upvalue внутри функции", "setupvalue: не изменил upvalue", true)
        end

        local ok_su2 = select(1, safe_pcall(d_su, func, 1, "world"))
        check(ok_su2, "setupvalue: смена типа upvalue (string)", "setupvalue: ошибка при смене типа", true)
        local r1_new = select(1, func())
        check(r1_new == "world", "setupvalue: смена типа отразилась на вызове", "setupvalue: смена типа не сработала", true)
    end

    do
        local no_upval_func = function() return 1 end
        local ok_gus, upvals = safe_pcall(d_gus, no_upval_func)
        check(ok_gus and type(upvals) == "table" and #upvals == 0, "getupvalues: пустая таблица для функции без upvalues", "getupvalues: не пустая таблица", true)
    end

    do
        local upval_func = function() local a = 1 end
        local ok_err_gu = not select(1, safe_pcall(d_gu, upval_func, 0))
        check(ok_err_gu, "getupvalue: ошибка при индексе 0", "getupvalue: нет ошибки при индексе 0", true)
        local ok_err_gu2 = not select(1, safe_pcall(d_gu, upval_func, 2))
        check(ok_err_gu2, "getupvalue: ошибка при выходе за пределы", "getupvalue: нет ошибки при выходе за пределы", true)
    end

    do
        local ok_err_gu_c = not select(1, safe_pcall(d_gu, print, 1))
        local ok_err_gus_c = not select(1, safe_pcall(d_gus, print))
        local ok_err_su_c = not select(1, safe_pcall(d_su, print, 1, nil))
        check(ok_err_gu_c, "getupvalue: ошибка на C closure", "getupvalue: нет ошибки на C closure", true)
        check(ok_err_gus_c, "getupvalues: ошибка на C closure", "getupvalues: нет ошибки на C closure", true)
        check(ok_err_su_c, "setupvalue: ошибка на C closure", "setupvalue: нет ошибки на C closure", true)
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
        local call_triggered = false
        local old_call
        local function call_hook(self, ...)
            if self == game then
                call_triggered = true
                return "hooked_call_result"
            end
            return old_call(self, ...)
        end
        local ok_hook, orig_call = safe_pcall(hookmetamethod, game, "__call", call_hook)
        if check(ok_hook and type(orig_call) == "function", "hookmetamethod: __call хук установлен на game", "hookmetamethod: __call ошибка установки на game", true) then
            old_call = orig_call
            local ok_res, res = pcall(function() return game() end)
            check(call_triggered and ok_res and res == "hooked_call_result", "hookmetamethod: __call перехват работает", "hookmetamethod: __call перехват не работает", true)
            local ok_restore = safe_pcall(hookmetamethod, game, "__call", old_call)
            check(ok_restore, "hookmetamethod: __call восстановлен", "hookmetamethod: __call ошибка восстановления", true)
        end
    end

    do
        local len_triggered = false
        local old_len
        local function len_hook(self)
            if self == game then
                len_triggered = true
                return 12345
            end
            return old_len(self)
        end
        local ok_hook, orig_len = safe_pcall(hookmetamethod, game, "__len", len_hook)
        if check(ok_hook and type(orig_len) == "function", "hookmetamethod: __len хук установлен на game", "hookmetamethod: __len ошибка установки на game", true) then
            old_len = orig_len
            local res = #game
            check(len_triggered and res == 12345, "hookmetamethod: __len перехват работает", "hookmetamethod: __len перехват не работает", true)
            local ok_restore = safe_pcall(hookmetamethod, game, "__len", old_len)
            check(ok_restore, "hookmetamethod: __len восстановлен", "hookmetamethod: __len ошибка восстановления", true)
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
		check(part_found, "getgc(true): находит userdata (Instance)", "getgc(true): не нашел Instance", false)
	end

end

local function test_cloneref()
	if not present(cloneref, "cloneref") then return end

	local original = Instance.new("Part", workspace)
	local ok_clone, clone = safe_pcall(cloneref, original)

	if not check(ok_clone and typeof(clone) == "Instance", "cloneref: создает клон типа Instance", "cloneref: не смог создать клон", true) then
		original:Destroy(); return
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
	local ok_method_destroyed, _ = safe_pcall(clone.GetFullName, clone)
	check(not ok_method_destroyed, "cloneref: клон становится невалидным после уничтожения оригинала", "cloneref: клон остается валидным", true)

end

local function test_firetouchinterest()
	if not present(firetouchinterest, "firetouchinterest") then return end

	local part1 = Instance.new("Part", workspace); part1.CFrame = CFrame.new(0, 20, 0); part1.Anchored = true
	local part2 = Instance.new("Part", workspace); part2.CFrame = CFrame.new(0, 20.1, 0); part2.Anchored = true

	local touch_started, touch_ended = 0, 0
	local c1 = part1.Touched:Connect(function() touch_started = touch_started + 1 end)
	local c2 = part1.TouchEnded:Connect(function() touch_ended = touch_ended + 1 end)

	part1.CanTouch = false
	task.wait(0.1)
	safe_pcall(firetouchinterest, part1, part2, 0)
	task.wait(0.1)
	check(touch_started == 0, "firetouchinterest: принимает свойство CanTouch (false)", "firetouchinterest: игнорирует CanTouch", true)

	part1.CanTouch = true
	safe_pcall(firetouchinterest, part1, part2, 0)
	task.wait(0.1)
	check(touch_started == 1, "firetouchinterest: вызывает Touched (toggle 0)", "firetouchinterest: не вызывает Touched (toggle 0)", true)

	safe_pcall(firetouchinterest, part1, part2, 1)
	task.wait(0.1)
	check(touch_ended == 1, "firetouchinterest: вызывает TouchEnded (toggle 1)", "firetouchinterest: не вызывает TouchEnded (toggle 1)", true)

	safe_pcall(firetouchinterest, part1, part2, true)
	task.wait(0.1)
	check(touch_started == 2, "firetouchinterest: вызывает Touched (toggle true)", "firetouchinterest: не вызывает Touched (toggle true)", true)

	safe_pcall(firetouchinterest, part1, part2, false)
	task.wait(0.1)
	check(touch_ended == 2, "firetouchinterest: вызывает TouchEnded (toggle false)", "firetouchinterest: не вызывает TouchEnded (toggle false)", true)

	local ok_err_nil = not select(1, safe_pcall(firetouchinterest, part1, nil, 0))
	check(ok_err_nil, "firetouchinterest: ошибка при передаче nil в качестве объекта", "firetouchinterest: не вызвал ошибку для nil", true)

	c1:Disconnect(); c2:Disconnect(); part1:Destroy(); part2:Destroy()

end

local function test_checkcaller()
    if not present(checkcaller, "checkcaller") then return end

    local ok_p, v_p = safe_pcall(checkcaller)
    check(ok_p and v_p, "checkcaller: true в pcall", "checkcaller: не true в pcall/ошибка", true)

    local ok_args = safe_pcall(function() return checkcaller("arg") end)
    check(ok_args, "checkcaller: игнорирует аргументы", "checkcaller: крашит при аргументах", true)

    local gm = game
    pcall(function() if cloneref then gm = cloneref(game) end end)

    local hook_result
    local old_nc
    local in_call = false

    local function wrapper(self, ...)
        if in_call then
            return old_nc and old_nc(self, ...)
        end
        in_call = true
        local m = getnamecallmethod()
        if m == "IsA" then
            hook_result = checkcaller()
        end
        local ok, res = pcall(old_nc, self, ...)
        in_call = false
        if ok then
            return res
        end
    end

    local ok_hook = false
    pcall(function()
        if newcclosure then
            old_nc = hookmetamethod(gm, "__namecall", newcclosure(wrapper))
        else
            old_nc = hookmetamethod(gm, "__namecall", wrapper)
        end
        ok_hook = type(old_nc) == "function"
    end)

    check(ok_hook, "hookmetamethod: оригинал получен", "hookmetamethod: не вернул оригинал __namecall", true)
    if not ok_hook then return end

    pcall(function() gm:IsA("Workspace") end)
    task.wait()
    check(hook_result == false, "checkcaller: false при вызове из C-кода", "checkcaller: true для C-кода", true)

    if newcclosure then
        local cc_false_fn = newcclosure(function()
            return checkcaller()
        end)
        local ok_cc, v_cc = safe_pcall(cc_false_fn)
        check(ok_cc and not v_cc, "checkcaller: false из newcclosure", "checkcaller: true из newcclosure", true)

        local function normal_fn()
            return cc_false_fn()
        end
        local ok_n, v_n = safe_pcall(normal_fn)
        check(ok_n and v_n, "checkcaller: true при вызове C-closure из Luau", "checkcaller: false при вызове C-closure из Luau", true)
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
end


local function test_getconnections()
	if not present(getconnections, "getconnections") then return end
	local be = Instance.new("BindableEvent")
	local triggered = false
	local function handler() triggered = true; return "fired" end
	local c = be.Event:Connect(handler)

	local okc, conns = safe_pcall(getconnections, be.Event)
	check(okc and type(conns) == "table" and #conns >= 1, "getconnections: возвращает таблицу соединений", "getconnections: вернул не таблицу или пусто", true)

	if okc and #conns > 0 then
		local conn_obj = conns[#conns] 
		if check(typeof(conn_obj) == "RBXScriptConnection" and conn_obj.Connected, "getconnections: элементы в таблице - валидные Connection", "getconnections: элементы не являются валидными Connection", true) then
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
	c:Disconnect(); be:Destroy()

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

	local post_ok, res_post = safe_pcall(req, {Url="https://httpbin.org/post", Method="POST", Body="test", Headers={["Content-Type"]="text/plain"}})
	check(post_ok and type(res_post)=="table" and res_post.Success and res_post.Body:find("test"), name..": успешный POST запрос", name..": ошибка POST запроса", false)

	local get_ok, res_get = safe_pcall(req, { Url = "https://httpbin.org/get", Method = "GET" })
	if check(get_ok and res_get and res_get.Success and res_get.StatusCode == 200, name..": успешный GET запрос", name..": ошибка GET запроса", false) then
		local p, decoded = safe_pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), res_get.Body)
		if check(p and type(decoded) == "table" and type(decoded.headers) == "table", name..": тело ответа GET - валидный JSON", name..": тело ответа GET - не JSON", false) then
			local has_ua = decoded.headers["User-Agent"] and decoded.headers["User-Agent"] ~= ""
			local has_fp = false
			for k in pairs(decoded.headers) do
				if k:lower():find("fingerprint") then has_fp = true; break end
			end
			check(has_ua, name..": запрос содержит заголовок User-Agent", name..": отсутствует User-Agent", false)
			check(has_fp, name..": запрос содержит заголовок Fingerprint", name..": отсутствует Fingerprint", false)
		end
	end

	local ok_err, _ = safe_pcall(req, {Url="invalid-url", Method="GET"})
	check(not select(1, safe_pcall(req, {Url = "https://invalid.domain. nonexistent/", Method = "GET"})), name..": ошибка при невалидном URL", name..": не вызвал ошибку для невалидного URL", false)
end

local function test_getnilinstances()
	if not present(getnilinstances, "getnilinstances") then return end

	local ok_get, list_before = safe_pcall(getnilinstances)
	check(ok_get and type(list_before) == "table", "getnilinstances: возвращает таблицу", "getnilinstances: не вернул таблицу/ошибка", true)

	local p = Instance.new("Part"); p.Name = "GNI_Test_"..math.random()
	local parented_p = Instance.new("Part", workspace)
	task.wait(0.05)

	local list = getnilinstances()
	local found, found_parented = false, false
	for _,inst in ipairs(list) do 
		if inst==p then found = true end
		if inst==parented_p then found_parented = true end
	end
	check(found, "getnilinstances: находит экземпляры вне иерархии (nil parent)", "getnilinstances: не находит nil-parent экземпляры", true)
	check(not found_parented, "getnilinstances: не включает экземпляры с родителем", "getnilinstances: ошибочно включает экземпляры с родителем", true)

	p:Destroy()
	parented_p:Destroy()
	task.wait(0.05)

	local list_after = getnilinstances()
	local found_after = false
	for _,inst in ipairs(list_after) do if inst==p then found_after = true; break end end
	check(not found_after, "getnilinstances: экземпляр исчезает после Destroy", "getnilinstances: экземпляр не исчез после Destroy", true)

end

local function test_threadidentity()
	local gti, sti = getthreadidentity or getidentity, setthreadidentity or setidentity
	if not present(gti, "getthreadidentity") or not present(sti, "setthreadidentity") then return end

	local original_identity = gti()
	check(type(original_identity) == "number", "getthreadidentity: возвращает число", "getthreadidentity: не вернул число", true)
	local new_id = -1
	local th = task.spawn(function() sti(5); new_id=gti() end)
	task.wait()
	check(new_id == 5, "setthreadidentity: работает в новом потоке (task.spawn)", "setthreadidentity: не сработал в новом потоке", true)
	check(gti() == original_identity, "setthreadidentity: не влияет на другие потоки", "setthreadidentity: повлиял на другой поток", true)

	sti(original_identity)

end

local function test_debug_info()
	local getinfo = debug.getinfo
	if not present(getinfo, "debug.getinfo") then return end

	local line_defined
	local upval = "upvalue"
	local function target_func(arg)
		local l_var = arg
		line_defined = getinfo(1,"l").currentline-3
		return upval .. l_var
	end

	local ok_info, info_by_ref = safe_pcall(getinfo, target_func, "Slnu")
	if check(ok_info and type(info_by_ref) == "table", "debug.getinfo(func): возвращает таблицу", "debug.getinfo(func): вернул не таблицу", true) then
		check(info_by_ref.what == "Lua" and type(info_by_ref.source) == "string", "debug.getinfo(func, S): 'what' и 'source' корректны", "debug.getinfo(func, S): некорректные 'what' или 'source'", true)
		check(info_by_ref.linedefined == line_defined and type(info_by_ref.lastlinedefined) == "number", "debug.getinfo(func, l): 'linedefined' корректно", "debug.getinfo(func, l): некорректный 'linedefined'", true)
		check(info_by_ref.nups == 1, "debug.getinfo(func, u): 'nups' (кол-во upvalue) корректно", "debug.getinfo(func, u): некорректный 'nups'", true)
		if info_by_ref.name then 
			check(info_by_ref.name == "target_func", "debug.getinfo(func, n): 'name' корректно", "debug.getinfo(func, n): некорректный 'name'", true)
		end
	end

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

	local ok_err_c = not select(1, safe_pcall(getinfo, print, "s"))
	check(ok_err_c, "debug.getinfo: ожидаемо выдает ошибку на C-функции", "debug.getinfo: не вызвал ошибку на C-функции", true)

end

local function test_getscripts()
	if not present(getscripts, "getscripts") then return end


	local dummy_script = Instance.new("LocalScript")
	dummy_script.Name = "GetScriptsDummy_"..math.random()
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

	scripts = getscripts()
	found = false
	for _, s in ipairs(scripts) do
		if s == dummy_script then
			found = true
			break
		end
	end
	check(not found, "getscripts: не находит уничтоженный скрипт", "getscripts: нашел уничтоженный скрипт", false)

end

local function test_clonefunction()
	if not present(clonefunction, "clonefunction") then return end

	local upval = { n = 10 }
	local original = function() upval.n = upval.n + 1; return "original" end
	local ok_clone, cloned = safe_pcall(clonefunction, original)

	if check(ok_clone and type(cloned) == "function", "clonefunction: создает функцию", "clonefunction: не создал функцию", true) then
		check(original ~= cloned, "clonefunction: клон не является той же самой функцией", "clonefunction: клон и оригинал идентичны", true)
		if getfenv then
			check(getfenv(original) == getfenv(cloned), "clonefunction: клон и оригинал имеют одно окружение (env)", "clonefunction: окружения разные", true)
		end
		
		local okh, old_original = pcall(hookfunction, original, function() return "hooked" end)
		if okh then
			local original_res = original()
			local cloned_res = cloned()
			check(original_res == "hooked" and cloned_res == "original", "clonefunction: хук оригинала не влияет на клон", "clonefunction: хук повлиял на клон", true)
		end
	end

	local ok_err, _ = safe_pcall(clonefunction, print)
	check(not ok_err, "clonefunction: ошибка при клонировании С-функции", "clonefunction: не вызвал ошибку для C-функции", true)
end

local function test_debug_protos()
	local getproto = debug.getproto
	if not present(getproto, "debug.getproto") then return end

	local activated_proto_ref
	local function container()
		local function proto1() return "p1" end
		activated_proto_ref = proto1
		local function proto2() return "p2" end
		return proto1, proto2
	end

	local ok_inactive, inactive_p1 = safe_pcall(getproto, container, 1, false)
	if check(ok_inactive and type(inactive_p1) == "function", "debug.getproto: возвращает неактивный прототип", "debug.getproto: не вернул неактивный прототип", true) then
		local uncallable_ok, _ = safe_pcall(inactive_p1)
		check(not uncallable_ok, "debug.getproto: неактивный прототип не может быть вызван", "debug.getproto: неактивный прототип был вызван", true)
	end
	
	container()
	local ok_active, active_protos_table = safe_pcall(getproto, container, 1, true)
	local active_proto = active_protos_table and active_protos_table[1]
	if check(ok_active and type(active_protos_table) == "table" and #active_protos_table > 0 and type(active_proto) == "function", "debug.getproto(true): возвращает таблицу активных прототипов", "debug.getproto(true): не вернул таблицу активных прототипов", true) then
		check(active_proto == activated_proto_ref, "debug.getproto(true): активный прототип совпадает с оригиналом", "debug.getproto(true): активный прототип не совпадает", true)
		local can_call_ok, call_res = safe_pcall(active_proto)
		check(can_call_ok and call_res == "p1", "debug.getproto(true): активный прототип может быть вызван", "debug.getproto(true): не удалось вызвать активный прототип", true)
	end
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

	local thread_found = false
	for _, value in pairs(getreg()) do
		if value == loop_thread then
			thread_found = true
			local close_ok, _ = safe_pcall(coroutine.close, loop_thread)
			if close_ok then
				task.wait(0.05)
				thread_closed = coroutine.status(loop_thread) == "dead"
			end
			break
		end
	end
	check(thread_found, "getreg: находит созданный поток в реестре", "getreg: не нашел поток", false)
	check(thread_closed, "getreg: можно использовать для закрытия потока через coroutine.close", "getreg: не удалось закрыть поток", false)

end

local function test_debug_constants()
	if not present(debug.getconstants, "debug.getconstants") or not present(debug.getconstant, "debug.getconstant") then return end


	local const_str = "hello_const"
	local const_num = 123.456
	local function func_with_consts()
		return const_str, const_num, true
	end

	local ok_consts, consts_table = safe_pcall(debug.getconstants, func_with_consts)
	if check(ok_consts and type(consts_table) == "table", "getconstants: возвращает таблицу", "getconstants: не вернул таблицу", true) then
		local str_found, num_found, bool_found = false, false, false
		for _, v in ipairs(consts_table) do
			if v == const_str then str_found = true end
			if v == const_num then num_found = true end
			if v == true then bool_found = true end
		end
		check(str_found and num_found and bool_found, "getconstants: таблица содержит правильные константы", "getconstants: таблица не содержит констант", true)
	end

	local ok_c, val = safe_pcall(debug.getconstant, func_with_consts, 1)
	check(ok_c, "getconstant: выполнился для валидного индекса", "getconstant: ошибка на валидном индексе", true)

	local ok_c_nil, val_nil = safe_pcall(debug.getconstant, func_with_consts, 999)
	check(ok_c_nil and val_nil == nil, "getconstant: возвращает nil для индекса за пределами диапазона", "getconstant: не вернул nil", true)

	local ok_err_c_plural = not select(1, safe_pcall(debug.getconstants, print))
	local ok_err_c_singular = not select(1, safe_pcall(debug.getconstant, print, 1))
	check(ok_err_c_plural, "getconstants: ошибка на C-функции", "getconstants: не вызвал ошибку", true)
	check(ok_err_c_singular, "getconstant: ошибка на C-функции", "getconstant: не вызвал ошибку", true)

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
		check(getfenv().test_var_genv == nil, "getgenv: изолирован от getfenv (2)", "getgenv: не изолирован от getfenv (2)", false)
	end
end

local function test_getcallbackvalue()
	if not present(getcallbackvalue, "getcallbackvalue") then return end

	local bf = Instance.new("BindableFunction")
	local rf = Instance.new("RemoteFunction")

	local sentinel = false
	local callback_func = function() sentinel = true end
	bf.OnInvoke = callback_func

	local ok_get, retrieved = safe_pcall(getcallbackvalue, bf) 
	if ok_get and retrieved == nil then 
		ok_get, retrieved = safe_pcall(getcallbackvalue, bf, "OnInvoke")
	end
	
	if check(ok_get and retrieved == callback_func, "getcallbackvalue: извлекает установленный callback", "getcallbackvalue: не извлек callback", true) then
		retrieved()
		check(sentinel, "getcallbackvalue: извлеченный callback является рабочей функцией", "getcallbackvalue: callback не работает", true)
	end

	local ok_nil, val_nil = safe_pcall(getcallbackvalue, rf, "OnClientInvoke")
	check(ok_nil and val_nil == nil, "getcallbackvalue: возвращает nil для неустановленного свойства", "getcallbackvalue: не вернул nil", true)

	local ok_non, val_non = safe_pcall(getcallbackvalue, bf, "NonExistentProperty")
	check(ok_non and val_non == nil, "getcallbackvalue: возвращает nil для несуществующего свойства", "getcallbackvalue: не вернул nil для несуществующего свойства", true)

	bf:Destroy(); rf:Destroy()

end

local function test_getcustomasset()
	if not present(getcustomasset, "getcustomasset") then return end

	local path = "gcatest.txt"
	if isfile and isfile(path) and delfile then delfile(path) end

	if writefile then
		writefile(path, "test")
		local ok_get, assetId = safe_pcall(getcustomasset, path)
		if check(ok_get and type(assetId) == "string", "getcustomasset: выполняется без ошибок для существующего файла", "getcustomasset: ошибка при выполнении", false) then
			check(assetId:find("^rbxasset", 1, true), "getcustomasset: возвращает валидный asset id (rbxasset://...)", "getcustomasset: вернул невалидный id", false)
		end
		if delfile then delfile(path) end
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

	local running_script = script
	local inactive_script = Instance.new("LocalScript")

	local ok_get, list = safe_pcall(getrunningscripts)
	if not check(ok_get and type(list) == "table", "getrunningscripts: возвращает таблицу", "getrunningscripts: не вернул таблицу", false) then return end

	local found_self, found_inactive = false, false
	for _, s in ipairs(list) do
		if s == running_script then found_self = true end
		if s == inactive_script then found_inactive = true end
	end
	check(found_self, "getrunningscripts: находит текущий исполняемый скрипт", "getrunningscripts: не нашел текущий скрипт", false)
	check(not found_inactive, "getrunningscripts: не включает неактивные скрипты", "getrunningscripts: ошибочно включил неактивный скрипт", false)
	inactive_script:Destroy()

end

local function test_getscriptbytecode()
	if not present(getscriptbytecode, "getscriptbytecode") then return end


	local dummy_with_code = Instance.new("LocalScript")
	dummy_with_code.Source = "print('hello')"
	local dummy_empty = Instance.new("LocalScript")

	local ok_get, bytecode = safe_pcall(getscriptbytecode, dummy_with_code)
	check(ok_get and type(bytecode) == "string" and #bytecode > 0, "getscriptbytecode: возвращает строку байт-кода для скрипта с кодом", "getscriptbytecode: не вернул байт-код", false)

	local ok_nil, bc_nil = safe_pcall(getscriptbytecode, dummy_empty)
	check(ok_nil and bc_nil == nil, "getscriptbytecode: возвращает nil для скрипта без байт-кода", "getscriptbytecode: не вернул nil для пустого скрипта", false)

	dummy_with_code:Destroy(); dummy_empty:Destroy()
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

	if present(delfile, "delfile") then delfile(path) end
end

local function test_folder_and_load_ops()
	local fns = {makefolder, isfolder, listfiles, loadfile, writefile}
	local fns_names = {"makefolder", "isfolder", "listfiles", "loadfile", "writefile"}
	for i=1,#fns do if not present(fns[i], fns_names[i]) then return end end

	local folder = "luau_test_folder"
	local file_in_root = "luau_test_file.lua"
	local file_in_folder = folder .. "/" .. "inner_file.txt"

	if present(delfile, "delfile") then
		safe_pcall(delfile, file_in_root)
		safe_pcall(delfile, file_in_folder)
	end
	if present(delfolder, "delfolder") then safe_pcall(delfolder, folder) end
	task.wait(0.05)

	makefolder(folder)
	check(isfolder(folder), "isfolder: true для созданной через makefolder папки", "isfolder: false для созданной папки", false)
	
	writefile(file_in_root, "return ...+1")
	check(not isfolder(file_in_root), "isfolder: false для созданного файла", "isfolder: true для файла", true)
	writefile(file_in_folder, "test_content")

	local ok_list, root_files = safe_pcall(listfiles, "")
	if check(ok_list and type(root_files) == "table", "listfiles(''): возвращает таблицу", "listfiles(''): не вернул таблицу", false) then
		local found = false; for _,v in ipairs(root_files) do if v:match(folder) then found=true; break end end
		check(found, "listfiles(''): находит созданную папку", "listfiles(''): не нашел папку", false)
	end

	local ok_list2, folder_files = safe_pcall(listfiles, folder)
	if check(ok_list2 and type(folder_files) == "table", "listfiles(folder): возвращает таблицу", "listfiles(folder): не вернул таблицу", false) then
		local found = false; for _,v in ipairs(folder_files) do if v==("inner_file.txt") then found=true; break end end
		check(found, "listfiles(folder): находит файл внутри папки", "listfiles(folder): не нашел файл", false)
	end
	
	local ok_load, chunk = safe_pcall(loadfile, file_in_root)
	if check(ok_load and type(chunk)=="function", "loadfile: компилирует файл в функцию", "loadfile: не скомпилировал файл", true) then
		local ok_exec, res = safe_pcall(chunk, 10)
		check(ok_exec and res == 11, "loadfile: функция из файла работает корректно", "loadfile: функция не работает", true)
	end

	writefile(file_in_root, "invalid-syntax")
	check(not select(1, safe_pcall(loadfile, file_in_root)), "loadfile: ожидаемо выдает ошибку на файле с ошибкой синтаксиса", "loadfile: не вызвал ошибку", true)

	if present(delfolder, "delfolder") then
		local ok_del = select(1, safe_pcall(delfolder, folder))
		if check(ok_del, "delfolder: выполнился без ошибок", "delfolder: ошибка при выполнении", false) then
			check(not isfolder(folder), "delfolder: успешно удаляет папку", "delfolder: папка не удалена", false)
		end
	end

	if present(delfile, "delfile") then delfile(file_in_root) end
end


local function test_setscriptable()
	if not present(setscriptable, "setscriptable") then return end
	local part = Instance.new("Part")
	local prop = "Size"


	local ok_before = not select(1, safe_pcall(function() return part[prop] end))
	check(ok_before, "setscriptable: свойство '"..prop.."' изначально нескриптуемо (как и ожидалось)", "setscriptable: свойство '"..prop.."' изначально скриптуемо", true)

	local ok_set_true = select(1, safe_pcall(setscriptable, part, prop, true))
	if check(ok_set_true, "setscriptable(true): выполнился без ошибок", "setscriptable(true): ошибка при выполнении", true) then
		local p, val = safe_pcall(function() return part[prop] end)
		check(p and typeof(val) == "Vector3", "setscriptable(true): свойство '"..prop.."' стало читаемым", "setscriptable(true): свойство '"..prop.."' не читается", true)
	end

	local ok_set_false = select(1, safe_pcall(setscriptable, part, prop, false))
	if check(ok_set_false, "setscriptable(false): выполнился без ошибок", "setscriptable(false): ошибка при выполнении", true) then
		local ok_after = not select(1, safe_pcall(function() return part[prop] end))
		check(ok_after, "setscriptable(false): свойство '"..prop.."' снова стало нескриптуемым", "setscriptable(false): свойство '"..prop.."' осталось скриптуемым", true)
	end

	part:Destroy()

end

local function test_debug_setstack()  -- Убрал рекурсию
	if not present(debug.setstack, "debug.setstack") then return end

	local outer_success = false
	local function outer_wrapper()
		local outer_val = 1 
		local function inner()
			local success, err = safe_pcall(debug.setstack, 2, 1, 2)
			if success and outer_val == 2 then
				outer_success = true
			end
		end
		inner()
	end
	outer_wrapper()
	check(outer_success, "debug.setstack(2, ...): успешно изменяет local в родительском скоупе", "debug.setstack: не изменил local в родителе", true)

	local function inner_wrapper()
		local inner_val = 10 
		safe_pcall(debug.setstack, 1, 1, 20)
		return inner_val == 20
	end
	check(inner_wrapper(), "debug.setstack(1, ...): успешно изменяет local в текущем скоупе", "debug.setstack: не изменил local", true)

	local function type_mismatch_test()
		local a_number = 5
		local ok_err = not select(1, safe_pcall(debug.setstack, 1, 1, "a string"))
		check(ok_err, "debug.setstack: ожидаемо выдает ошибку при несовпадении типов", "debug.setstack: не выдал ошибку при несовпадении типов", true)
	end
	type_mismatch_test()

	local ok_err_c = not select(1, safe_pcall(function() pcall(debug.setstack, 1, 1, 0) end))
	check(ok_err_c, "debug.setstack: ожидаемо выдает ошибку на C-замыкании", "debug.setstack: не выдал ошибку на C-замыкании", true)
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
	
	local loaded_mod = Instance.new("ModuleScript")
	loaded_mod.Name = "Loaded_"..math.random()
	loaded_mod.Source = "return true"
	local not_loaded_mod = Instance.new("ModuleScript")
	not_loaded_mod.Name = "NotLoaded_"..math.random()

	local ok_req, _ = safe_pcall(require, loaded_mod)
	check(ok_req, "getloadedmodules: require тестового модуля прошел успешно", "getloadedmodules: ошибка при require", false)

	local ok_get, modules = safe_pcall(getloadedmodules)
	if check(ok_get and type(modules) == "table", "getloadedmodules: возвращает таблицу", "getloadedmodules: не вернул таблицу", false) then
		local found_loaded, found_not_loaded = false, false
		for _, mod in ipairs(modules) do
			if mod == loaded_mod then found_loaded = true end
			if mod == not_loaded_mod then found_not_loaded = true end
		end
		check(found_loaded, "getloadedmodules: находит загруженный модуль", "getloadedmodules: не нашел загруженный модуль", false)
		check(not found_not_loaded, "getloadedmodules: не включает незагруженные модули", "getloadedmodules: ошибочно включил незагруженный модуль", false)
	end
	
	loaded_mod:Destroy(); not_loaded_mod:Destroy()
end

local function test_getscriptclosure()
	if not present(getscriptclosure, "getscriptclosure") then return end
	
	local script_with_code = Instance.new("LocalScript")
	script_with_code.Source = "return 'hello', 123"
	
	local script_empty = Instance.new("LocalScript")
	
	local ok_get, closure = safe_pcall(getscriptclosure, script_with_code)
	if check(ok_get and type(closure) == "function", "getscriptclosure: возвращает функцию для скрипта с кодом", "getscriptclosure: не вернул функцию", false) then
		local ok_run, s, n = safe_pcall(closure)
		check(ok_run and s == "hello" and n == 123, "getscriptclosure: возвращенная функция выполняется корректно", "getscriptclosure: функция выполняется некорректно", false)
	end

	local ok_nil, res_nil = safe_pcall(getscriptclosure, script_empty)
	check(ok_nil and res_nil == nil, "getscriptclosure: возвращает nil для скрипта без байткода", "getscriptclosure: не вернул nil", false)

	script_with_code:Destroy(); script_empty:Destroy()
end

local function test_getscripthash()
	if not present(getscripthash, "getscripthash") then return end
	local is_sha384_hex = function(h) return type(h) == "string" and #h == 96 and h:match("^[0-9a-fA-F]+$") ~= nil end
	
	local s1 = Instance.new("LocalScript")
	s1.Source = "print(1)"
	local s2 = Instance.new("LocalScript")
	s2.Source = "print(2)"
	local s3 = Instance.new("LocalScript")
	s3.Source = "print(1)"
	local s_empty = Instance.new("LocalScript")

	local ok_h1, h1 = safe_pcall(getscripthash, s1)
	check(ok_h1 and is_sha384_hex(h1), "getscripthash: возвращает валидный SHA384 хэш", "getscripthash: не вернул хэш", false)
	
	local h2 = getscripthash(s2)
	local h3 = getscripthash(s3)
	check(h1 and h2 and h1 ~= h2, "getscripthash: хэши разных скриптов различаются", "getscripthash: хэши разных скриптов одинаковы", false)
	check(h1 and h3 and h1 == h3, "getscripthash: хэши одинаковых скриптов совпадают", "getscripthash: хэши одинаковых скриптов различаются", false)
	
	local ok_nil, res_nil = safe_pcall(getscripthash, s_empty)
	check(ok_nil and res_nil == nil, "getscripthash: возвращает nil для скрипта без байткода", "getscripthash: не вернул nil", false)

	s1:Destroy(); s2:Destroy(); s3:Destroy(); s_empty:Destroy()
end

local function test_identifyexecutor()
	if not present(identifyexecutor, "identifyexecutor") then return end

	local ok_get, name, version = safe_pcall(identifyexecutor)
	if check(ok_get, "identifyexecutor: выполняется без ошибок", "identifyexecutor: ошибка при выполнении", true) then
		check(type(name) == "string" and #name > 0, "identifyexecutor: возвращает непустое имя (строка)", "identifyexecutor: не вернул имя", true)
		check(type(version) == "string" and #version > 0, "identifyexecutor: возвращает непустую версию (строка)", "identifyexecutor: не вернул версию", true)
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

local function test_fireclickdetector() -- Xeno фикс #2
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


info("--- Основные функции ---")
test_newcclosure()
test_hookfunction()
test_restorefunction()
test_getrawmetatable()
test_setrawmetatable()
test_readonly()
test_hookmetamethod()
test_getgc()
test_cloneref()
test_firetouchinterest()
test_firesignal()
test_compareinstances()
test_identifyexecutor()

info("--- Проверки типов Closure ---")
test_closure_checks()

info("--- Низкоуровневые операции 💀💀💀 ---")
test_checkcaller()
test_getconnections()
test_getnilinstances()
test_threadidentity()
test_getscripts()
test_getrunningscripts()
test_getscriptbytecode()
test_setscriptable()
test_getgenv()
test_getcallbackvalue()
test_getcallingscript()
test_getloadedmodules()
test_getscriptclosure()
test_getscripthash()
test_getfunctionhash()
test_getinstances()
test_fireproximityprompt()
test_fireclickdetector()

info("--- Файловые операции и сетевые (aka request и тд.) ---")
test_request()
test_file_operations()
test_folder_and_load_ops()
test_getcustomasset()
test_replicatesignal()

info("--- Криптография ---")
test_crypto_ops()

info("--- 2D Рендеринг ---")
test_drawing()

info("--- Ебучий лоадстринг ---")
test_loadstring()

info("--- Тесты для debug ---")
test_debug_info()
test_debug_upvalues()
test_debug_constants()
test_debug_setstack()
test_clonefunction()
test_debug_protos()
test_getreg()


local percent = totalTests > 0 and math.floor((passedTests / totalTests) * 100) or 0
local skidRate = totalTests > 0 and math.floor((skidCount / totalTests) * 100) or 0
info("Итого: "..passedTests.."/"..totalTests.." ("..percent.."%)")
info("Skid Rate: "..skidCount.."/"..totalTests.." ("..skidRate.."%)")

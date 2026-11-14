-- ============================================================
--  on_login.append.lua  v1.0
--  Snippet to APPEND to your existing on_login.lua (ASCII ONLY)
--
--  If game_bin/resources/scripts/on_login.lua does not exist,
--  then rename this file to on_login.lua as-is.
--  If it already exists: keep its content, add only the body
--  of the function below inside the existing on_login(name).
-- ============================================================

function on_login(name)
  if RZ_RW and RZ_RW.on_login then
    local ok, st = pcall(RZ_RW.on_login, name)
    if not ok then
      if RZ_RW.log then RZ_RW.log("[RZ] on_login error: " .. tostring(st)) end
    end
  end
end

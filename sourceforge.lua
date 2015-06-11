dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')

local downloaded = {}
local addedtolist = {}
local downloadslist = {}

local nored = {}
local noretry = {}

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
  local itemvalue = string.gsub(item_value, "%-", "%%%-")
  
  if downloaded[url] == true or addedtolist[url] == true or string.match(url, "%.dl%.sourceforge%.net/") then
    return false
  end

  if string.match(url, "%?r=http.+%?r=http") or string.match(url, "&r=http.+&r=http") or string.match(url, "%%26r%%3Dhttp.+%%26r%%3Dhttp") or string.match(url, "&r=http.+%%26r%%3Dhttp") or string.match(url, "&amp;stars=") or string.match(url, "&stars=") or string.match(url, "%?stars=") or string.match(url, "%%3E") or string.match(url, ">") or (string.match(url, "/_static_/") and string.match(url, "fsdn%.com")) or string.match(url, "%.dl%.sourceforge%.net/") then
    return false
  end
  
  if (downloaded[url] ~= true or addedtolist[url] ~= true) and not (string.match(url, "%?r=http.+%?r=http") or string.match(url, "&r=http.+&r=http") or string.match(url, "%%26r%%3Dhttp.+%%26r%%3Dhttp") or string.match(url, "&r=http.+%%26r%%3Dhttp") or string.match(url, "&amp;stars=") or string.match(url, "&stars=") or string.match(url, "%?stars=") or string.match(url, "%%3E") or string.match(url, ">") or (string.match(url, "/_static_/") and string.match(url, "fsdn%.com")) or string.match(url, "%.dl%.sourceforge%.net/")) then
    if string.match(url, "/p/"..itemvalue) or string.match(url, "/projects/"..itemvalue) or string.match(url, itemvalue.."%.sourceforge%.net") or html == 0 then
      addedtolist[url] = true
      return true
    else
      return false
    end
  end
end

wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
  local itemvalue = string.gsub(item_value, "%-", "%%%-")

  local function check(url)
    if string.match(url, "%.dl%.sourceforge%.net/") then
      if (downloaded[url] ~= true and addedtolist[url] ~= true and downloadslist[string.match(url, "(%.dl%.sourceforge%.net/.+)")] ~= true) then
        table.insert(urls, { url=url })
        addedtolist[url] = true
        downloadslist[string.match(url, "(%.dl%.sourceforge%.net/.+)")] = true
      end
    elseif (downloaded[url] ~= true and addedtolist[url] ~= true) and not (string.match(url, "%?r=http.+%?r=http") or string.match(url, "&r=http.+&r=http") or string.match(url, "%%26r%%3Dhttp.+%%26r%%3Dhttp") or string.match(url, "&r=http.+%%26r%%3Dhttp") or string.match(url, "&amp;stars=") or string.match(url, "&stars=") or string.match(url, "%?stars=") or string.match(url, "%%3E") or string.match(url, ">") or (string.match(url, "/_static_/") and string.match(url, "fsdn%.com"))) then
      if string.match(url, "&amp;") then
        table.insert(urls, { url=string.gsub(url, "&amp;", "&") })
        addedtolist[url] = true
        addedtolist[string.gsub(url, "&amp;", "&")] = true
      else
      	table.insert(urls, { url=url })
      	addedtolist[url] = true
      end
    end
  end
  
  if string.match(url, item_value) then
    if string.match(url, "/p/"..itemvalue) or string.match(url, "/projects/"..itemvalue) or string.match(url, itemvalue.."%.sourceforge%.net") then
      html = read_file(file)
      if string.match(string.match(url, "(https?://.+/)"), itemvalue) and not string.match(url, "https?://[a-z]+%.fsdn%.com") then
        noretry[string.match(url, "(https?://.+/)")] = true
        check(string.match(url, "(https?://.+/)"))
      end
      if string.match(url, "(https?://.+/)[^/]+/") and string.match(string.match(url, "(https?://.+/)[^/]+/"), itemvalue) and not string.match(url, "https?://[a-z]+%.fsdn%.com") then
        noretry[string.match(url, "(https?://.+/)[^/]+/")] = true
        check(string.match(url, "(https?://.+/)[^/]+/"))
      end
--      if string.match(url, "/projects/"..itemvalue) then
--        nored[string.gsub(url, "/projects/"..itemvalue, "/p/"..item_value)] = true
--        check(string.gsub(url, "/projects/"..itemvalue, "/p/"..item_value))
--      end
--      if string.match(url, "/p/"..itemvalue) then
--        nored[string.gsub(url, "/p/"..itemvalue, "/projects/"..item_value)] = true
--        check(string.gsub(url, "/p/"..itemvalue, "/projects/"..item_value))
--      end
      for num in string.gmatch(url, "/"..itemvalue.."/[^/]+/([0-9]+)/") do
        local linksort = string.match(url, "/"..itemvalue.."/([^/]+)/[0-9]+/")
        if not string.match(url, "/"..itemvalue.."/news/") then
          while tonumber(num) >= 0 do
            check("http://sourceforge.net/p/"..item_value.."/"..linksort.."/"..tostring(num).."/")
            num = tonumber(num) - 1
          end
        end
      end
      for newurl in string.gmatch(html, '("/[^"]+)"') do
        if string.match(newurl, '"//') then
          if (string.match(newurl, itemvalue) and string.match(newurl, "sourceforge%.net")) or string.match(newurl, "fsdn%.com") then
            check(string.gsub(newurl, '"//', 'http://'))
          end
        elseif string.match(newurl, itemvalue) then
          check("http://sourceforge.net"..string.match(newurl, '"(/.+)'))
        end
      end
      for newurl in string.gmatch(html, "('/[^']+)'") do
        if string.match(newurl, "'//") then
          if (string.match(newurl, itemvalue) and string.match(newurl, "sourceforge%.net")) or string.match(newurl, "fsdn%.com") then
            check(string.gsub(newurl, "'//", "http://"))
          end
        elseif string.match(newurl, itemvalue) then
          check("http://sourceforge.net"..string.match(newurl, "'(/.+)"))
        end
      end
      for newurl in string.gmatch(html, '"(https?://[^"]+)"') do
        if (string.match(newurl, itemvalue) and string.match(newurl, "sourceforge%.net")) or string.match(newurl, "fsdn%.com") then
          check(newurl)
        end
      end
      for newurl in string.gmatch(html, "'(https?://[^']+)'") do
        if (string.match(newurl, itemvalue) and string.match(newurl, "sourceforge%.net")) or string.match(newurl, "fsdn%.com") then
          check(newurl)
        end
      end
      if string.match(url, "//") then
        check(string.gsub(url, "//", "/"))
      end
    end
  end
  
  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()

  if (status_code >= 200 and status_code <= 399) then
    if string.match(url.url, "https://") then
      local newurl = string.gsub(url.url, "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url.url] = true
    end
  end
  
  if nored[url["url"]] == true or noretry[url["url"]] == true then
    return wget.actions.EXIT
  end
  
  if status_code == 405 then
    return wget.actions.EXIT
  elseif status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403 and status_code ~= 400 and status_code ~= 405) then

    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 1")

    tries = tries + 1

    if tries >= 10 then
      if string.match(url["url"], "fsdn%.com") or noretry[url["url"]] == true then
        io.stdout:write("\nSkipping this url...\n")
        io.stdout:flush()
        tries = 0
        return wget.actions.EXIT
      else
        io.stdout:write("\nI give up...\n")
        io.stdout:flush()
        tries = 0
        return wget.actions.ABORT
      end
    else
      return wget.actions.CONTINUE
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 100")
    
    tries = tries + 1

    if tries >= 10 then
      if noretry[url["url"]] == true or not (string.match(url["url"], "https?://sourceforge%.net") or string.match(url["url"], "https?://[^%.]+%.sourceforge%.net")) then
        io.stdout:write("\nSkipping this url...\n")
        io.stdout:flush()
        tries = 0
        return wget.actions.EXIT
      else
        io.stdout:write("\nI give up...\n")
        io.stdout:flush()
        tries = 0
        return wget.actions.ABORT
      end
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  local sleep_time = 0

  -- We're okay; sleep a bit (if we have to) and continue
  if not (string.match(url["url"], "https?://[^%.]+%.googleusercontent%.com") or string.match(url["url"], "/photos/")) then
    local sleep_time = math.random(2, 4)
  end
  -- local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end

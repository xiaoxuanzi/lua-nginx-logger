local file_ffi = require "logger.file"

local _M = {}

local function access_log()

    local msg = {}

    table.insert(msg, '{ ')
    table.insert(msg, '\"timestamp\":\"')
    table.insert(msg, ngx.var.time_iso8601)
    table.insert(msg, '\",\"remote_addr\":\"')
    table.insert(msg, ngx.var.remote_addr or '-')
    table.insert(msg, '\",\"remote_user\":\"')
    table.insert(msg, ngx.var.remote_user or '-')
    table.insert(msg, '\",\"upstream_addr\":\"')
    table.insert(msg, ngx.var.upstream_addr or '-')
    table.insert(msg, '\",\"status\":\"')
    table.insert(msg, ngx.var.status)
    table.insert(msg, '\",\"body_bytes_sent\":')
    table.insert(msg, ngx.var.body_bytes_sent)
    table.insert(msg, ',\"request\":\"')
    table.insert(msg, ngx.var.request)
    table.insert(msg, '\",\"http_user_agent\":\"')
    table.insert(msg, ngx.var.http_user_agent or '-')
    table.insert(msg, '\",\"request_time\":')
    table.insert(msg, ngx.var.request_time)
    table.insert(msg, ',\"http_referer\":\"')
    table.insert(msg, ngx.var.http_referer or '-')
    table.insert(msg, '\",\"http_x_forwarded_for\":\"')
    table.insert(msg, ngx.var.http_x_forwarded_for or '-')
    table.insert(msg, '\",\"server_name\":\"')
    table.insert(msg, ngx.var.server_name)
    table.insert(msg, '\",\"bytes_sent\":\"')
    table.insert(msg, ngx.var.bytes_sent)
    table.insert(msg, '\"}')
    table.insert(msg, '\n')

    local result = table.concat(msg)
    return result

end

local function write_file( data, file_path )

    local flag = bit.bor(file_ffi.O_CREAT, file_ffi.O_WRONLY, file_ffi.O_APPEND)
    local mode = bit.bor(file_ffi.S_IRUSR, file_ffi.S_IWUSR,
                         file_ffi.S_IRGRP, file_ffi.S_IROTH)

    local f, err_code, err_msg = file_ffi:open(file_path, flag, mode)
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    local written, err_code, err_msg = f:write(data)
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    local res, err_code, err_msg = f:fdatasync()
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    return nil, nil, nil
end

function _M.logger( file_path )


    assert(file_path ~= nil)

    local msg = access_log()
    local res, err_code, err_msg = write_file( msg, file_path )

    if err_code ~= nil then
        ngx.log(ngx.ERR, 'logger failed! err_code: ', err_code, ' err_msg: ', err_msg)
    end

end

return _M



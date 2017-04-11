local file_ffi = require "std_ffi.file"

local _M = {}

local function transform( var )

    if var == nil then
        return '-'
    end

    return var

end

local function access_log()

    local msg = '{ ' ..
        '\"timestamp\":\"'       .. ngx.var.time_local .. ',' ..
        '\"remote_addr\":\"'     .. ngx.var.remote_addr .. ',' ..
        '\"remote_user\":\"'     .. transform(ngx.var.remote_user) .. ',' ..
        '\"upstream_addr\":\"'   .. transform(ngx.var.upstream_addr) .. ',' ..
        '\"status\":\"'          .. ngx.var.status .. ',' ..
        '\"body_bytes_sent\":\"' .. ngx.var.body_bytes_sent .. ',' ..
        '\"request\":\"'         .. ngx.var.request .. ',' ..
        '\"http_user_agent\":\"' .. transform(ngx.var.http_user_agent) .. ',' ..
        '\"request_time\":\"'    .. ngx.var.request_time .. ',' ..
        '\"http_referer\":\"'    .. transform(ngx.var.http_referer) .. ',' ..
        '\"http_x_forwarded_for\":\"' .. transform(ngx.var.http_x_forwarded_for) .. ',' ..
        '\"server_name\":\"'     .. ngx.var.server_name .. ',' ..
        '\"bytes_sent\":\"'      .. ngx.var.bytes_sent .. '}' .. '\n'

    return msg

end

local function write_file( data )

    local file_path = '/opt/qq-openresty/nginx/logs/mou.log'
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

function _M.logger()

    ngx.log(ngx.ERR, 'logger begin ')
    local msg = access_log()
    local res, err_code, err_msg = write_file( msg )

    if err_code ~= nil then
        ngx.log(ngx.ERR, 'logger failed! err_code: ', err_code, ' err_msg: ', err_msg)
    end

end

return _M



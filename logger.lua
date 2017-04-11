local file_ffi = require "std_ffi.file"

local _M = {}

local function access_log()

    local msg = 
        'timestamp:'       .. ngx.var.time_local .. ',' ..
        'remote_addr:'     .. ngx.var.remote_addr .. ',' ..
        'remote_user:'     .. ngx.var.remote_user .. ',' ..
        'upstream_addr:'   .. ngx.var.upstream_addr .. ',' ..
        'status:'          .. ngx.var.status .. ',' ..
        'body_bytes_sent:' .. ngx.var.body_bytes_sent .. ',' ..
        'request:'         .. ngx.var.request .. ',' ..
        'http_user_agent:' .. ngx.var.http_user_agent .. ',' ..
        'request_time:'    .. ngx.var.request_time .. ',' ..
        'http_referer:'    .. ngx.var.http_referer .. ',' ..
        'http_x_forwarded_for:' .. ngx.var.http_x_forwarded_for .. ',' ..
        'server_name:'     .. ngx.var.server_name .. ',' ..
        'bytes_sent:'      .. ngx.var.bytes_sent .. ','

    return msg

end

local function write_file( data )

    local f, err_code, err_msg = file_ffi:open(TEST_FILE_PATH,
                                               bit.bor(file_ffi.O_CREAT,
                                                       file_ffi.O_RDWR,
                                                       file_ffi.O_TRUNC),
                                                file_ffi.S_IRWXU)
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

end


function _M.logger()

    local msg = access_log()
    local res, err_code, er err_msg = write_file( msg )

    if err_code ~= nil then
        ngx.log('logger failed! err_code: ', err_code, ' err_msg: ', err_msg)
    end

end




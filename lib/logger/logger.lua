local file_ffi = require "logger.file"
local json     = require( "cjson" )

local logger_key = 'logger-status'
local store_data = ngx.shared.logger_status
local INIT_VAL   = 'MRD_INTIT_VAL'

local _M = {}

function _M.init()

    local val = INIT_VAL
    local succ, err, f = store_data:set(logger_key, val)
    if not succ then
        ngx.log(ngx.ERR, 'init store data failed, err: ' .. err)
        error('Init failed. error: ' .. err .. ' aborting!!')
    end

end

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

local function get_dict_data( dict, key )

    local val, err = dict:get( key )

    if not val then
        return nil, err
    end

    if val == INIT_VAL then
        return val, nil
    end

    local err, data = pcall( json.decode, val )
    if not err then
        ngx.log(ngx.ERR, 'get logger status failed, err : ' .. err)

        return nil, err
    end

    return data, nil

end

local function set_dict_data( dict, key, data )

    local err, json_data = pcall(json.encode, data )
    if not err then
        ngx.log(ngx.ERR, 'set dict data faled, since json decode, err: ', err)
        return
    end

    local succ, err, f = dict:set(key, json_data )
    if not succ then
        ngx.log(ngx.ERR, 'set dict data failed, err: ' .. err)
    end

end

function _M.logger( file_path )


    assert(file_path ~= nil)

    local msg = access_log()
    local res, err_code, err_msg = write_file( msg, file_path )

    if err_code == nil then
        return
    end

    ngx.log(ngx.ERR, 'logger failed! err_code: ', err_code, ' err_msg: ', err_msg)
    --record err msg

    local data, err = get_dict_data( store_data, logger_key )
    if not data then
        ngx.log(ngx.ERR, 'get dict data failed, err: '.. err)
        return
    end

    if data == INIT_VAL then
        data = {}
    end

    local skey = ngx.var.upstream_addr
    if not data[ skey ] then
        data[ skey ] = {
            total = 0,
            err_code = '',
            err_msg = ''
        }
    end

    data[ skey ][ 'total' ] = data[ skey ][ 'total' ] + 1
    data[ skey ][ 'err_code' ] = err_code
    data[ skey ][ 'err_msg' ]  = err_msg

    set_dict_data( store_data, logger_key, data )

end

function _M.status()

    local _ret = {

        nginx_info = {
            nginx_version = ngx.var.nginx_version,
            address = ngx.var.server_addr,
            timestamp = ngx.now() * 1000,
            time_iso8601 = ngx.var.time_iso8601,
            pid = ngx.worker.pid()
        },

        status = {}

    }

    local logger_status, err = get_dict_data(store_data, logger_key)
    if not logger_status then
        ngx.log(ngx.ERR, 'get statistic failed, err: ' .. err)
        ngx.exit(500)
    end

    if logger_status == INIT_VAL then

        ngx.print( 'There is no data yet, please try later!' )
        ngx.exit(ngx.HTTP_OK)

    end

    _ret.status = logger_status

    local ret = json.encode( _ret )
    ngx.status = ngx.HTTP_OK
    ngx.print( ret )
    ngx.exit(ngx.HTTP_OK)

end

return _M



package require tcldbf
package require json
source utils.tcl
source json.tcl

set value {{"bookname":"Harry Potter","username":"admin"}}

proc request {data} {
    set data [json::json2dict $data]
    
    return [dict values $data]
}
# puts [string map {"" " "} [json_value $value]]
puts [request $value]

proc testUsername {data username} {
    foreach name $data {
        if {[string match $username $name]} {
            return 1
        } 
    }
    return "wrong"
}

proc testPass {data userPass} {
    foreach pass $data {
        if {[string match $userPass $pass]} {
                return 1
            } 
       }
       return "wrong pass"
}

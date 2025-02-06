proc editBooks {bookName inputNameValue inputTextValue inputAuthorValue inputDateValue} {
    set file_name "books.dbf"
    dbf d -open $file_name

    set bookNames [$d values bookName]

    set rowid [searchUtilsStrict $bookNames $bookName]

    if {$inputNameValue ne ""} {
        $d update $rowid bookName $inputNameValue
    }
    if {$inputTextValue ne ""} {
        $d update $rowid bookText $inputTextValue
    }
    if {$inputAuthorValue ne ""} {
        $d update $rowid author $inputAuthorValue
    }
    if {$inputDateValue ne ""} {
        $d update $rowid date $inputDateValue
    }
   
    $d close
}

proc createBook {inputNameValue inputTextValue inputAuthorValue inputDateValue} {
    set file_name "books.dbf"
     dbf d -open $file_name
    $d update end bookName $inputNameValue bookText $inputTextValue author $inputAuthorValue date $inputDateValue 
    $d close
}

proc deleteBook {bookName} {
   set file_name "books.dbf"
    dbf d -open $file_name
    set bookNames [$d values bookName]    
    set rowid [searchUtilsStrict $bookNames $bookName]
    $d deleted $rowid true
    $d close
}

proc createLibrarian {name pass} {
    set file_name "users.dbf"
    dbf d -open $file_name
    $d update end NAME $name PASSWORD $pass STATUS "librarian"
    $d close
}
proc deletedUser {name} {
    set file_name "users.dbf"
    dbf d -open $file_name
    set users [$d values NAME]    
    set rowid [searchUtilsStrict $users $name]
    $d deleted $rowid true
    $d close
}
proc banUser {name} {
    set file_name "users.dbf"
    dbf d -open $file_name
    set users [$d values NAME]    
    set rowid [searchUtilsStrict $users $name]
    set banstatus [$d get $rowid BANSTATUS]
    if {$banstatus eq ""} {
        $d update $rowid BANSTATUS "Ban"
    } else {
       $d update $rowid BANSTATUS "" 
    }
    
    $d close
}
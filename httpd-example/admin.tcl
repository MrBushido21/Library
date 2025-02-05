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
    $d update end id [expr {[llength [$d values bookName]] + 1}] bookName $inputNameValue bookText $inputTextValue author $inputAuthorValue date $inputDateValue 
    $d close
}

proc deleteBook {bookName} {
    set file_name "books.dbf"
    dbf d -open $file_name

    set data [$d values bookName]
    set rowid [searchUtilsStrict $data $bookName]
    $d deleted $rowid [true]
}